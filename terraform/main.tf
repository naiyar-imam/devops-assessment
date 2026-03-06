############################################
# TERRAFORM CONFIGURATION
############################################

terraform {

  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }

  }

}

############################################
# AWS PROVIDER
############################################

provider "aws" {
  region = var.region
}

############################################
# RANDOM SUFFIX (AVOID NAME COLLISION)
############################################

resource "random_id" "suffix" {
  byte_length = 3
}

############################################
# DEFAULT VPC
############################################

data "aws_vpc" "default" {
  default = true
}

############################################
# DEFAULT SUBNETS
############################################

data "aws_subnets" "default" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

}

############################################
# SECURITY GROUP
############################################

resource "aws_security_group" "app_sg" {

  name   = "devops-assessment-sg-${random_id.suffix.hex}"
  vpc_id = data.aws_vpc.default.id

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

############################################
# IAM ROLE FOR EC2
############################################

resource "aws_iam_role" "ec2_role" {

  name = "devops-ec2-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }

    ]

  })

}

############################################
# ATTACH ECR READ POLICY
############################################

resource "aws_iam_role_policy_attachment" "ecr_read" {

  role       = aws_iam_role.ec2_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"

}

############################################
# INSTANCE PROFILE
############################################

resource "aws_iam_instance_profile" "ec2_profile" {

  name = "devops-instance-profile-${random_id.suffix.hex}"

  role = aws_iam_role.ec2_role.name

}

############################################
# ECR REPOSITORIES
############################################

resource "aws_ecr_repository" "backend_repo" {

  name = "devops-backend-${random_id.suffix.hex}"

}

resource "aws_ecr_repository" "frontend_repo" {

  name = "devops-frontend-${random_id.suffix.hex}"

}

############################################
# UBUNTU AMI
############################################

data "aws_ami" "ubuntu" {

  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    ]
  }

}

############################################
# EC2 INSTANCE
############################################

resource "aws_instance" "app_server" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [
    aws_security_group.app_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  key_name = var.key_name

  tags = {
    Name = "devops-server-${random_id.suffix.hex}"
  }

}