output "elb-dns" {
  description = "The DNS name of the ELB"
  value       = aws_elb.elb.dns_name
}
