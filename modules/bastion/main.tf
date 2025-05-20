data "aws_ami" "amazon_linux" {
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

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  subnet_id              = element(var.subnet_ids, 0)
  vpc_security_group_ids = [var.security_group_id]
  
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y git vim
    
    # Harden SSH
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd
    
    # Set hostname
    hostnamectl set-hostname ${var.name}-${var.environment}-bastion
  EOF

  tags = merge(
    {
      "Name" = format("%s-%s-bastion", var.name, var.environment)
    },
    var.tags,
  )

  volume_tags = merge(
    {
      "Name" = format("%s-%s-bastion", var.name, var.environment)
    },
    var.tags,
  )

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "bastion" {
  domain = "vpc"
  instance = aws_instance.bastion.id
  
  tags = merge(
    {
      "Name" = format("%s-%s-bastion-eip", var.name, var.environment)
    },
    var.tags,
  )
}
