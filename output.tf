output "on_prem_private_ip" {
  value = aws_instance.on-prem.private_ip
}

output "on_prem_public_ip" {
  value = aws_instance.on-prem.public_ip
}