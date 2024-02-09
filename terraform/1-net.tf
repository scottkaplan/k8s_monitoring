provider "aws" {
  region = "us-west-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

resource "aws_vpc" "firefly" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "firefly"
  }
}

resource "aws_internet_gateway" "firefly-igw" {
  vpc_id = aws_vpc.firefly.id

  tags = {
    Name = "firefly-igw"
  }
}

resource "aws_subnet" "private-us-west-1a" {
  vpc_id            = aws_vpc.firefly.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = "us-west-1a"

  tags = {
    "Name"                            = "private-us-west-1a"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/demo"      = "owned"
  }
}

resource "aws_subnet" "private-us-west-1c" {
  vpc_id            = aws_vpc.firefly.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = "us-west-1c"

  tags = {
    "Name"                            = "private-us-west-1c"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/demo"      = "owned"
  }
}

resource "aws_subnet" "public-us-west-1a" {
  vpc_id                  = aws_vpc.firefly.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name"                       = "public-us-west-1a"
    "kubernetes.io/role/elb"     = "1"
    "kubernetes.io/cluster/demo" = "owned"
  }
}

resource "aws_subnet" "public-us-west-1c" {
  vpc_id                  = aws_vpc.firefly.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = "us-west-1c"
  map_public_ip_on_launch = true

  tags = {
    "Name"                       = "public-us-west-1c"
    "kubernetes.io/role/elb"     = "1"
    "kubernetes.io/cluster/demo" = "owned"
  }
}

resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "nat"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-us-west-1a.id

  tags = {
    Name = "nat"
  }

  depends_on = [aws_internet_gateway.firefly-igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.firefly.id

  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      nat_gateway_id             = aws_nat_gateway.nat.id
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      gateway_id                 = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    },
  ]

  tags = {
    Name = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.firefly.id

  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      gateway_id                 = aws_internet_gateway.firefly-igw.id
      nat_gateway_id             = ""
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    },
  ]

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "private-us-west-1a" {
  subnet_id      = aws_subnet.private-us-west-1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-us-west-1c" {
  subnet_id      = aws_subnet.private-us-west-1c.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public-us-west-1a" {
  subnet_id      = aws_subnet.public-us-west-1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-us-west-1c" {
  subnet_id      = aws_subnet.public-us-west-1c.id
  route_table_id = aws_route_table.public.id
}

provider "kubernetes" {
  host                   = aws_eks_cluster.demo.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.demo.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

