# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.name}-${var.environment}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

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
    {
      "Name" = format("%s-%s-alb-sg", var.name, var.environment)
    },
    var.tags,
  )
}

# Bastion Security Group
resource "aws_security_group" "bastion" {
  name        = "${var.name}-${var.environment}-bastion-sg"
  description = "Security group for the bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
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
    {
      "Name" = format("%s-%s-bastion-sg", var.name, var.environment)
    },
    var.tags,
  )
}

# WordPress Security Group
resource "aws_security_group" "wordpress" {
  name        = "${var.name}-${var.environment}-wordpress-sg"
  description = "Security group for the WordPress instances"
  vpc_id      = var.vpc_id

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
    {
      "Name" = format("%s-%s-wordpress-sg", var.name, var.environment)
    },
    var.tags,
  )
}

# Database Security Group
resource "aws_security_group" "database" {
  name        = "${var.name}-${var.environment}-database-sg"
  description = "Security group for the RDS instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from WordPress instances"
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
    {
      "Name" = format("%s-%s-database-sg", var.name, var.environment)
    },
    var.tags,
  )
}

# Cache Security Group
resource "aws_security_group" "cache" {
  name        = "${var.name}-${var.environment}-cache-sg"
  description = "Security group for ElastiCache"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from WordPress instances"
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
    {
      "Name" = format("%s-%s-cache-sg", var.name, var.environment)
    },
    var.tags,
  )
}

# EFS Security Group
resource "aws_security_group" "efs" {
  name        = "${var.name}-${var.environment}-efs-sg"
  description = "Security group for EFS"
  vpc_id      = var.vpc_id

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
    {
      "Name" = format("%s-%s-efs-sg", var.name, var.environment)
    },
    var.tags,
  )
}

