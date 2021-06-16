output "vpc_id" {
  value       = aws_vpc.main_vpc.id
  description = "The ID of the VPC"
}

output "private_subnet" {
  value       = [for i, v in aws_subnet.private_subnet : v.id]
  description = "The IDs of the private subnets"
}

output "public_subnet" {
  value       = [for i, v in aws_subnet.public_subnet : v.id]
  description = "The IDs of the public subnets"
}
