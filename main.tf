###############################################################
# VPC and Network Resources
###############################################################

resource "aws_vpc" "wordpress_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-vpc"
    }
  )
}

# Public subnets - one per AZ
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.wordpress_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-public-subnet-${count.index + 1}"
    }
  )
}

# Private app subnets - one per AZ
resource "aws_subnet" "private_app" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.wordpress_vpc.id
  cidr_block              = var.private_app_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-private-app-subnet-${count.index + 1}"
    }
  )
}

# Private data subnets - one per AZ
resource "aws_subnet" "private_data" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.wordpress_vpc.id
  cidr_block              = var.private_data_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-private-data-subnet-${count.index + 1}"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.wordpress_vpc.id
  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-igw"
    }
  )
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"
  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-nat-eip-${count.index + 1}"
    }
  )
}

# NAT Gateways
resource "aws_nat_gateway" "nat" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-nat-gateway-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.igw]
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.wordpress_vpc.id
  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-public-rt"
    }
  )
}

# Route to Internet Gateway for Public Subnets
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Tables for Private Subnets
resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.wordpress_vpc.id
  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-private-rt-${count.index + 1}"
    }
  )
}

# Routes to NAT Gateway for Private Subnets
resource "aws_route" "private_nat_gateway" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}

# Route Table Associations for Private App Subnets
resource "aws_route_table_association" "private_app" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Route Table Associations for Private Data Subnets
resource "aws_route_table_association" "private_data" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
###############################################################
# Security Groups
###############################################################

# Security Group for Load Balancer
resource "aws_security_group" "alb" {
  name        = "${local.project_name}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.wordpress_vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-alb-sg"
    }
  )
}

# Security Group for Bastion Hosts
resource "aws_security_group" "bastion" {
  name        = "${local.project_name}-bastion-sg"
  description = "Security group for bastion hosts"
  vpc_id      = aws_vpc.wordpress_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-bastion-sg"
    }
  )
}

# Security Group for WordPress Instances
resource "aws_security_group" "wordpress" {
  name        = "${local.project_name}-wordpress-sg"
  description = "Security group for WordPress instances"
  vpc_id      = aws_vpc.wordpress_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-wordpress-sg"
    }
  )
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${local.project_name}-rds-sg"
  description = "Security group for RDS instances"
  vpc_id      = aws_vpc.wordpress_vpc.id

  ingress {
    description     = "MySQL from WordPress"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-rds-sg"
    }
  )
}

# Security Group for ElastiCache
resource "aws_security_group" "elasticache" {
  name        = "${local.project_name}-elasticache-sg"
  description = "Security group for ElastiCache"
  vpc_id      = aws_vpc.wordpress_vpc.id

  ingress {
    description     = "Redis from WordPress"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-elasticache-sg"
    }
  )
}
###############################################################
# Application Load Balancer
###############################################################

resource "aws_lb" "wordpress" {
  name               = "${local.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-alb"
    }
  )
}

# ALB Target Group
resource "aws_lb_target_group" "wordpress" {
  name     = "${local.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.wordpress_vpc.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-tg"
    }
  )
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}

# Add HTTPS listener if SSL is enabled
resource "aws_lb_listener" "https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.wordpress.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}

###############################################################
# RDS Database for WordPress
###############################################################

resource "aws_db_subnet_group" "wordpress" {
  name       = "${local.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private_data[*].id

  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-db-subnet-group"
    }
  )
}

resource "aws_db_parameter_group" "wordpress" {
  name   = "${local.project_name}-db-params"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-db-params"
    }
  )
}

resource "aws_db_instance" "wordpress_master" {
  identifier             = "${local.project_name}-db-master"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  max_allocated_storage  = var.db_max_allocated_storage
  storage_type           = "gp3"
  storage_encrypted      = true
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  parameter_group_name   = aws_db_parameter_group.wordpress.name
  db_subnet_group_name   = aws_db_subnet_group.wordpress.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = true
  backup_retention_period = 7
  skip_final_snapshot    = var.skip_final_snapshot
  final_snapshot_identifier = "${local.project_name}-final-snapshot"
  deletion_protection    = var.enable_deletion_protection
  
  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-db-master"
    }
  )
}

resource "aws_db_instance" "wordpress_replica" {
  count                  = var.create_db_replica ? 1 : 0
  identifier             = "${local.project_name}-db-replica"
  replicate_source_db    = aws_db_instance.wordpress_master.identifier
  instance_class         = var.db_replica_instance_class
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.wordpress.name
  skip_final_snapshot    = true
  deletion_protection    = var.enable_deletion_protection
  
  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-db-replica"
    }
  )
}

###############################################################
# ElastiCache for Caching
###############################################################

resource "aws_elasticache_subnet_group" "wordpress" {
  count      = var.create_elasticache ? 1 : 0
  name       = "${local.project_name}-elasticache-subnet-group"
  subnet_ids = aws_subnet.private_data[*].id

  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-elasticache-subnet-group"
    }
  )
}

resource "aws_elasticache_parameter_group" "wordpress" {
  count  = var.create_elasticache ? 1 : 0
  name   = "${local.project_name}-elasticache-params"
  family = "redis6.x"

  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-elasticache-params"
    }
  )
}

resource "aws_elasticache_replication_group" "wordpress" {
  count                         = var.create_elasticache ? 1 : 0
  replication_group_id          = "${replace(local.project_name, "-", "")}-cache"
  description                   = "Redis cache for WordPress"
  node_type                     = var.elasticache_node_type
  port                          = 6379
  parameter_group_name          = aws_elasticache_parameter_group.wordpress[0].name
  subnet_group_name             = aws_elasticache_subnet_group.wordpress[0].name
  security_group_ids            = [aws_security_group.elasticache.id]
  automatic_failover_enabled    = true
  multi_az_enabled              = true
  num_cache_clusters            = length(var.availability_zones)
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  
  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-redis-cache"
    }
  )
}

###############################################################
# EFS for WordPress Content
###############################################################

resource "aws_efs_file_system" "wordpress" {
  creation_token = "${local.project_name}-efs"
  encrypted      = true
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  
  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-efs"
    }
  )
}

resource "aws_security_group" "efs" {
  name        = "${local.project_name}-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = aws_vpc.wordpress_vpc.id

  ingress {
    description     = "NFS from WordPress instances"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-efs-sg"
    }
  )
}

resource "aws_efs_mount_target" "wordpress" {
  count           = length(var.availability_zones)
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = aws_subnet.private_app[count.index].id
  security_groups = [aws_security_group.efs.id]
}

###############################################################
# Launch Template for WordPress
###############################################################

resource "aws_launch_template" "wordpress" {
  name_prefix   = "${local.project_name}-launch-template-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.wordpress.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.wordpress.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    db_host          = aws_db_instance.wordpress_master.address
    db_name          = var.db_name
    db_user          = var.db_username
    db_password      = var.db_password
    efs_id           = aws_efs_file_system.wordpress.id
    region           = var.aws_region
    site_url         = var.site_url
    use_elasticache  = var.create_elasticache
    elasticache_host = var.create_elasticache ? aws_elasticache_replication_group.wordpress[0].primary_endpoint_address : ""
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.tags,
      {
        Name = "${local.project_name}-wordpress"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      local.tags,
      {
        Name = "${local.project_name}-wordpress-volume"
      }
    )
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
}

###############################################################
# Auto Scaling Group for WordPress
###############################################################

resource "aws_autoscaling_group" "wordpress" {
  name                      = "${local.project_name}-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 300
  vpc_zone_identifier       = aws_subnet.private_app[*].id
  target_group_arns         = [aws_lb_target_group.wordpress.arn]

  launch_template {
    id      = aws_launch_template.wordpress.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.project_name}-wordpress"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${local.project_name}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.wordpress.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${local.project_name}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.wordpress.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.project_name}-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "Scale up if CPU > 70% for 2 minutes"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpress.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${local.project_name}-low-cpu"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "Scale down if CPU < 30% for 2 minutes"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpress.name
  }
}

###############################################################
# Bastion Host
###############################################################

resource "aws_instance" "bastion" {
  count                       = length(var.availability_zones)
  ami                         = var.ami_id
  instance_type               = var.bastion_instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public[count.index].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-bastion-${count.index + 1}"
    }
  )
}

###############################################################
# Route 53 Records
###############################################################

resource "aws_route53_record" "wordpress" {
  count   = var.create_route53_record ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.site_url
  type    = "A"

  alias {
    name                   = aws_lb.wordpress.dns_name
    zone_id                = aws_lb.wordpress.zone_id
    evaluate_target_health = true
  }
}

###############################################################
# IAM Roles
###############################################################

resource "aws_iam_role" "wordpress" {
  name = "${local.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "wordpress" {
  name = "${local.project_name}-ec2-policy"
  role = aws_iam_role.wordpress.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${local.project_name}/*"
      },
      {
        Action = [
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ]
        Effect   = "Allow"
        Resource = aws_efs_file_system.wordpress.arn
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.wordpress.arn,
          "${aws_s3_bucket.wordpress.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "wordpress" {
  name = "${local.project_name}-instance-profile"
  role = aws_iam_role.wordpress.name
}

###############################################################
# S3 Bucket for Backups
###############################################################

resource "aws_s3_bucket" "wordpress" {
  bucket = "${local.project_name}-backups-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    local.tags,
    {
      Name = "${local.project_name}-backups"
    }
  )
}

resource "aws_s3_bucket_versioning" "wordpress" {
  bucket = aws_s3_bucket.wordpress.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "wordpress" {
  bucket = aws_s3_bucket.wordpress.id

  rule {
    id     = "backup-lifecycle"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "wordpress" {
  bucket = aws_s3_bucket.wordpress.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "wordpress" {
  bucket = aws_s3_bucket.wordpress.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

###############################################################
# Monitoring and Logging
###############################################################

resource "aws_cloudwatch_dashboard" "wordpress" {
  dashboard_name = "${local.project_name}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.wordpress.name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.wordpress_master.id]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.wordpress.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB Request Count"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.wordpress.arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Response Time"
        }
      }
    ]
  })
}

###############################################################
# CloudWatch Alarms for Critical Components
###############################################################

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.project_name}-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "RDS CPU utilization is too high"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.wordpress_master.id
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_count" {
  alarm_name          = "${local.project_name}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Application Load Balancer is returning 5XX errors"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    LoadBalancer = aws_lb.wordpress.arn_suffix
  }
}

###############################################################
# Data Sources
###############################################################

data "aws_caller_identity" "current" {}
