
provider "aws" {
  region = "ap-south-1"
}

# --- 1. DYNAMIC AMI LOOKUP (Finds the latest Ubuntu automatically) ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu Creator)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- 2. NETWORK (VPC) ---
resource "aws_vpc" "lab_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "Sentinel-VPC" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.lab_vpc.id
}

# REMOVED "availability_zone" to let AWS pick the best working zone for you
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "Sentinel-Public-Subnet" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.lab_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# --- 3. FIREWALLS (Security Groups) ---

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Allow SSH and Jenkins"
  vpc_id      = aws_vpc.lab_vpc.id

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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "target_sg" {
  name        = "target_sg"
  description = "Allow SSH and Web Traffic"
  vpc_id      = aws_vpc.lab_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "monitor_sg" {
  name        = "monitor_sg"
  description = "Allow SSH, Kibana, Wazuh"
  vpc_id      = aws_vpc.lab_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 1514
    to_port     = 1514
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 4. SERVERS (EC2 Instances) ---

# CHANGED: Using "t3.micro" (Newer, supported everywhere)
# CHANGED: Using "data.aws_ami.ubuntu.id" (Automatically finds correct Image)

resource "aws_instance" "jenkins_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = "sentinel-key" 
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  tags = { Name = "Sentinel-Jenkins" }
}

resource "aws_instance" "target_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = "sentinel-key"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.target_sg.id]
  tags = { Name = "Sentinel-Target" }
}

resource "aws_instance" "monitor_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro" # Downgraded to micro to fix your error. ELK might be slow.
  key_name      = "sentinel-key"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.monitor_sg.id]
  tags = { Name = "Sentinel-Monitor" }
}

# --- 5. OUTPUTS ---
output "jenkins_ip" {
  value = aws_instance.jenkins_node.public_ip
}

output "target_ip" {
  value = aws_instance.target_node.public_ip
}

output "monitor_ip" {
  value = aws_instance.monitor_node.public_ip
}
