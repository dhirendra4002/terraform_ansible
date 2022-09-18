provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "ap-south-1"
}

variable "privatekey" {
  default = "/etc/ansible/xyz.pem"
}
resource "aws_security_group" "splunk" {
  name        = "terraform-splunk"
  description = "Created by terraform"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-068257025f72f470d"
  key_name      = "xyz"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.splunk.name}"]
    connection {
    host        = "${self.public_ip}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("xyz.pem")
  }

  tags = {
    Name = "Prod"
  }
  provisioner "remote-exec" {
    inline = [
      "ping -c 10 8.8.8.8",
    ]
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u ubuntu -i ${aws_instance.web.public_ip}, --private-key ${var.privatekey} play.yml"
  }
}
output "web_ip" {
  value = aws_instance.web.public_ip
}
##################ansible.cfg############################

[defaults]
remote_user=ubuntu
host_key_checking= False