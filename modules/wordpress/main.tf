locals {
  use_custom_ami = var.ami_id != ""
}

data "aws_ami" "amazon_linux" {
  count       = local.use_custom_ami ? 0 : 1
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "this" {
  name          = "${var.name}-${var.environment}-wordpress-lt"
  image_id      = local.use_custom_ami ? var.ami_id : data.aws_ami.amazon_linux[0].id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [var.security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.wordpress.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp2"
      delete_on_termination = true
      encrypted             = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh", {
    db_name         = var.db_name
    db_user         = var.db_username
    db_password     = var.db_password
    db_host         = split(":", var.db_endpoint)[0]
    efs_id          = var.efs_id
    region          = data.aws_region.current.name
    enable_cache    = var.enable_cache
    redis_host      = var.enable_cache ? split(":", var.cache_endpoint)[0] : ""
    site_name       = "${var.name}-${var.environment}"
    environment     = var.environment
  }))

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      {
        "Name" = format("%s-%s-wordpress", var.name, var.environment)
      },
      var.tags,
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      {
        "Name" = format("%s-%s-wordpress-volume", var.name, var.environment)
      },
      var.tags,
    )
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      "Name" = format("%s-%s-wordpress-lt", var.name, var.environment)
    },
    var.tags,
  )
}

resource "aws_autoscaling_group" "this" {
  name                      = "${var.name}-${var.environment}-wordpress-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.this.arn]
  
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(
      {
        "Name" = format("%s-%s-wordpress-asg", var.name, var.environment)
      },
      var.tags,
    )

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.name}-${var.environment}-wordpress-scale-up"
  autoscaling_group_name = aws_autoscaling_group.this.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.name}-${var.environment}-wordpress-scale-down"
  autoscaling_group_name = aws_autoscaling_group.this.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.name}-${var.environment}-wordpress-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }
  
  alarm_description = "Scale up if CPU utilization is above 80% for 4 minutes"
  alarm_actions     = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.name}-${var.environment}-wordpress-low-cpu"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }
  
  alarm_description = "Scale down if CPU utilization is below 20% for 4 minutes"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]
}

resource "aws_lb_target_group" "this" {
  name     = "${var.name}-${var.environment}-wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
  
  tags = merge(
    {
      "Name" = format("%s-%s-wordpress-tg", var.name, var.environment)
    },
    var.tags,
  )
}

data "aws_region" "current" {}

resource "aws_iam_role" "wordpress" {
  name = "${var.name}-${var.environment}-wordpress-role"
  
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
  
  tags = merge(
    {
      "Name" = format("%s-%s-wordpress-role", var.name, var.environment)
    },
    var.tags,
  )
}

resource "aws_iam_instance_profile" "wordpress" {
  name = "${var.name}-${var.environment}-wordpress-instance-profile"
  role = aws_iam_role.wordpress.name
}

resource "aws_iam_role_policy" "ssm" {
  name = "${var.name}-${var.environment}-wordpress-ssm-policy"
  role = aws_iam_role.wordpress.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter*",
          "ssm:GetParameters",
          "ssm:DescribeParameters"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "${var.name}-${var.environment}-wordpress-cloudwatch-policy"
  role = aws_iam_role.wordpress.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

