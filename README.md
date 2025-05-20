# AWS WordPress Terraform
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

A production-grade Terraform module for deploying scalable, secure, and highly available WordPress installations on AWS.

## Architecture

![wordpress-architecture](https://github.com/user-attachments/assets/ac209ec9-2194-41db-b6ce-6180ec189c3e)


This Terraform module creates a fully-featured WordPress deployment with the following components:

- **Network**: Multi-AZ VPC with public, private application, and private data subnets
- **Compute**: Auto Scaling Group of WordPress EC2 instances for high availability and scalability
- **Database**: RDS MySQL with optional read replicas for database scaling
- **Storage**: EFS for shared WordPress content across instances
- **Caching**: ElastiCache (Redis) for improved performance
- **Load Balancing**: Application Load Balancer for traffic distribution
- **CDN**: Optional CloudFront distribution for global content delivery
- **Security**: Well-defined security groups, IAM roles, and encryption
- **Monitoring**: CloudWatch dashboards, alarms, and logging

## Usage

```hcl
module "wordpress" {
  source = "github.com/yourusername/aws-wordpress-terraform"

  # Required parameters
  project_name = "my-wordpress-site"
  environment  = "production"
  aws_region   = "us-east-1"
  
  # Network parameters
  vpc_cidr               = "10.0.0.0/16"
  availability_zones     = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  private_data_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]
  
  # WordPress configuration
  instance_type      = "t3.small"
  min_size           = 2
  max_size           = 5
  desired_capacity   = 2
  key_name           = "my-key-pair"
  
  # Database configuration
  db_instance_class  = "db.t3.small"
  db_name            = "wordpress"
  db_username        = "admin"
  db_password        = "securepassword"  # Use secrets management in production
  create_db_replica  = true
  
  # Cache configuration
  create_elasticache = true
  
  # Domain configuration
  site_url           = "example.com"
  create_route53_record = true
  route53_zone_id    = "Z1234567890ABC"
  
  # Optional HTTPS
  enable_https      = true
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234-ef56-gh78-ij90-klmnopqrstuv"
  
  # Tags
  tags = {
    Owner       = "DevOps Team"
    Project     = "Corporate Website"
    Environment = "Production"
  }
}
```

### Examples

The module includes two example configurations:

- **Basic**: A simplified WordPress setup for development environments
- **Complete**: A fully-featured production configuration with all options enabled

To deploy an example:

```bash
cd examples/basic
terraform init
terraform plan -var-file="example.tfvars"
terraform apply -var-file="example.tfvars"
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | ~> 5.0 |

## Features

### High Availability
- Multi-AZ deployment across availability zones
- Auto-scaling for WordPress instances
- RDS Multi-AZ with optional read replicas
- Self-healing infrastructure

### Performance
- ElastiCache (Redis) for object caching
- EFS for shared content across instances
- Optional CloudFront CDN integration
- Load balancing across multiple instances

### Security
- Private subnets for application and data tiers
- Security groups with principle of least privilege
- Encrypted storage and database
- Bastion hosts for secure SSH access
- HTTPS support with ACM certificates

### Scalability
- Auto Scaling based on CPU utilization
- Separate database read replicas for read scaling
- Ability to scale instances horizontally

### Monitoring
- CloudWatch dashboards with key metrics
- Alarms for critical components
- Detailed logging for troubleshooting

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | The name of the project used for tagging | `string` | - | yes |
| environment | Environment name (dev, staging, prod) | `string` | `"dev"` | no |
| aws_region | AWS region to deploy resources | `string` | `"us-east-1"` | no |
| vpc_cidr | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| availability_zones | List of availability zones to use | `list(string)` | `["us-east-1a", "us-east-1b"]` | no |
| public_subnet_cidrs | CIDR blocks for public subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | no |
| private_app_subnet_cidrs | CIDR blocks for private app subnets | `list(string)` | `["10.0.11.0/24", "10.0.12.0/24"]` | no |
| private_data_subnet_cidrs | CIDR blocks for private data subnets | `list(string)` | `["10.0.21.0/24", "10.0.22.0/24"]` | no |
| instance_type | Instance type for WordPress servers | `string` | `"t3.small"` | no |
| min_size | Minimum number of WordPress instances | `number` | `1` | no |
| max_size | Maximum number of WordPress instances | `number` | `4` | no |
| desired_capacity | Desired number of WordPress instances | `number` | `2` | no |
| db_instance_class | RDS instance class | `string` | `"db.t3.small"` | no |
| db_name | Name of the WordPress database | `string` | `"wordpress"` | no |
| db_username | Username for the WordPress database | `string` | - | yes |
| db_password | Password for the WordPress database | `string` | - | yes |
| create_db_replica | Whether to create a read replica | `bool` | `true` | no |
| create_elasticache | Whether to create ElastiCache for caching | `bool` | `true` | no |
| site_url | URL of the WordPress site | `string` | `"example.com"` | no |
| create_route53_record | Whether to create Route 53 record | `bool` | `false` | no |
| route53_zone_id | ID of the Route 53 hosted zone | `string` | `""` | no |
| enable_https | Whether to enable HTTPS | `bool` | `false` | no |
| acm_certificate_arn | ARN of the ACM certificate for HTTPS | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| alb_dns_name | The DNS name of the load balancer |
| rds_endpoint | The endpoint of the RDS instance |
| bastion_public_ips | The public IPs of the bastion hosts |
| wordpress_security_group_id | The ID of the WordPress security group |
| efs_id | The ID of the EFS file system |
| elasticache_endpoint | The endpoint of the ElastiCache cluster |

## Considerations for Production Use

- **Secrets Management**: Use AWS Secrets Manager or SSM Parameter Store for database credentials
- **Backups**: Enable RDS automated backups and consider additional backup solutions
- **CI/CD**: Use the included GitHub Actions workflow for infrastructure validation
- **Custom AMI**: Consider building a custom AMI with WordPress pre-installed for faster scaling
- **Updates**: Implement a strategy for WordPress core and plugin updates
- **WAF**: Add AWS WAF for additional security against common web exploits
- **Monitoring**: Extend CloudWatch monitoring with custom metrics and alarms

## Security Features

- Private subnets for application and database tiers
- Bastion hosts for secure SSH access
- Security groups with principle of least privilege
- Encrypted storage (EBS, EFS, S3)
- Encrypted database (RDS)
- HTTPS support with ACM certificates
- IAM roles with least-privilege permissions

## License

This module is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for full details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
