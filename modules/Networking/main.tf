terraform {
  required_version = ">= 0.12"
}

####################################################################
# AWS vpc
#####################################################################

resource "aws_vpc" "my_vpc" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "My VPC"
  }
}

####################################################################
# Two public subnets
#####################################################################

resource "aws_subnet" "public_sub_a" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "Public Subnet A"
  }
}

resource "aws_subnet" "public_sub_b" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.6.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name = "Public Subnet B"
  }
}



####################################################################
# Creating an internet gateway (for the public subnets rout table)
#####################################################################

resource "aws_internet_gateway" "my_vpc_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "My VPC - Internet Gateway"
  }
}

####################################################################
# Rout table for the public subnets
#####################################################################

resource "aws_route_table" "my_vpc_us_east_1a_public" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_vpc_igw.id
    }

    tags = {
        Name = "Public Subnet Route Table."
    }
}
####################################################################
# Associate the two public subnets to the route table (with the igw)
#####################################################################

resource "aws_route_table_association" "my_vpc_us_east_1a_public" {
    subnet_id = aws_subnet.public_sub_a.id
    route_table_id = aws_route_table.my_vpc_us_east_1a_public.id
}

resource "aws_route_table_association" "my_vpc_us_east_1b_public" {
    subnet_id = aws_subnet.public_sub_b.id
    route_table_id = aws_route_table.my_vpc_us_east_1a_public.id
}

####################################################################
# Security group
#####################################################################

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_sg"
  description = "Allow SSH inbound connections"
  vpc_id = aws_vpc.my_vpc.id

  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  #  ingress {
  #   from_port   = 8080
  #   to_port     = 8080
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_sg"
  }
}

####################################################################
# Two elastic ips for the two nat gateways
#####################################################################

resource "aws_eip" "nat_gw_eip_a" {
  vpc = true
}

resource "aws_eip" "nat_gw_eip_b" {
  vpc = true
}

####################################################################
# Two nat gateways for the two route tables private subnets
#####################################################################

resource "aws_nat_gateway" "gw_a" {
  allocation_id = aws_eip.nat_gw_eip_a.id
  subnet_id     = aws_subnet.public_sub_a.id
}

resource "aws_nat_gateway" "gw_b" {
  allocation_id = aws_eip.nat_gw_eip_b.id
  subnet_id     = aws_subnet.public_sub_b.id
}

####################################################################
# Two route tables for the two private subnets
#####################################################################

resource "aws_route_table" "my_vpc_us_east_1a_nated" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.gw_a.id
    }

    tags = {
        Name = "Main Route Table for NAT-ed subnet a"
    }
}

resource "aws_route_table" "my_vpc_us_east_1b_nated" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.gw_b.id
    }

    tags = {
        Name = "Main Route Table for NAT-ed subnet b"
    }
}

####################################################################
# Two private subnets
#####################################################################

resource "aws_subnet" "private_sub_a" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "NAT-ed Subnet"
  }
}

resource "aws_subnet" "private_sub_b" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name = "Isolated Private Subnet"
  }
}

####################################################################
# Associate the two private subnets to the two route tables 
#####################################################################

resource "aws_route_table_association" "my_vpc_us_east_1a_nated" {
    subnet_id = aws_subnet.private_sub_a.id
    route_table_id = aws_route_table.my_vpc_us_east_1a_nated.id
}




resource "aws_route_table_association" "my_vpc_us_east_1a_private" {
    subnet_id = aws_subnet.private_sub_b.id
    route_table_id = aws_route_table.my_vpc_us_east_1b_nated.id
}