resource "aws_vpc" "cluster" {
  cidr_block = "10.240.0.0/16"

  tags = {
    Name        = "kubernetes-the-hard-way-${terraform.workspace}"
    ManagedBy   = "Terraform"
    Environment = terraform.workspace
  }
}

resource "aws_subnet" "cluster" {
  vpc_id                  = aws_vpc.cluster.id
  cidr_block              = "10.240.0.0/24"
  availability_zone       = var.zone
  map_public_ip_on_launch = "true"

  tags = {
    Name        = "kubernetes-the-hard-way-${terraform.workspace}"
    ManagedBy   = "Terraform"
    Environment = terraform.workspace
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.cluster.id

  tags = {
    Name        = "kubernetes-the-hard-way-${terraform.workspace}"
    ManagedBy   = "Terraform"
    Environment = terraform.workspace
  }
}

resource "aws_route_table" "routes" {
  vpc_id = aws_vpc.cluster.id

  tags = {
    Name        = "kubernetes-the-hard-way-${terraform.workspace}"
    ManagedBy   = "Terraform"
    Environment = terraform.workspace
  }
}

resource "aws_route" "egress" {
  route_table_id         = aws_route_table.routes.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route" "pods" {
  count = length(aws_instance.worker.*.id)

  route_table_id         = aws_route_table.routes.id
  destination_cidr_block = "10.200.${count.index}.0/24"
  instance_id            = aws_instance.worker[count.index].id
}

resource "aws_route_table_association" "cluster" {
  subnet_id      = aws_subnet.cluster.id
  route_table_id = aws_route_table.routes.id
}
