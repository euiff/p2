#!/bin/bash

# Verifica se o domínio foi passado como argumento
if [ -z "$1" ]; then
  echo "Uso: $0 seu-dominio.com"
  exit 1
fi

DOMINIO=$1

echo "Atualizando o sistema..."
apt update && apt upgrade -y

echo "Instalando Apache, PHP e extensões..."
apt install -y apache2 php libapache2-mod-php php-mysql php-cli php-common php-zip php-gd php-mbstring php-curl php-xml php-bcmath unzip

echo "Instalando MariaDB..."
apt install -y mariadb-server
mysql_secure_installation

echo "Instalando phpMyAdmin..."
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password root" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password root" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password root" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections

apt install -y phpmyadmin

# Criar link simbólico para o phpMyAdmin
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

echo "Criando diretório do site $DOMINIO..."
mkdir -p /var/www/$DOMINIO

echo "<?php phpinfo(); ?>" > /var/www/$DOMINIO/index.php

# Permissões
chown -R www-data:www-data /var/www/$DOMINIO
chmod -R 755 /var/www/$DOMINIO

echo "Criando Virtual Host do Apache..."
cat <<EOF > /etc/apache2/sites-available/$DOMINIO.conf
<VirtualHost *:80>
    ServerAdmin webmaster@$DOMINIO
    ServerName $DOMINIO
    DocumentRoot /var/www/$DOMINIO

    <Directory /var/www/$DOMINIO>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$DOMINIO-error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMINIO-access.log combined
</VirtualHost>
EOF

a2ensite $DOMINIO.conf
a2dissite 000-default.conf
systemctl reload apache2

echo "Ativando firewall UFW e liberando Apache..."
ufw allow 'Apache Full'
ufw --force enable

echo "Reiniciando Apache..."
systemctl restart apache2

echo "Instalação concluída com sucesso!"
echo "Acesse http://$DOMINIO e http://$DOMINIO/phpmyadmin"
