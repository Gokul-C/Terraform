# Creating vpc , subnet , gateway , route tables , security groups
# Choosing ec2 instace type and instace image , and automating ssh login 
# Deploying ec2 instance and run bash script to execute some commands 

//repressent provider like aws,azure ect .. and type region which is nearest to you
//install aws cli and install iam role access key and secreat key as env variable in system

provider "aws" {                     
    region = "ap-south-1"            
                                

}

//variables -- these are mentioned in another file

variable "vpc-cidr_block" {}
variable "subnet1-cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {} 
variable "instance_type" {}
variable "public_key_location" {}
  

//Creating vpc ----1

resource "aws_vpc" "myapp-vpc" {    
    cidr_block = var.vpc-cidr_block            
    tags = {
        Name: "${var.env_prefix}-vpc"
    } 
}

//Creating subnet ----2

resource "aws_subnet" "myapp-subnet-1" {     
   vpc_id = aws_vpc.myapp-vpc.id
   cidr_block = var.subnet1-cidr_block             
    availability_zone = "ap-south-1a"      
    tags = {
      Name: "${var.env_prefix}-subnet-1"
    }
}

//Creating gateway   ----3

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name: "${var.env_prefix}-igw"
  }
  
}

// Creating EXTRA route table 

/*resource "aws_route_table" "mypp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name: "${var.env_prefix}-rtb"
  }
}

# Creating EXTRA subnet Association

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id = aws_subnet.dev-subnet-1.id
  route_table_id = aws_route_table.mypp-route-table.id
  
}*/

//Using default route table for existing vpc    ------4

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

  route {
     cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name: "${var.env_prefix}-main-rtb"
  }
  
}

/*# Creating EXTRA security group -- configuring incoming & outgoing ports

resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

#incoming ports need to be opend

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outgoing ports need to be opend

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name: "${var.env_prefix}-sg"
  }
  
}  */

//Using default security group ---- configuring incoming & outgoing ports  -------- -5

resource "aws_default_security_group" "default-sg" {
  
  vpc_id = aws_vpc.myapp-vpc.id

//incoming ports need to be opend

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //Outgoing ports need to be opend

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name: "${var.env_prefix}-default-sg"
  }
  
}

// selecting EC2 instance   ---6

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]

  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  
}

//shows ami id for confirmation

output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.public_key_location)
  
}

// configuring ec2 instace for deployment -----7

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone = var.avail_zone
  
  associate_public_ip_address = true      //we can access this from browser
  key_name = aws_key_pair.ssh-key.key_name

  //writing bash script to make somthing after deploing ec2 instance
  //this bash script only run once while creating the total infra structure
  //if you want to run bash script after deploying infra structure
  //then write on last line (foo = "bar") without brackets
  //we can write shell script here (or) we can specify script file as variable file.

  /*user_data = <<EOF
                  #!/bin/bash
                  sudo yum update -y && sudo yum install -y docker
                  sudo systemctl start docker
                  sudo usermod -aG docker ec2-user
                  docker run -p 8080:80 nginx
              EOF*/

  //mentioning script file to run after deploying of ec2 instance.

  user_data = file("entry-script.sh")            

  tags = {
    Name = "${var.env_prefix}-server"
    //foo = "bar"
  }
  
  
}

