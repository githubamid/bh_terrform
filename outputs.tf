output "latest_amazon_image" {
  value = data.aws_ami.latest_ami.id
}

output "region" {
  value = var.region
}

output "EIP" {
  value = aws_eip.ec2eip.id
}
