provider "aws" {
  region = var.region
}

resource "aws_security_group" "app_sg" {
  name = "devops-sg"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_server" {
  ami           = "ami-0f58b397bc5c1f2e8" # Ubuntu (update per region)
  instance_type = "t2.micro"

  security_groups = [aws_security_group.app_sg.name]

  key_name = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt update
              apt install docker.io -y
              usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "DevOps-App-Server"
  }
}