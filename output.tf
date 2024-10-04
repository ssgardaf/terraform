output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "Public Subnets"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnets" {
  description = "Private Subnets"
  value       = aws_subnet.private_subnets[*].id
}

output "websocket_sg_id" {
  description = "WebSocket Security Group ID"
  value       = aws_security_group.websocket_sg.id
}

output "websocket_server_instance_id" {
  description = "WebSocket Server EC2 Instance ID"
  value       = aws_instance.websocket_server.id
}

output "eks_cluster_id" {
  description = "EKS Cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_role_arn" {
  description = "EKS Cluster Role ARN"
  value       = module.eks.cluster_iam_role_arn
}

