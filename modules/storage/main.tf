resource "aws_efs_file_system" "this" {
  creation_token = "${var.name}-${var.environment}-efs"
  
  encrypted        = var.encrypted
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  
  tags = merge(
    {
      "Name" = format("%s-%s-efs", var.name, var.environment)
    },
    var.tags,
  )
}

resource "aws_efs_mount_target" "this" {
  count = length(var.subnet_ids)
  
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = element(var.subnet_ids, count.index)
  security_groups = [var.security_group_id]
}

resource "aws_efs_access_point" "wordpress" {
  file_system_id = aws_efs_file_system.this.id
  
  posix_user {
    gid = 33  # www-data group ID
    uid = 33  # www-data user ID
  }
  
  root_directory {
    path = "/wordpress"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = "0755"
    }
  }
  
  tags = merge(
    {
      "Name" = format("%s-%s-efs-ap", var.name, var.environment)
    },
    var.tags,
  )
}

