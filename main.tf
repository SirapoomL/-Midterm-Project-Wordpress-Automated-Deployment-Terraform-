provider "aws" {
    region = var.region
}

# Create a new VPC
resource "aws_vpc" "wp_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "cloud_midterm"
    }
}

# Internet Gateway for the VPC
resource "aws_internet_gateway" "wp_igw" {
    vpc_id = aws_vpc.wp_vpc.id

    tags = {
        Name = "cloud_midterm_wp_igw"
    }
}

resource "aws_subnet" "public_wp" {
    vpc_id = aws_vpc.wp_vpc.id
    cidr_block = "10.0.0.16/28"
    availability_zone = var.availability_zone

    tags = {
        Name = "cloud_midterm_public_wp"
    }
}

resource "aws_subnet" "public_nat" {
    vpc_id = aws_vpc.wp_vpc.id
    cidr_block = "10.0.0.32/28"
    availability_zone = var.availability_zone

    tags = {
        Name = "cloud_midterm_public_nat"
    }
}

resource "aws_subnet" "private_wp" {
    vpc_id = aws_vpc.wp_vpc.id
    cidr_block = "10.0.0.48/28"
    availability_zone = var.availability_zone

    tags = {
        Name = "cloud_midterm_private_wp"
    }
}

resource "aws_subnet" "private_nat" {
    vpc_id = aws_vpc.wp_vpc.id
    cidr_block = "10.0.0.64/28"
    availability_zone = var.availability_zone

    tags = {
        Name = "cloud_midterm_private_nat"
    }
}

# Elastic IP
resource "aws_eip" "wp_eip" {
    tags = {
        Name = "cloud_midterm_wordpress_eip"
    }
}

resource "aws_eip" "nat" {
    tags = {
        Name = "cloud_midterm_nat_eip"
    }
}

resource "aws_nat_gateway" "nat_gtw" {
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.public_nat.id

    tags = {
        Name = "cloud_midterm_nat_gtw"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.wp_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.wp_igw.id
    }

    tags = {
        Name = "cloud_midterm_route_public"
    }
}

resource "aws_route_table_association" "public_wp" {
    subnet_id = aws_subnet.public_wp.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_nat" {
    subnet_id = aws_subnet.public_nat.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.wp_vpc.id

    tags = {
        Name = "cloud_midterm_route_private"
    }
}

resource "aws_route_table_association" "private_wp" {
    subnet_id = aws_subnet.private_wp.id
    route_table_id = aws_route_table.private.id
}

resource "aws_route_table" "private_nat" {
    vpc_id = aws_vpc.wp_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gtw.id
    }

    tags = {
        Name = "cloud_midterm_route_private_nat"
    }
}

resource "aws_route_table_association" "private_db_nat" {
    subnet_id = aws_subnet.private_nat.id
    route_table_id = aws_route_table.private_nat.id
}

resource "aws_iam_user" "s3_iam" {
    name = "cloud_midterm_s3_iam"

    tags = {
        Name = "cloud_midterm_s3_full_access"
    }
}

resource "aws_iam_user_policy_attachment" "s3_iam" {
    user = aws_iam_user.s3_iam.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_access_key" "s3_iam" {
    user = aws_iam_user.s3_iam.name
}

# Create an S3 bucket for WordPress media files
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name
  force_destroy = true

  tags = {
    Name = "cloud_midterm_s3"
  }
}

# Ownership Controls
resource "aws_s3_bucket_ownership_controls" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Public Access Block
resource "aws_s3_bucket_public_access_block" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ACL - last resource applied to the bucket
resource "aws_s3_bucket_acl" "s3_bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.s3_bucket,
    aws_s3_bucket_public_access_block.s3_bucket,
  ]

  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "public-read"
}

resource "aws_security_group" "default" {
    name        = "cloud_midterm_sg_default"
    description = "Allow traffic within the VPC"
    vpc_id      = aws_vpc.wp_vpc.id
    
    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "cloud_midterm_sg_default"
    }
}

resource "aws_security_group" "wordpress_sg" {
  name        = "cloud_midterm_wordpress_sg"
  description = "Allow web traffic to WordPress"
  vpc_id      = aws_vpc.wp_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloud_midterm_wordpress_sg"
  }
}

resource "aws_security_group" "mariadb_sg" {
  name        = "cloud_midterm_mariadb_sg"
  description = "Allow MySQL"
  vpc_id      = aws_vpc.wp_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.wordpress_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.wordpress_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloud_midterm_mariadb_sg"
  }
}

resource "aws_network_interface" "wp_with_internet" {
    subnet_id   = aws_subnet.public_wp.id
    security_groups = [aws_security_group.wordpress_sg.id]

    tags = {
        Name = "cloud_midterm_wp_with_internet"
    }
}

resource "aws_eip_association" "wp_with_internet" {
    allocation_id = aws_eip.wp_eip.id
    network_interface_id = aws_network_interface.wp_with_internet.id
}

resource "aws_network_interface" "wp_to_mariadb" {
    subnet_id   = aws_subnet.private_wp.id
    security_groups = [aws_security_group.default.id]

    tags = {
        Name = "cloud_midterm_wp_to_mariadb"
    }
}

resource "aws_network_interface" "mariadb_get_wp" {
    subnet_id   = aws_subnet.private_wp.id
    security_groups = [aws_security_group.mariadb_sg.id]

    tags = {
        Name = "cloud_midterm_mariadb_get_wp"
    }
}

resource "aws_network_interface" "nat" {
    subnet_id   = aws_subnet.private_nat.id
    security_groups = [aws_security_group.default.id]

    tags = {
        Name = "cloud_midterm_nat"
    }
}

# EC2 instance for MariaDB
resource "aws_instance" "mariadb" {
    ami                    = var.ami
    instance_type          = "t2.micro"
    availability_zone      = var.availability_zone

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.nat.id
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install mariadb-server -y
                sudo systemctl start mariadb
                sudo systemctl enable mariadb
                mysql -e "CREATE DATABASE ${var.database_name};"
                mysql -e "CREATE USER '${var.database_user}'@'%' IDENTIFIED BY '${var.database_pass}';"
                mysql -e "GRANT ALL PRIVILEGES ON ${var.database_name}.* TO '${var.database_user}'@'%';"
                mysql -e "FLUSH PRIVILEGES;"
                sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
                sudo echo 'ssh-ed25519AAAAC3NzaC1lZDI1NTE5AAAAIODaHqtrCOBpfD+meWggDG5gFEqnNDtpxnqQ7xWIfXfL cloud-wordpress' >> /home/ubuntu/.ssh/authorized_keys
                sudo systemctl restart mariadb
                EOF
    tags = {
        Name = "cloud_midterm_mariadb"
    }
}

resource "aws_network_interface_attachment" "mariadb_get_wp" {
    device_index = 1
    instance_id = aws_instance.mariadb.id
    network_interface_id = aws_network_interface.mariadb_get_wp.id
}

# EC2 instance for WordPress
resource "aws_instance" "wordpress" {
    depends_on = [ aws_instance.mariadb, aws_network_interface_attachment.mariadb_get_wp, aws_iam_access_key.s3_iam, aws_s3_bucket.s3_bucket ]
    ami                    = var.ami
    instance_type          = "t2.micro"
    availability_zone      = var.availability_zone
    
    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.wp_with_internet.id
    }

    user_data =   <<-EOF
    #!/bin/bash
    sudo sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
    sudo apt-get update
    sudo apt-get install -y apache2 php8.1 php8.1-{curl,gd,mbstring,xml,xmlrpc,soap,intl,zip,mysql} libapache2-mod-php
    sudo systemctl enable php8.1-fpm
    sudo systemctl start php8.1-fpm
    sudo systemctl start apache2
    sudo systemctl enable apache2
    sudo systemctl restart apache2
    
    sudo sed -i '/<\/VirtualHost>/i\<Directory /var/www/html>\nAllowOverride All\n</Directory>' /etc/apache2/sites-enabled/000-default.conf
    sudo a2enmod rewrite
    sudo systemctl restart apache2

    cd /tmp
    wget https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    sudo cp -a /tmp/wordpress/. /var/www/html
    sudo chown -R www-data:www-data /var/www/html
    sudo find /var/www/html/ -type d -exec chmod 755 {} \;
    sudo find /var/www/html/ -type f -exec chmod 644 {} \;

    sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    sudo sed -i "s/database_name_here/${var.database_name}/" /var/www/html/wp-config.php
    sudo sed -i "s/username_here/${var.database_user}/" /var/www/html/wp-config.php
    sudo sed -i "s/password_here/${var.database_pass}/" /var/www/html/wp-config.php
    sudo sed -i "s/localhost/${aws_instance.mariadb.private_ip}/" /var/www/html/wp-config.php

    CUSTOM_VALUES_LINE=$(grep -n "Add any custom values between this line and the" /var/www/html/wp-config.php | cut -d : -f 1)
    if [ ! -z "$CUSTOM_VALUES_LINE" ]; then
        sudo sed -i "$((CUSTOM_VALUES_LINE-1))i define( 'AS3CF_SETTINGS', serialize( array(\\n        'provider' => 'aws',\\n        'access-key-id' => '${aws_iam_access_key.s3_iam.id}',\\n        'secret-access-key' => '${aws_iam_access_key.s3_iam.secret}',\\n        'bucket' => '${var.bucket_name}',\\n        'region' => '${var.region}',\\n        'copy-to-s3' => true,\\n        'serve-from-s3' => true,\\n    ) ) );" /var/www/html/wp-config.php
    fi

    sudo systemctl restart apache2

    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp

    curl localhost 
    sleep 60
    sudo wp core install --path=/var/www/html --url="${aws_eip.wp_eip.public_ip}" --admin_user="${var.admin_user}" --admin_password="${var.admin_pass}" --admin_email="exmaple@example.com" --title="Cloud" --skip-email --allow-root
    sudo wp plugin install amazon-s3-and-cloudfront --activate --path=/var/www/html --allow-root
    sudo echo 'ssh-ed25519AAAAC3NzaC1lZDI1NTE5AAAAIODaHqtrCOBpfD+meWggDG5gFEqnNDtpxnqQ7xWIfXfL cloud-wordpress' >> /home/ubuntu/.ssh/authorized_keys
    sudo systemctl restart apache2
                    EOF

    tags = {
        Name = "cloud_midterm_wp_ec2"
    }
}


resource "aws_network_interface_attachment" "wp_to_mariadb" {
    device_index = 1
    instance_id = aws_instance.wordpress.id
    network_interface_id = aws_network_interface.wp_to_mariadb.id
}

output "wordpress_public_ip" {
  value = aws_instance.wordpress.public_ip
}

output "mariadb_public_ip" {
  value = aws_instance.mariadb.public_ip
}
