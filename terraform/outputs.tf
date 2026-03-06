output "ec2_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "backend_ecr_url" {
  value = aws_ecr_repository.backend_repo.repository_url
}

output "frontend_ecr_url" {
  value = aws_ecr_repository.frontend_repo.repository_url
}