  module "db" {
    source  = "terraform-aws-modules/rds/aws"
    version = "~> 6.5"

    identifier = "replica-postgresql"

    engine                         = "postgres"

    instance_class                 = "db.t3.micro"     
    allocated_storage              = 20
    storage_type                   = "gp3"

    db_name                        = "replicaPostgresql"
    username                       = "replica_postgresql"
    port                           = 5432
    manage_master_user_password    = false
    password                       = "UberSecretPassword"

    publicly_accessible            = false
    multi_az                       = false
    storage_encrypted              = true
    deletion_protection            = false
  
    vpc_security_group_ids         = [module.db_security_group.security_group_id]
    create_db_subnet_group         = true
    subnet_ids                     = module.vpc.private_subnets

    backup_retention_period        = 7
    maintenance_window             = "Mon:00:00-Mon:03:00"
    backup_window                  = "03:00-06:00"

    family = "postgres17"

    tags = {
      Project     = "lab-databases"
      Environment = "dev"
    }
  }

module "db_read" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.5"

  identifier = "replica-postgresql-read"

  replicate_source_db = module.db.db_instance_arn

  instance_class      = "db.t3.micro"
  publicly_accessible = false
  multi_az            = false

  vpc_security_group_ids = [module.db_security_group.security_group_id]
  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets

  apply_immediately          = true
  auto_minor_version_upgrade = true
  maintenance_window         = "Mon:00:00-Mon:03:00"

  engine = "postgres"
  family = "postgres17"

  tags = {
    Project     = "lab-databases"
    Environment = "dev"
    Role        = "read-replica"
  }

  depends_on = [module.db]
}

output "rds_read_endpoint" {
  value = module.db_read.db_instance_endpoint
}

output "rds_endpoint" {
  value = module.db.db_instance_endpoint
}