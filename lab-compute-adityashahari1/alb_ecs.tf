
# Look up default networking

data "aws_vpc" "default" {
  default = true
}

# All subnets in the default VPC (default VPC subnets are public)
data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


# Security groups
# ALB: open 80 to the world

resource "aws_security_group" "alb_sg" {
  name        = "alb-http-sg"
  description = "Allow HTTP from anywhere"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS tasks: only allow 80 from the ALB

resource "aws_security_group" "ecs_task_sg" {
  name        = "ecs-task-http-from-alb"
  description = "Allow HTTP from ALB only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from ALB SG"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Application Load Balancer

resource "aws_lb" "app" {
  name               = "app-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default_vpc_subnets.ids
}

# Target Group for ASG EC2 instances (Apache)

resource "aws_lb_target_group" "ec2_tg" {
  name        = "tg-ec2-apache"
  vpc_id      = data.aws_vpc.default.id
  protocol    = "HTTP"
  port        = 80
  target_type = "instance"

  health_check {
    protocol = "HTTP"
    path     = "/"
    matcher  = "200"
    port     = "80"
  }
}

# Target Group for ECS Fargate (Nginx)

resource "aws_lb_target_group" "ecs_tg" {
  name        = "tg-ecs-nginx"
  vpc_id      = data.aws_vpc.default.id
  protocol    = "HTTP"
  port        = 80
  target_type = "ip" # required for Fargate/awsvpc

  health_check {
    protocol = "HTTP"
    path     = "/"
    matcher  = "200"
    port     = "80"
  }
}

# Listener: forward root (/) 50/50 to both target groups

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.ec2_tg.arn
        weight = 50
      }
      target_group {
        arn    = aws_lb_target_group.ecs_tg.arn
        weight = 50
      }

      stickiness {
        enabled  = false
        duration = 1
      }
    }
  }
}


# ECS cluster + task + service (Fargate)

resource "aws_ecs_cluster" "this" {
  name = "example-cluster"
}

# Logs for the container

resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/ecs/nginx"
  retention_in_days = 7
}

# Execution role for Fargate tasks (pull image, write logs)

resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Nginx task definition

resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx-fargate"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "nginx"
      image = "nginx:latest"
      essential = true

      # Create simple page at /nginx/index.html, then run nginx in foreground
      command = [
        "sh", "-c",
        "mkdir -p /usr/share/nginx/html/nginx && echo '<h1>Hello from ECS Nginx</h1>' > /usr/share/nginx/html/nginx/index.html && nginx -g 'daemon off;'"
      ]

      portMappings = [{
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.nginx.name
          awslogs-region        = "us-west-1"
          awslogs-stream-prefix = "nginx"
        }
      }
    }
  ])
}

# ECS service that registers tasks into the ECS TG

resource "aws_ecs_service" "nginx" {
  name            = "nginx-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default_vpc_subnets.ids
    security_groups = [aws_security_group.ecs_task_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]
}
