output "all_subnet_ids" {
  description = "List of all Subnet IDs in the current region"
  value = data.aws_subnets.current_region.ids
}

output "public_ip_serv1" {
  value = aws_instance.web_server[0].public_ip
}

output "privet_ip_serv1" {
  value = aws_instance.web_server[0].private_ip
}

output "public_ip_serv2" {
  value = aws_instance.web_server[1].public_ip
}

output "privet_ip_serv2" {
  value = aws_instance.web_server[1].private_ip
}

output "web_load_balancer_url" {
  description = "The URL of the web load balancer"
  value = aws_lb.web.dns_name
}