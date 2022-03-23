
provider "aws" {                      #provider name like aws , azure ,gcp
    region = "ap-south-1"             #select nearest region to you
                                #secreat key is given to iam role means admin

}

variable "vpc-cidr_block" {
  description = "vpc cidr block"
  
}

variable "subnet1-cidr_block" {
  description = "subnet1-cidr block"
  
}

variable "subnet2-cider_block" {
  description = "subnet2 cider block"
  
}

variable "subnet2-tag" {
  description = "name of the subnet2"
  
}

resource "aws_vpc" "devlopment_vpc" {    #Creating vpc (virtual private cloud) for instance , given name aws_vpc , 
                                         # "devlopment_vpc" is any name can give .
    cidr_block = var.vpc-cidr_block            # its vpc range
    tags = {
        Name: "development"
    } 
  
}

#creating and configuring subnet for instance

resource "aws_subnet" "dev-subnet-1" {     #creating subnet and "dev-subnet-1" is name can give any name.
   vpc_id = aws_vpc.devlopment_vpc.id
   cidr_block = var.subnet1-cidr_block            #subnet range 
    availability_zone = "ap-south-1a"      #select nearest range
    tags = {
      Name: "subnet-1-dev"
    }
}
  
data "aws_vpc" "existing_vpc" {
   default = true
}


resource "aws_subnet" "dev-subnet-2" {     #creating subnet and "dev-subnet-1" is name can give any name.
    vpc_id = data.aws_vpc.existing_vpc.id     #creating vpc id for above mentioned names
    cidr_block = var.subnet2-cider_block            #subnet range 
    availability_zone = "ap-south-1a"      #select nearest range
    tags = {
      Name: var.subnet2-tag
    }
}