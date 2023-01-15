resource "aws_vpc" "main" {
  cidr_block = "10.1.0.0/16" # /16 give us 64534 possible ip addresses
  # ref : https://www.aelius.com/njh/subnet_sheet.html

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    tomap({ Name = "${local.prefix}-vpc", }),
    local.common_tags
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id # internet gateway connected to vpc to allow inbound/outbound connection with outside world
  tags = merge(
    tomap({ Name = "${local.prefix}-main" }),
    local.common_tags
  )
}

#####################################################
# Public Subnets - Inbound/Outbound Internet Access #
#####################################################

# Subnet A

resource "aws_subnet" "public_a" {
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "${data.aws_region.current.name}a"
  tags = merge(
    tomap({ Name = "${local.prefix}-public-a" }),
    local.common_tags
  )
}

resource "aws_route_table" "public_a" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    tomap({ Name = "${local.prefix}-public-a" }),
    local.common_tags
  )
}

resource "aws_route_table_association" "public_a" {
  # this code block means to link between subnet a and route table
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_a.id
}

resource "aws_route" "public_internet_access_a" {
  # link our subnet a to the internet gateway
  route_table_id         = aws_route_table.public_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_eip" "public_a" {
  # ElasticIP
  vpc = true

  tags = merge(
    tomap({ Name = "${local.prefix}-public-a" }),
    local.common_tags
  )

}

resource "aws_nat_gateway" "public_a" {
  allocation_id = aws_eip.public_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = merge(
    tomap({ Name = "${local.prefix}-public-a" }),
    local.common_tags
  )
}

# Subnet B


resource "aws_subnet" "public_b" {
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "${data.aws_region.current.name}b"
  tags = merge(
    tomap({ Name = "${local.prefix}-public-b" }),
    local.common_tags
  )
}

resource "aws_route_table" "public_b" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    tomap({ Name = "${local.prefix}-public-b" }),
    local.common_tags
  )
}

resource "aws_route_table_association" "public_b" {
  # this code block means to link between subnet a and route table
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_b.id
}

resource "aws_route" "public_internet_access_b" {
  # link our subnet a to the internet gateway
  route_table_id         = aws_route_table.public_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_eip" "public_b" {
  # ElasticIP
  vpc = true

  tags = merge(
    tomap({ Name = "${local.prefix}-public-b" }),
    local.common_tags
  )

}

resource "aws_nat_gateway" "public_b" {
  allocation_id = aws_eip.public_b.id
  subnet_id     = aws_subnet.public_b.id

  tags = merge(
    tomap({ Name = "${local.prefix}-public-b" }),
    local.common_tags
  )
}

#####################################################
# Private Subnets - Outbound Internet Access Only   #
#####################################################

# Subnet A

resource "aws_subnet" "private_a" {
  cidr_block        = "10.1.10.0/24"
  vpc_id            = aws_vpc.main.id
  availability_zone = "${data.aws_region.current.name}a"

  tags = merge(
    tomap({ Name = "${local.prefix}-private-a" }),
    local.common_tags
  )
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    tomap({ Name = "${local.prefix}-private-a" }),
    local.common_tags
  )
}

resource "aws_route_table_association" "private_a" {
  # this code block means to link between subnet a and route table
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route" "private_a_internet_out" {
  route_table_id         = aws_route_table.private_a.id
  nat_gateway_id         = aws_nat_gateway.public_a.id # link to our public network for outbound traffic
  destination_cidr_block = "0.0.0.0/0"
}

# Subnet B

resource "aws_subnet" "private_b" {
  cidr_block        = "10.1.11.0/24"
  vpc_id            = aws_vpc.main.id
  availability_zone = "${data.aws_region.current.name}b"

  tags = merge(
    tomap({ Name = "${local.prefix}-private-b" }),
    local.common_tags
  )
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    tomap({ Name = "${local.prefix}-private-b" }),
    local.common_tags
  )
}

resource "aws_route_table_association" "private_b" {
  # this code block means to link between subnet a and route table
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

resource "aws_route" "private_b_internet_out" {
  route_table_id         = aws_route_table.private_b.id
  nat_gateway_id         = aws_nat_gateway.public_b.id # link to our public network for outbound traffic
  destination_cidr_block = "0.0.0.0/0"
}