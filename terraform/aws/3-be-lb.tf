#Author
#Bhasker C V (bhasker@unixindia.com)

#Lets init the provider
provider "aws" {
  region = "eu-west-2"
}

# Create a VPC

resource "aws_vpc" "bhasker_vpc" {
  cidr_block = "10.8.0.0/16"
}

#associate VPC with a public ip 
resource "aws_internet_gateway" "bhasker_gw" {
  vpc_id = aws_vpc.bhasker_vpc.id
}

# and create a corresponding local subnet
resource "aws_subnet" "bhasker_subnet" {

  vpc_id = aws_vpc.bhasker_vpc.id
  map_public_ip_on_launch = true
  cidr_block = "10.8.1.0/24"

}

# Give the subnet a security group for port permissions

resource "aws_security_group" "bhasker_sg" {
  name        = "bhasker_sg"
  description = "For VM LB"
  vpc_id      = aws_vpc.bhasker_vpc.id

  # ssh access from anywhere
  ingress {
    from_port   = 22  # allow ssh
    to_port     = 22  # allow ssh
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

#Very first machine

resource "aws_instance" "bcv-be1" {
  ami           = "ami-0d8e27447ec2c8410"
  instance_type = "t2.micro"
#  availability_zone = "eu-west-2a"
#  security_groups = [ "default" ]
  key_name = "bhasker-london"
  subnet_id = aws_subnet.bhasker_subnet.id  
vpc_security_group_ids = [aws_security_group.bhasker_sg.id]
  associate_public_ip_address = tobool("false")
  tags = {
    Name = "VM1"
    type = "maintype1"
    postgres = "11"
## can use ansible -a "ls" tag_postgres_11 --list-hosts
  }
}

#Second one
resource "aws_instance" "bcv-be2" {
  ami           = "ami-0d8e27447ec2c8410"
  instance_type = "t2.micro"
#  availability_zone = "eu-west-2a"
#  security_groups = [ "default" ]
  key_name = "bhasker-london"
  associate_public_ip_address = tobool("false")

  subnet_id = aws_subnet.bhasker_subnet.id  
vpc_security_group_ids = [aws_security_group.bhasker_sg.id]
  tags = {
    Name = "VM2"
    type = "type2"
  }
}

#Third one
resource "aws_instance" "bcv-be3" {
  ami           = "ami-0d8e27447ec2c8410"
  instance_type = "t2.micro"
#  availability_zone = "eu-west-2a"
#  security_groups = [ "default" ]
  key_name = "bhasker-london"
  associate_public_ip_address = tobool("false")

  subnet_id = aws_subnet.bhasker_subnet.id  
vpc_security_group_ids = [aws_security_group.bhasker_sg.id]
  tags = {
    Name = "VM3"
    type = "type3"
  }
}

#All load balanced behind port 22 for ssh 
resource "aws_elb" "bhasker"  {
 name = "fe" 
  listener {
    instance_port     = 22
    instance_protocol = "tcp"
    lb_port           = 22
    lb_protocol       = "tcp"
  }

instances       = [aws_instance.bcv-be1.id, aws_instance.bcv-be2.id,aws_instance.bcv-be3.id]
subnets  = [aws_subnet.bhasker_subnet.id]
}
