## Questions

1. Imagine that your application will need to run two always-on `f1.2xlarge` instances (which come with instance storage and won't require any EBS volumes). To meet seasonal demand, you can expect to require as many as four more instances for a total of 100 hours through the course of a single year. What combination of instance types should you use? Calculate your total estimated monthly and annual costs.

If I need two big f1.2xlarge machines running all the time, I’d buy a one-year pass for them using the reserved option so they’re cheaper. When I sometimes need up to four extra machines for about 100 hours in the whole year, I’d just turn them on only when needed using On-Demand. With typical prices, the two reserved machines cost about 1,748 dollars per month, which is about 20,978 dollars per year. The short bursts add about 55 dollars per month on average, which is about 660 dollars per year. That makes a total of about 1,803 dollars per month or about 21,638 dollars per year.

(https://instances.vantage.sh/aws/ec2/f1.2xlarge)
(https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html)
(https://docs.aws.amazon.com/pricing-calculator/latest/userguide/ec2-estimates.html)

2. What are some benefits to using an Elastic Load Balancer and an Auto Scaling Group? What are some cons?

Using an Elastic Load Balancer (ELB) and an Auto Scaling Group (ASG) provides benefits like high availability, scalability, improved performance, and cost optimization, as ELB distributes traffic and ASG manages resources based on demand. However, cons include increased complexity in configuration, potential cost overruns from mismanagement, initial scaling delays, and reliance on the health of the AWS infrastructure.

(https://www.nops.io/blog/aws-ec2-autoscaling/#:~:text=or%20terminating%20instances.-,What%20is%20the%20difference%20between%20EC2%20Auto%20Scaling%20and%20ELB,that%20traffic%20as%20demand%20changes.)

3. What's the difference between a launch template and a launch configuration?

Launch configurations have been a part of Amazon EC2 Auto Scaling Groups since 2010. Customers use launch configurations to define Auto Scaling group configurations that include AMI and instance type definition. In 2017, AWS released launch templates, which reduce the number of steps required to create an instance by capturing all launch parameters within one resource that can be used across multiple services.

Launch configuration: older, legacy. Single, immutable blob of settings. If you need a change, you create a brand-new LC and point the ASG at it. LCs don’t support many newer features.

Launch template: modern and versioned. Lets us keep multiple versions, specify subnets/SGs, mixed instances policies, larger set of EC2 features. LTs are what AWS recommends now; LCs are basically for backwards compatibility.

(https://docs.aws.amazon.com/autoscaling/ec2/userguide/launch-configurations.html)
(https://aws.amazon.com/blogs/compute/amazon-ec2-auto-scaling-will-no-longer-add-support-for-new-ec2-features-to-launch-configurations)

4. What's the purpose of a security group?

A security group controls the traffic that is allowed to reach and leave the resources that it is associated with. For example, after you associate a security group with an EC2 instance, it controls the inbound and outbound traffic for the instance.
When you create a VPC, it comes with a default security group. You can create additional security groups for a VPC, each with their own inbound and outbound rules. You can specify the source, port range, and protocol for each inbound rule. You can specify the destination, port range, and protocol for each outbound rule.

(https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)

5. What's the method to convert an existing unencrypted EBS volume to an encrypted EBS volume?

You can’t flip a volume’s encryption flag in-place. The standard path is:

Create a snapshot of the unencrypted volume.
Copy that snapshot with encryption enabled choose KMS key - aws/ebs.
Create a new volume from the encrypted snapshot AZ as the instance.
Detach the old volume, attach the new encrypted one keep same device name - /dev/sdf.
Mount/verify on the instance, then delete the old unencrypted volume.

(https://medium.com/bacic/encrypt-an-already-attached-unencrypted-ebs-volume-on-aws-ec2-c67f9923b228)
