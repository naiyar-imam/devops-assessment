provider "aws" {
  region = var.region
}

# Security Group
resource "aws_security_group" "app_sg" {
  name_prefix = "devops-sg-"
  description = "Allow SSH, HTTP, HTTPS, Backend"

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Backend"
    from_port   = 8000
    to_port     = 8000
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

# EC2 Instance
resource "aws_instance" "app_server" {
  ami           = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"

  key_name = "devops-key"

  vpc_security_group_ids = [
    aws_security_group.app_sg.id
  ]

  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash

# Update system
apt update -y

# Install Docker
apt install docker.io -y

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Allow ubuntu user to run docker
usermod -aG docker ubuntu

# Install AWS CLI
apt install awscli -y

EOF

  tags = {
    Name = "DevOps-App-Server"
  }
}