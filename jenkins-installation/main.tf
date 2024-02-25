provider "aws" {
  region = "eu-north-1"
}

resource "aws_instance" "jenkins_instance" {
  ami           = "ami-0014ce3e52359afbd"  # Replace with your desired AMI ID
  instance_type = "t3.micro"                # Adjust instance type as needed

  key_name      = "bigkey"      # Replace with your EC2 key pair name
  vpc_security_group_ids = ["sg-0ecdd245a67e6d166"]  # Replace with your security group(s)


  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y java-1.8.0-openjdk",  # Install Java (required for Jenkins)
      "sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins.io/redhat-stable/jenkins.repo",  # Add Jenkins repository
      "sudo rpm --import http://pkg.jenkins.io/redhat-stable/jenkins.io.key",  # Import Jenkins GPG key
      "sudo yum install -y jenkins",  # Install Jenkins
      "sudo systemctl start jenkins",  # Start Jenkins service
    ]
  }
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins_instance.public_ip
}
