#!/bin/bash

# Function to check for a valid Linux distribution
check_distribution() {
    if [ -f /etc/debian_version ]; then
        DISTRO="debian"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="redhat"
    else
        echo "Unsupported Linux distribution"
        exit 1
    fi
}

# Function to install common packages for DVWA
install_common_packages() {
    if [ "$DISTRO" == "debian" ]; then
        sudo apt update -y
        sudo apt install -y openssh-server apache2 php libapache2-mod-php php-mysql php-gd php-xml mariadb-server git
    elif [ "$DISTRO" == "redhat" ]; then
        sudo yum update -y
        sudo yum install -y openssh-server httpd php php-mysqlnd php-gd php-xml mariadb-server git
    fi
    sudo systemctl enable --now apache2 || sudo systemctl enable --now httpd
    sudo systemctl enable --now mariadb
}

# Function to configure Apache
configure_apache() {
    if [ "$DISTRO" == "debian" ]; then
        sudo sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/Options Indexes FollowSymLinks/Options Indexes FollowSymLinks/' /etc/apache2/apache2.conf
        sudo systemctl restart apache2
    elif [ "$DISTRO" == "redhat" ]; then
        sudo sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/Options Indexes FollowSymLinks/Options Indexes FollowSymLinks/' /etc/httpd/conf/httpd.conf
        sudo systemctl restart httpd
    fi
}

# Function to configure SSH for security testing (insecure)
configure_ssh() {
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    
    if [ "$DISTRO" == "debian" ]; then
        sudo systemctl restart ssh
    elif [ "$DISTRO" == "redhat" ]; then
        sudo systemctl restart sshd
    fi
}

# Function to install and configure DVWA
install_dvwa() {
    if [ ! -d "/var/www/html/dvwa" ]; then
        sudo git clone https://github.com/digininja/DVWA.git /var/www/html/dvwa
    else
        echo "DVWA already exists, skipping git clone..."
    fi
    sudo cp /var/www/html/dvwa/config/config.inc.php.dist /var/www/html/dvwa/config/config.inc.php
    sudo sed -i "s/'db_password' => 'p@ssw0rd'/'db_password' => ''/" /var/www/html/dvwa/config/config.inc.php
    sudo chown -R www-data:www-data /var/www/html/dvwa || sudo chown -R apache:apache /var/www/html/dvwa
}

# Function to create the DVWA database and user
create_database() {
    sudo systemctl start mariadb
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS dvwa;"
    sudo mysql -e "CREATE USER IF NOT EXISTS 'dvwa'@'localhost' IDENTIFIED BY '';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
}

# Function to configure MySQL
configure_mysql() {
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY ''; FLUSH PRIVILEGES;"
}

# Function to configure firewall instead of disabling completely
configure_firewall() {
    sudo ufw allow 80/tcp 2>/dev/null || sudo firewall-cmd --add-service=http --permanent
    sudo ufw allow 22/tcp 2>/dev/null || sudo firewall-cmd --add-service=ssh --permanent
    sudo ufw allow 3306/tcp 2>/dev/null || sudo firewall-cmd --add-port=3306/tcp --permanent
    sudo firewall-cmd --reload 2>/dev/null
}

# Function to restore system to secure state
restore_secure_state() {
    echo "Restoring system to secure state..."
    sudo apt purge -y apache2 php* mariadb-server git 2>/dev/null || sudo yum remove -y httpd php* mariadb-server git 2>/dev/null
    sudo rm -rf /var/www/html/dvwa
    sudo sed -i 's/PermitRootLogin yes/#PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl disable --now apache2 || sudo systemctl disable --now httpd
    sudo systemctl disable --now mariadb
    sudo systemctl start ufw 2>/dev/null || sudo systemctl start firewalld 2>/dev/null
    echo "System restored to secure state."
}

# Main script logic
if [ "$1" == "--vuln" ]; then
    echo "Setting up vulnerable environment..."
    check_distribution
    install_common_packages
    configure_apache
    configure_ssh
    create_database
    install_dvwa
    configure_mysql
    configure_firewall
    echo "Linux machine is now intentionally vulnerable for Nessus scanning."
elif [ "$1" == "--fix" ]; then
    restore_secure_state
else
    echo "Usage: $0 --vuln (to make vulnerable) | --fix (to restore secure state)"
    exit 1
fi
