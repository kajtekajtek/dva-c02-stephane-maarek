#!/bin/bash
# Example of User Data script for EC2 instance

function write_to_index_html() {
    echo "$1" >> /var/www/html/index.html
}

yum update -y # yum is a package-management utility for computers running the Linux operating system using the RPM Package Manager
yum install -y httpd
systemctl start httpd
systemctl enable httpd
write_to_index_html "<h1>$(hostname -f)</h1>"
write_to_index_html "<p>Mieczów ci u nas dostatek, ale i te przyjmuję jako wróżbę zwycięstwa, którą mi sam Bóg przez wasze ręce zsyła. A pole bitwy On także wyznaczy. Do którego sprawiedliwości ninie się odwołuję, skargę na moją krzywdę i waszą nieprawość a pychę zanosząc, amen.</p>"