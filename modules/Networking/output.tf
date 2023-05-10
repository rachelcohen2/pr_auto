output "private_sub_b" {
  value = aws_subnet.private_sub_b.id
}

output "nat_private_sub" {
  value = aws_subnet.private_sub_a.id
}

output "security_group_id" {
  value = aws_security_group.allow_ssh.id
}

output "vpc_ip" {
  value = aws_vpc.my_vpc.id
}

output "private_sub_a" {
  value = aws_subnet.private_sub_a.id
}

output "public_sub_a" {
  value = aws_subnet.public_sub_a.id
}

output "public_sub_b" {
  value = aws_subnet.public_sub_b.id
}