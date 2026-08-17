resource "aws_vpc" "this" {
  cidr_block = var.cidr_block

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = { for subnet in var.public_subnets : subnet.availability_zone => subnet }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${each.key}"
    Tier = "public"
  })
}

resource "aws_subnet" "private_app" {
  for_each = { for subnet in var.private_app_subnets : subnet.availability_zone => subnet }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name}-private-app-${each.key}"
    Tier = "private-app"
  })
}

resource "aws_subnet" "private_db" {
  for_each = { for subnet in var.private_db_subnets : subnet.availability_zone => subnet }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name}-private-db-${each.key}"
    Tier = "private-db"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count = var.create_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip"
  })
}

resource "aws_nat_gateway" "this" {
  count = var.create_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[var.public_subnets[0].availability_zone].id

  tags = merge(var.tags, {
    Name = "${var.name}-nat"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.create_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[0].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-private-app-rt"
  })
}

resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.private_app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table" "private_db" {
  count = length(var.private_db_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-private-db-rt"
  })
}

resource "aws_route_table_association" "private_db" {
  for_each = aws_subnet.private_db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db[0].id
}
