provider "aws" {
  region = "ap-south-1"
}

# -----------------------------
# Create VPC
# -----------------------------
resource "aws_vpc" "devops_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "devops-vpc"
  }
}

# -----------------------------
# Internet Gateway
# -----------------------------
resource "aws_internet_gateway" "devops_igw" {
  vpc_id = aws_vpc.devops_vpc.id

  tags = {
    Name = "devops-igw"
  }
}

# -----------------------------
# Public Subnet
# -----------------------------
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "devops-public-subnet"
  }
}

# -----------------------------
# Route Table
# -----------------------------
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.devops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops_igw.id
  }

  tags = {
    Name = "devops-route-table"
  }
}

# -----------------------------
# Route Table Association
# -----------------------------
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# -----------------------------
# Security Group
# -----------------------------
resource "aws_security_group" "devops_sg" {
  name   = "devops-security-group"
  vpc_id = aws_vpc.devops_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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

  ingress {
    description = "HTTPS"
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

  tags = {
    Name = "devops-security-group"
  }
}

# -----------------------------
# EC2 Instance
# -----------------------------
resource "aws_instance" "devops_server" {

  ami           = "ami-03bb6d83c60fc5f7c"   # Amazon Linux (Mumbai region)
  instance_type = "t2.micro"
  key_name      = "devops-key"

  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  associate_public_ip_address = true

  tags = {
    Name = "DevOps-App-Server"
  }

  user_data = <<-EOF
#!/bin/bash

# Update packages
sudo yum update -y

# Install Docker
sudo yum install -y docker

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Allow ec2-user to run docker commands
sudo usermod -aG docker ec2-user

# Install AWS CLI
sudo yum install -y aws-cli

# Verify installations
docker --version
aws --version

EOF

}

# Output the public IP of the EC2 instanceSSS