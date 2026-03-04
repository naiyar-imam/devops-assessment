provider "aws" {
  region = var.region
}

resource "aws_security_group" "app_sg" {
  name_prefix = "devops-sg-"
  description = "Allow SSH, HTTP, HTTPS"

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_instance" "app_server" {
  ami           = "ami-0f58b397bc5c1f2e8" # Amazon Linux
  instance_type = "t2.micro"

  # IMPORTANT: Use ID, not name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  key_name = "naiyar"

  user_data = <<-EOF
#!/bin/bash
yum update -y
yum install docker -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user
EOF

  tags = {
    Name = "DevOps-App-Server"
  }
}