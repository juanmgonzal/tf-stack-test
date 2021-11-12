resource "aws_vpc" "vpc" {
    cidr_block = "${var.vpc_cidr}"
    tags = {
        Name = "myVpc"
    }
}

# Creates de Internet GW
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

# Creates one subnet for every availability zone to use
resource "aws_subnet" "web_subnets" {
    # Creates 
    count                   = var.az_count > local.az_avail_count ? local.az_avail_count : var.az_count

    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, var.subnet_newbit, count.index)
    availability_zone       = data.aws_availability_zones.aws_az.names[count.index]
    map_public_ip_on_launch = true

    tags = {
        Name = "subnet_${count.index}"
    }
}


# Creates security group for the webserver instances
resource "aws_security_group" "web_sec" {
    name = "web_sec"
    description = "HTTP and SSH rules"
    vpc_id = aws_vpc.vpc.id

    # Allow ssh from anywhere
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow http port only fron vpc cidr
    ingress {
        from_port   = "80"
        to_port     = "80"
        protocol    = "tcp"
        cidr_blocks = [aws_vpc.vpc.cidr_block]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
    tags = {
        Name = "web_sec"
    }
}

# creates webservers_count instances spread among the aws_subnet.web_subnets created before
resource "aws_instance" "web" {
    count                   = length(var.webservers_app)
    ami                     = data.aws_ami.ubuntu.id
    instance_type           = var.webservers_type
    subnet_id               = aws_subnet.web_subnets[count.index % length(aws_subnet.web_subnets) ].id
    vpc_security_group_ids  = [ aws_security_group.web_sec.id ]
    user_data               = templatefile("webserver_install.tpl", { app = var.webservers_app[count.index] })

    tags = {
        Name = "instance_${count.index}"
        App = var.webservers_app[count.index]
    }
}

# Security group to allow incoming http port
resource "aws_security_group" "elb_sec" {
    name        = "webserverELB"
    vpc_id      = aws_vpc.vpc.id

    # HTTP access from anywhere
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # outbound internet access
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Creates the elastic load balanceer
resource "aws_elb" "web" {
    name            = "webserver-elb"
    subnets         = aws_subnet.web_subnets[*].id
    security_groups = [ aws_security_group.elb_sec.id ]
    instances       = aws_instance.web[*].id

    listener {
        instance_port     = 80
        instance_protocol = "http"
        lb_port           = 80
        lb_protocol       = "http"
    }
    
    health_check {
        target              = "HTTP:80/"
        interval            = 30
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 5
    }
}
