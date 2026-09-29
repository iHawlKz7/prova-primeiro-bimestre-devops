data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "al2023-ami-2023.*-x86_64"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "api" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]

  associate_public_ip_address = true
  iam_instance_profile        = "LabInstanceProfile"

  user_data = <<-EOF
    #!/bin/bash
    set -e

    dnf update -y
    dnf install -y docker git

    systemctl enable docker
    systemctl start docker

    cd /home/ec2-user

    git clone ${var.repository_url} app
    cd app

    docker build -t reservas-api ./app

    DB_PASSWORD_B64='${base64encode(var.db_password)}'
    DB_PASSWORD_DECODED="$(printf '%s' "$DB_PASSWORD_B64" | base64 --decode)"

    docker run -d \
      --name reservas-api \
      --restart unless-stopped \
      -p 3000:3000 \
      -e PORT=3000 \
      -e DB_HOST=${var.db_host} \
      -e DB_PORT=5432 \
      -e DB_NAME=${var.db_name} \
      -e DB_USER=${var.db_username} \
      -e DB_PASSWORD="$DB_PASSWORD_DECODED" \
      -e DB_SSL=true \
      reservas-api

    unset DB_PASSWORD_B64
    unset DB_PASSWORD_DECODED
  EOF

  tags = {
    Name    = "${var.project_name}-api"
    Project = var.project_name
    RA      = "6325192"
  }
}
