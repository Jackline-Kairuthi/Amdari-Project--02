###############################################
# VPC
###############################################
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main"
  }
}

###############################################
# Internet Gateway (required for NAT)
###############################################
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

###############################################
# Public Subnet (for NAT Gateway)
###############################################
resource "aws_subnet" "public0" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public0"
  }
}

###############################################
# NAT Gateway
###############################################
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "main-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public0.id

  tags = {
    Name = "main-nat"
  }
}

###############################################
# Private Subnets (2 AZs)
###############################################
resource "aws_subnet" "private0" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-1a"

  tags = {
    Name = "private0"
  }
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-1b"

  tags = {
    Name = "private1"
  }
}

###############################################
# Private Route Table (routes to NAT)
###############################################
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

###############################################
# Route Table Associations
###############################################
resource "aws_route_table_association" "private0" {
  subnet_id      = aws_subnet.private0.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}
