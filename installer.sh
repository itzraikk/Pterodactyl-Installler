

#!/bin/bash
#!/usr/bin/env bash

########################################################################
#                                                                      #
#            Pterodactyl Installer, Updater, Remover and More          #
#            Copyright 2023, ItzRaikk.Dev, <contacto@itzraikk.dev>     # 
#  https://github.com/itzraikk/Pterodactyl-Installer/blob/main/LICENSE #
#                                                                      #
#  This script is not associated with the official Pterodactyl Panel.  #
#  You may not remove this line                                        #
#                                                                      #
########################################################################

### VARIABLES ###

dist="$(. /etc/os-release && echo "$ID")"
version="$(. /etc/os-release && echo "$VERSION_ID")"
USERPASSWORD=""
WINGSNOQUESTIONS=false

### OUTPUTS ###

function trap_ctrlc ()
{
    echo ""
    echo "Adios!"
    exit 2
}
trap "trap_ctrlc" 2

warning(){
    echo -e '\e[31m'"$1"'\e[0m';

}

### CHECKS ###

if [[ $EUID -ne 0 ]]; then
    echo ""
    echo "[!] Lo Siento, pero necesitas ser root para ejecutar este script."
    echo "La mayoría de las veces esto se puede hacer escribiendo sudo su en su terminal"
    exit 1
fi

if ! [ -x "$(command -v curl)" ]; then
    echo ""
    echo "[!] Se requiere cURL para ejecutar este script."
    echo "Para continuar, instale cURL en su máquina."
    echo ""
    echo "Sistemas basados ​​en Debian: apt install curl"
    echo "CentOS: yum install curl"
    exit 1
fi

### Pterodactyl Panel Installation ###

send_summary() {
    clear
    echo ""
    
    if [ -d "/var/www/pterodactyl" ]; then
        warning "[!] ADVERTENCIA: Pterodactyl ya está instalado. ¡Este script fallará!"
    fi

    echo ""
    echo "[!] Summary:"
    echo "    Panel URL: $FQDN"
    echo "    Webserver: $WEBSERVER"
    echo "    Email: $EMAIL"
    echo "    SSL: $SSLSTATUS"
    echo "    Username: $USERNAME"
    echo "    First name: $FIRSTNAME"
    echo "    Last name: $LASTNAME"
    if [ -n "$USERPASSWORD" ]; then
    echo "    Password: $(printf "%0.s*" $(seq 1 ${#USERPASSWORD}))"
    else
        echo "    Password:"
    fi
    echo ""
    
    if [ "$dist" = "centos" ] && [ "$version" = "7" ]; then
        echo "    Está ejecutando CentOS 7. Se seleccionará NGINX como servidor web."
    fi
    
    echo ""
}

panel(){
    echo ""
    echo "[!] Antes de la instalación, necesitamos cierta información."
    echo ""
    panel_webserver
}

finish(){
    clear
    cd
    echo -e "Resumen de la instalación\n\nURL del panel: $FQDN\nServidor web: $WEBSERVER\nNombre de usuario: $USERNAME\nEmail: $EMAIL\nNombre: $FIRSTNAME\nApellido: $LASTNAME\nContraseña: $(printf "%0.s *" $(seq 1 ${#USERPASSWORD}))\nContraseña de la base de datos: $DBPASSWORD\nContraseña del host de la base de datos: $DBPASSWORDHOST">> panel_credentials.txt

    echo "[!] Instalación del Panel Pterodactyl realizada"
    echo ""
    echo "    Resumen de la instalación" 
    echo "    Panel URL: $FQDN"
    echo "    Webserver: $WEBSERVER"
    echo "    Email: $EMAIL"
    echo "    SSL: $SSLSTATUS"
    echo "    Username: $USERNAME"
    echo "    First name: $FIRSTNAME"
    echo "    Last name: $LASTNAME"
    echo "    Password: $(printf "%0.s*" $(seq 1 ${#USERPASSWORD}))"
    echo "" 
    echo "    Database password: $DBPASSWORD"
    echo "    Password for Database Host: $DBPASSWORDHOST"
    echo "" 
    echo "    Estas credenciales se han guardado en un archivo llamado" 
    echo "    panel_credentials.txt en su directorio actual"
    echo ""

    if [ "$INSTALLBOTH" = "true" ]; then
        WINGSNOQUESTIONS=true
        wings
    fi

    if [ "$INSTALLBOTH" = "false" ]; then
        WINGSNOQUESTIONS=false
        echo "    ¿Te gustaría instalar Wings también? (S/N)"
        read -r -p "¿Quieres instalar Wings? [S/n]: " WINGS_ON_PANEL

        if [[ "$WINGS_ON_PANEL" =~ [Ss] ]]; then
            wings
        fi
        
        if [[ "$WINGS_ON_PANEL" =~ [Nn] ]]; then
            echo "Adios!"
            exit 0
        fi
    fi
}

panel_webserver(){
    send_summary
    echo "[!] Seleccione servidor web"
    echo "    (1) NGINX"
    echo "    (2) Apache"
    echo "    Input 1-2"
    read -r option
    case $option in
        1 ) option=1
            WEBSERVER="NGINX"
            panel_fqdn
            ;;
        2 ) option=2
            WEBSERVER="Apache"
            panel_fqdn
            ;;
        * ) echo ""
            echo "Por favor ingresa una opción válida del 1-2"
    esac
}

panel_conf(){
    [ "$SSLSTATUS" == true ] && appurl="https://$FQDN"
    [ "$SSLSTATUS" == false ] && appurl="http://$FQDN"
    mariadb -u root -e "CREATE USER 'pterodactyluser'@'127.0.0.1' IDENTIFIED BY '$DBPASSWORDHOST';" && mariadb -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'pterodactyluser'@'127.0.0.1' WITH GRANT OPTION;"
    mariadb -u root -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DBPASSWORD';" && mariadb -u root -e "CREATE DATABASE panel;" && mariadb -u root -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;" && mariadb -u root -e "FLUSH PRIVILEGES;"
    php artisan p:environment:setup --author="$EMAIL" --url="$appurl" --timezone="CET" --telemetry=false --cache="redis" --session="redis" --queue="redis" --redis-host="localhost" --redis-pass="null" --redis-port="6379" --settings-ui=true
    php artisan p:environment:database --host="127.0.0.1" --port="3306" --database="panel" --username="pterodactyl" --password="$DBPASSWORD"
    php artisan migrate --seed --force
    php artisan p:user:make --email="$EMAIL" --username="$USERNAME" --name-first="$FIRSTNAME" --name-last="$LASTNAME" --password="$USERPASSWORD" --admin=1
    chown -R www-data:www-data /var/www/pterodactyl/*
    if [ "$dist" = "centos" ]; then
        chown -R nginx:nginx /var/www/pterodactyl/*
         systemctl enable --now redis
        fi
    curl -o /etc/systemd/system/pteroq.service https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pteroq.service
    (crontab -l ; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1")| crontab -
     systemctl enable --now redis-server
     systemctl enable --now pteroq.service

    if [ "$dist" = "centos" ] && { [ "$version" = "7" ] || [ "$SSLSTATUS" = "true" ]; }; then
         yum install epel-release -y
         yum install certbot -y
        curl -o /etc/nginx/conf.d/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx-ssl.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/conf.d/pterodactyl.conf
        sed -i -e "s@/run/php/php8.1-fpm.sock@/var/run/php-fpm/pterodactyl.sock@g" /etc/nginx/conf.d/pterodactyl.conf
        systemctl stop nginx
        certbot certonly --standalone -d $FQDN --staple-ocsp --no-eff-email -m $EMAIL --agree-tos
        systemctl start nginx
        finish
        fi
    if [ "$dist" = "centos" ] && { [ "$version" = "7" ] || [ "$SSLSTATUS" = "false" ]; }; then
        curl -o /etc/nginx/conf.d/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/conf.d/pterodactyl.conf
        sed -i -e "s@/run/php/php8.1-fpm.sock@/var/run/php-fpm/pterodactyl.sock@g" /etc/nginx/conf.d/pterodactyl.conf
        systemctl restart nginx
        finish
        fi
    if [ "$SSLSTATUS" = "true" ] && [ "$WEBSERVER" = "NGINX" ]; then
        rm -rf /etc/nginx/sites-enabled/default
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx-ssl.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/sites-enabled/pterodactyl.conf

        systemctl stop nginx
        certbot certonly --standalone -d $FQDN --staple-ocsp --no-eff-email -m $EMAIL --agree-tos
        systemctl start nginx
        finish
        fi
    if [ "$SSLSTATUS" = "true" ] && [ "$WEBSERVER" = "Apache" ]; then
        a2dissite 000-default.conf && systemctl reload apache2
        curl -o /etc/apache2/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-apache-ssl.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/apache2/sites-enabled/pterodactyl.conf
        apt install libapache2-mod-php
         a2enmod rewrite
         a2enmod ssl
        systemctl stop apache2
        certbot certonly --standalone -d $FQDN --staple-ocsp --no-eff-email -m $EMAIL --agree-tos
        systemctl start apache2
        finish
        fi
    if [ "$SSLSTATUS" = "false" ] && [ "$WEBSERVER" = "NGINX" ]; then
        rm -rf /etc/nginx/sites-enabled/default
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl restart nginx
        finish
        fi
    if [ "$SSLSTATUS" = "false" ] && [ "$WEBSERVER" = "Apache" ]; then
        a2dissite 000-default.conf && systemctl reload apache2
        curl -o /etc/apache2/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-apache.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/apache2/sites-enabled/pterodactyl.conf
         a2enmod rewrite
        systemctl stop apache2
        systemctl start apache2
        finish
        fi
}

panel_install(){
    echo "" 
    if  [ "$dist" =  "ubuntu" ] && [ "$version" = "20.04" ]; then
        apt update
        apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
        curl -fsSL https://packages.redis.io/gpg |  gpg --dearmor --batch --yes -o /usr/share/keyrings/redis-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" |  tee /etc/apt/sources.list.d/redis.list
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup |  bash
        apt update
         add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
    fi
    if [ "$dist" = "debian" ] && [ "$version" = "11" ]; then
        apt update
        apt -y install software-properties-common curl ca-certificates gnupg2  lsb-release
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" |  tee /etc/apt/sources.list.d/sury-php.list
        curl -fsSL  https://packages.sury.org/php/apt.gpg |  gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg
        curl -fsSL https://packages.redis.io/gpg |  gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" |  tee /etc/apt/sources.list.d/redis.list
        apt update -y
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup |  bash
    fi
    if [ "$dist" = "debian" ] && [ "$version" = "12" ]; then
        apt update
        apt -y install software-properties-common curl ca-certificates gnupg2  lsb-release
         apt install -y apt-transport-https lsb-release ca-certificates wget
        wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" |  tee /etc/apt/sources.list.d/php.list
        curl -fsSL https://packages.redis.io/gpg |  gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" |  tee /etc/apt/sources.list.d/redis.list
        apt update -y
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup |  bash
    fi
    if [ "$dist" = "centos" ] && [ "$version" = "7" ]; then
        yum update -y
        yum install -y policycoreutils policycoreutils-python selinux-policy selinux-policy-targeted libselinux-utils setroubleshoot-server setools setools-console mcstrans -y

        curl -o /etc/yum.repos.d/mariadb.repo https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/mariadb.repo

        yum update -y
        yum install -y mariadb-server
        sed -i 's/character-set-collations = utf8mb4=uca1400_ai_ci/character-set-collations = utf8mb4=utf8mb4_general_ci/' /etc/mysql/mariadb.conf.d/50-server.cnf
        systemctl start mariadb
        systemctl enable mariadb
        systemctl restart mariadb

        yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
        yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm
        yum install -y yum-utils
        yum-config-manager --disable 'remi-php*'
        yum-config-manager --enable remi-php81

        yum update -y
        yum install -y php php-{common,fpm,cli,json,mysqlnd,mcrypt,gd,mbstring,pdo,zip,bcmath,dom,opcache}

        yum install -y zip unzip
        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
        yum install -y nginx

        yum install -y --enablerepo=remi redis
        systemctl start redis
        systemctl enable redis

        setsebool -P httpd_can_network_connect 1
        setsebool -P httpd_execmem 1
        setsebool -P httpd_unified 1

        curl -o /etc/php-fpm.d/www-pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/www-pterodactyl.conf
        systemctl enable php-fpm
        systemctl start php-fpm

        pause 0.5s
        mkdir /var
        mkdir /var/www
        mkdir /var/www/pterodactyl
        cd /var/www/pterodactyl
        curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
        tar -xzvf panel.tar.gz
        chmod -R 755 storage/* bootstrap/cache/
        cp .env.example .env
        command composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs
        php artisan key:generate --force

        WEBSERVER=NGINX
        panel_conf
        fi

    apt update
    apt install certbot -y

    apt install -y mariadb-server tar unzip git redis-server
    sed -i 's/character-set-collations = utf8mb4=uca1400_ai_ci/character-set-collations = utf8mb4=utf8mb4_general_ci/' /etc/mysql/mariadb.conf.d/50-server.cnf
    systemctl restart mariadb
    apt -y install php8.1 php8.1-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip}
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    pause 0.5s
    mkdir /var
    mkdir /var/www
    mkdir /var/www/pterodactyl
    cd /var/www/pterodactyl
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    cp .env.example .env
    command composer install --no-dev --optimize-autoloader --no-interaction
    php artisan key:generate --force
    if  [ "$WEBSERVER" =  "NGINX" ]; then
        apt install nginx -y
        panel_conf
    fi
    if  [ "$WEBSERVER" =  "Apache" ]; then
        apt install apache2 libapache2-mod-php8.1 -y
        panel_conf
    fi
}

panel_summary(){
    clear
    DBPASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    DBPASSWORDHOST=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    echo ""
    echo "[!] Summary:"
    echo "    Panel URL: $FQDN"
    echo "    Webserver: $WEBSERVER"
    echo "    SSL: $SSLSTATUS"
    echo "    Username: $USERNAME"
    echo "    First name: $FIRSTNAME"
    echo "    Last name: $LASTNAME"
    echo "    Password: $(printf "%0.s*" $(seq 1 ${#USERPASSWORD}))"
    echo ""
    echo "    Las Credenciales seran guardadas en el archivo" 
    echo "    panel_credentials.txt en tu directorio Actual"
    echo "" 
    echo "    Iniciar Instalación? (S/N)" 
    read -r PANEL_INSTALLATION

    if [[ "$PANEL_INSTALLATION" =~ [Ss] ]]; then
        panel_install
    fi
    if [[ "$PANEL_INSTALLATION" =~ [Nn] ]]; then
        echo "[!] Instalación Aboratda."
        exit 1
    fi
}

panel_fqdn(){
    send_summary
    echo "[!] Por favor ingrese FQDN. Accederás al Panel con esto."
    echo "[!] Ejemplo: panel.yourdomain.dk."
    read -r FQDN
    [ -z "$FQDN" ] && echo "FQDN no puede estar vacío."
    IP=$(dig +short myip.opendns.com @resolver2.opendns.com -4)
    DOMAIN=$(dig +short ${FQDN})
    if [ "${IP}" != "${DOMAIN}" ]; then
        echo ""
        echo "Su FQDN no se resuelve con la IP de esta máquina."
        echo "Continuando de todos modos en 10 segundos. CTRL+C para detener."
        sleep 10s
        panel_ssl
    else
        panel_ssl
    fi
}

panel_ssl(){
    send_summary
    echo "[!] ¿Quieres utilizar SSL para tu Panel? Esto es recomendable. (S/N)"
    echo "[!] Se recomienda SSL para cada panel."
    read -r SSL_CONFIRM

    if [[ "$SSL_CONFIRM" =~ [Ss] ]]; then
        SSLSTATUS=true
        panel_email
    fi
    if [[ "$SSL_CONFIRM" =~ [Nn] ]]; then
        SSLSTATUS=false
        panel_email
    fi
}

panel_email(){
    send_summary
    if  [ "$SSLSTATUS" =  "true" ]; then
        echo "[!] Por favor ingrese su correo electrónico. Se compartirá con Lets Encrypt y se utilizará para configurar este Panel."
        fi
    if  [ "$SSLSTATUS" =  "false" ]; then
        echo "[!] Por favor ingrese su correo electrónico. Se utilizará para configurar este Panel."
        fi
    read -r EMAIL
    panel_username
}

panel_username(){
    send_summary
    echo "[!] Por favor ingrese el nombre de usuario para la cuenta de administrador. Puede utilizar su nombre de usuario para iniciar sesión en su cuenta Pterodactyl."
    read -r USERNAME
    panel_firstname
}
panel_firstname(){
    send_summary
    echo "[!] Nombre"
    read -r FIRSTNAME
    panel_lastname
}

panel_lastname(){
    send_summary
    echo "[!] Apellido."
    read -r LASTNAME
    panel_password
}

panel_password(){
    send_summary
    echo "[!] Contraseña."
    local USERPASSWORD=""
    while IFS= read -r -s -n 1 char; do
        if [[ $char == $'\0' ]]; then
            break
        elif [[ $char == $'\177' ]]; then
            if [ -n "$USERPASSWORD" ]; then
                USERPASSWORD="${USERPASSWORD%?}"
                echo -en "\b \b"
            fi
        else
            echo -n '*'
            USERPASSWORD+="$char"
        fi
    done
    echo
    panel_summary
}




### Pterodactyl Wings Installation ###

wings(){
    if [ "$dist" = "debian" ] || [ "$dist" = "ubuntu" ]; then
         apt install dnsutils certbot curl tar unzip -y
    elif [ "$dist" = "centos" ]; then
         yum install bind-utils certbot policycoreutils policycoreutils-python selinux-policy selinux-policy-targeted libselinux-utils setroubleshoot-server setools setools-console mcstrans tar unzip zip -y
    fi
    
    if [ "$WINGSNOQUESTIONS" = "true" ]; then
        WINGS_FQDN_STATUS=false
        wings_full
    elif [ "$WINGSNOQUESTIONS" = "false" ]; then
        clear
        echo ""
        echo "[!] Antes de la Instalación, Necesitamos Algo de Información."
        echo ""
        wings_fqdn
    fi
}


wings_fqdnask(){
    echo "[!] Instalar Certificado SSl? (S/N)"
    echo "    Si si, Te preguntaremos por un EMAIL."
    echo "    El EMAIL Sera compartido con Lets Encrypt."
    read -r WINGS_SSL

    if [[ "$WINGS_SSL" =~ [Ss] ]]; then
        panel_fqdn
    fi
    if [[ "$WINGS_SSL" =~ [Nn] ]]; then
        WINGS_FQDN_STATUS=false
        wings_full
    fi
}

wings_full(){
    if [ "$dist" = "debian" ] || [ "$dist" = "ubuntu" ]; then
        apt-get update && apt-get -y install curl tar unzip

        if ! command -v docker &> /dev/null; then
            curl -sSL https://get.docker.com/ | CHANNEL=stable bash
             systemctl enable --now docker
        else
            echo "[!] Docker Ya esta Instalado."
        fi

        if ! mkdir -p /etc/pterodactyl; then
            echo "[!] Ocurrio un Error. No se pudo crear el Directorio." >&2
            exit 1
        fi

        if  [ "$WINGS_FQDN_STATUS" =  "true" ]; then
            systemctl stop nginx apache2
            apt install -y certbot && certbot certonly --standalone -d $WINGS_FQDN --staple-ocsp --no-eff-email --agree-tos
            fi

        curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
        curl -o /etc/systemd/system/wings.service https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/wings.service
        chmod u+x /usr/local/bin/wings
        clear
        echo ""
        echo "[!] Pterodactyl Wings Instaladas Exitosamente."
        echo "    Aun necesitas Poner El Nodo"
        echo "    en el Panel y reiniciar las Wings."
        echo ""

        if [ "$INSTALLBOTH" = "true" ]; then
            INSTALLBOTH="0"
            finish
            fi
    else
        echo "[!] Tu OS No puede instalar Wings con este Instalador"
    fi
}

wings_fqdn(){
    echo "[!] Inggresa tu FQDN Para instalar el Certificado SSL."
    read -r WINGS_FQDN
    IP=$(dig +short myip.opendns.com @resolver2.opendns.com -4)
    DOMAIN=$(dig +short ${WINGS_FQDN})
    if [ "${IP}" != "${DOMAIN}" ]; then
        echo ""
        echo "FQDN cancelado. O FQDN Es Incorrecto o lo dejaste en blanco."
        WINGS_FQDN_STATUS=false
        wings_full
    else
        WINGS_FQDN_STATUS=true
        wings_full
    fi
}

### PHPMyAdmin Installation ###

phpmyadmin(){
    apt install dnsutils -y
    echo ""
    echo "[!] Antes de la INstalación, Necesitamos algo de Información."
    echo ""
    phpmyadmin_fqdn
}

phpmyadmin_finish(){
    cd
    echo -e "PHPMyAdmin Instalación\n\nResultado de la Instalación\n\nPHPMyAdmin URL: $PHPMYADMIN_FQDN\nPreselected webserver: NGINX\nSSL: $PHPMYADMIN_SSLSTATUS\nUser: $PHPMYADMIN_USER_LOCAL\nPassword: $PHPMYADMIN_PASSWORD\nEmail: $PHPMYADMIN_EMAIL" > phpmyadmin_credentials.txt
    clear
    echo "[!] Instalación de PHPMyAdmin Finalizada"
    echo ""
    echo "    Summary of the installation" 
    echo "    PHPMyAdmin URL: $PHPMYADMIN_FQDN"
    echo "    Preselected webserver: NGINX"
    echo "    SSL: $PHPMYADMIN_SSLSTATUS"
    echo "    User: $PHPMYADMIN_USER_LOCAL"
    echo "    Password: $PHPMYADMIN_PASSWORD"
    echo "    Email: $PHPMYADMIN_EMAIL"
    echo ""
    echo "    Estas credenciales fueron guardadas en el archivo" 
    echo "    phpmyadmin_credentials.txt En tu directorio actual"
    echo ""
}


phpmyadminweb(){
    rm -rf /etc/nginx/sites-enabled/default || exit || echo "An error occurred. NGINX is not installed." || exit
    apt install mariadb-server -y
    PHPMYADMIN_PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    mariadb -u root -e "CREATE USER '$PHPMYADMIN_USER_LOCAL'@'localhost' IDENTIFIED BY '$PHPMYADMIN_PASSWORD';" && mariadb -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$PHPMYADMIN_USER_LOCAL'@'localhost' WITH GRANT OPTION;"
    
    if  [ "$PHPMYADMIN_SSLSTATUS" =  "true" ]; then
        rm -rf /etc/nginx/sites-enabled/default
        curl -o /etc/nginx/sites-enabled/phpmyadmin.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/phpmyadmin-ssl.conf
        sed -i -e "s@<domain>@${PHPMYADMIN_FQDN}@g" /etc/nginx/sites-enabled/phpmyadmin.conf
        systemctl stop nginx || exit || echo "An error occurred. NGINX is not installed." || exit
        certbot certonly --standalone -d $PHPMYADMIN_FQDN --staple-ocsp --no-eff-email -m $PHPMYADMIN_EMAIL --agree-tos || exit || echo "An error occurred. Certbot not installed." || exit
        systemctl start nginx || exit || echo "An error occurred. NGINX is not installed." || exit
        phpmyadmin_finish
        fi
    if  [ "$PHPMYADMIN_SSLSTATUS" =  "false" ]; then
        curl -o /etc/nginx/sites-enabled/phpmyadmin.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/phpmyadmin.conf || exit || echo "An error occurred. cURL is not installed." || exit
        sed -i -e "s@<domain>@${PHPMYADMIN_FQDN}@g" /etc/nginx/sites-enabled/phpmyadmin.conf || exit || echo "An error occurred. NGINX is not installed." || exit
        systemctl restart nginx || exit || echo "An error occurred. NGINX is not installed." || exit
        phpmyadmin_finish
        fi
}

phpmyadmin_fqdn(){
    send_phpmyadmin_summary
    echo "[!] Por favor ingresa FQDN. Accederas a PhPMyAdmin con este."
    read -r PHPMYADMIN_FQDN
    [ -z "$PHPMYADMIN_FQDN" ] && echo "FQDN No puede estar Vacio."
    IP=$(dig +short myip.opendns.com @resolver2.opendns.com -4)
    DOMAIN=$(dig +short ${PHPMYADMIN_FQDN})
    if [ "${IP}" != "${DOMAIN}" ]; then
        echo ""
        echo "Tu FQDN No ressuelve a la IP De la Maquina."
        echo "Continuenado en 10 seconds.. CTRL+C Para parar."
        sleep 10s
        phpmyadmin_ssl
    else
        phpmyadmin_ssl
    fi
}

phpmyadmininstall(){
    apt update
    apt install nginx certbot -y
    mkdir /var/www/phpmyadmin && cd /var/www/phpmyadmin || exit || echo "An error occurred. Could not create directory." || exit
    cd /var/www/phpmyadmin
    if  [ "$dist" =  "ubuntu" ] && [ "$version" = "20.04" ]; then
        apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup |  bash
        apt update
         add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
    fi
    if [ "$dist" = "debian" ] && [ "$version" = "11" ]; then
        apt -y install software-properties-common curl ca-certificates gnupg2  lsb-release
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" |  tee /etc/apt/sources.list.d/sury-php.list
        curl -fsSL  https://packages.sury.org/php/apt.gpg |  gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg
        apt update -y
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup |  bash
    fi
    if [ "$dist" = "debian" ] && [ "$version" = "12" ]; then
        apt -y install software-properties-common curl ca-certificates gnupg2  lsb-release
         apt install -y apt-transport-https lsb-release ca-certificates wget
        wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" |  tee /etc/apt/sources.list.d/php.list
        apt update -y
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup |  bash
    fi
    
    wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz
    tar xzf phpMyAdmin-5.2.1-all-languages.tar.gz
    mv /var/www/phpmyadmin/phpMyAdmin-5.2.1-all-languages/* /var/www/phpmyadmin
    chown -R www-data:www-data *
    mkdir config
    chmod o+rw config
    cp config.sample.inc.php config/config.inc.php
    chmod o+w config/config.inc.php
    rm -rf /var/www/phpmyadmin/config
    phpmyadminweb
}


phpmyadmin_summary(){
    clear
    echo ""
    echo "[!] Summary:"
    echo "    PHPMyAdmin URL: $PHPMYADMIN_FQDN"
    echo "    Preselected webserver: NGINX"
    echo "    SSL: $PHPMYADMIN_SSLSTATUS"
    echo "    User: $PHPMYADMIN_USER_LOCAL"
    echo "    Email: $PHPMYADMIN_EMAIL"
    echo ""
    echo "    Estas credenciales fueron guardadas en el archivo" 
    echo "    phpmyadmin_credentials.txt en tu directorio actual"
    echo "" 
    echo "    Comenzar Innstalación? (S/N)" 
    read -r PHPMYADMIN_INSTALLATION

    if [[ "$PHPMYADMIN_INSTALLATION" =~ [Ss] ]]; then
        phpmyadmininstall
    fi
    if [[ "$PHPMYADMIN_INSTALLATION" =~ [Nn] ]]; then
        echo "[!] Instalación Aboratada."
        exit 1
    fi
}

send_phpmyadmin_summary(){
    clear
    echo ""
    if [ -d "/var/www/phpymyadmin" ]; then
        warning "[!] ADVERTENCIA: PArece que ya instalaste PhPMyAdmin! El Script Fallara!"
    fi
    echo ""
    echo "[!] Resultado:"
    echo "    PHPMyAdmin URL: $PHPMYADMIN_FQDN"
    echo "    Preselected webserver: NGINX"
    echo "    SSL: $PHPMYADMIN_SSLSTATUS"
    echo "    User: $PHPMYADMIN_USER_LOCAL"
    echo "    Email: $PHPMYADMIN_EMAIL"
    echo ""
}

phpmyadmin_ssl(){
    send_phpmyadmin_summary
    echo "[!] Quieres usar SSL para PHPMyAdmin? Es recomendado. (S/N)"
    read -r SSL_CONFIRM

    if [[ "$SSL_CONFIRM" =~ [Ss] ]]; then
        PHPMYADMIN_SSLSTATUS=true
        phpmyadmin_email
    fi
    if [[ "$SSL_CONFIRM" =~ [Nn] ]]; then
        PHPMYADMIN_SSLSTATUS=false
        phpmyadmin_email
    fi
}

phpmyadmin_user(){
    send_phpmyadmin_summary
    echo "[!] Ingresa noombre de Usuario para cuenta de Admin."
    read -r PHPMYADMIN_USER_LOCAL
    phpmyadmin_summary
}

phpmyadmin_email(){
    send_phpmyadmin_summary
    if  [ "$PHPMYADMIN_SSLSTATUS" =  "true" ]; then
        echo "[!] Por favor ingresa tu EMAIL. Sera compratido con Lets Encrypt."
        read -r PHPMYADMIN_EMAIL
        phpmyadmin_user
        fi
    if  [ "$PHPMYADMIN_SSLSTATUS" =  "false" ]; then
        phpmyadmin_user
        PHPMYADMIN_EMAIL="Unavailable"
        fi
}

### Removal of Wings ###

wings_remove(){
    echo ""
    echo "[!] Seguro que quieres remover las Wings? Si tienes algun servidor en esta maquina tambien sera Removido. (Y/N)"
    read -r UNINSTALLWINGS

    if [[ "$UNINSTALLWINGS" =~ [Yy] ]]; then
         systemctl stop wings # Stops wings
         rm -rf /var/lib/pterodactyl # Removes game servers and backup files
         rm -rf /etc/pterodactyl  || exit || warning "Pterodactyl Wings not installed!"
         rm /usr/local/bin/wings || exit || warning "Wings is not installed!" # Removes wings
         rm /etc/systemd/system/wings.service # Removes wings service file
        echo ""
        echo "[!] Pterodactyl Wings Fueron Desinstaladas."
        echo ""
    fi
}

## PHPMyAdmin Removal ###

removephpmyadmin(){
    echo ""
    echo "[!] Seguro que Quieres remover PHPMyAdmin? /var/www/phpmyadmin Sera Borrado y no se puede recuperar. (S/N)"
    read -r UNINSTALLPHPMYADMIN

    if [[ "$UNINSTALLPHPMYADMIN" =~ [Ss] ]]; then
         rm -rf /var/www/phpmyadmin || exit || warning "PHPMyAdmin No esta Instalado!" # Removes PHPMyAdmin files
         echo "[!] PHPMyAdmin Fue removido."
    fi
    if [[ "$UNINSTALLPHPMYADMIN" =~ [Nn] ]]; then
        echo "[!] CAncelado."
    fi
}

### Removal of Panel ###

uninstallpanel(){
    echo ""
    echo "[!] Seguro que qquieres Remover el Pterodactyl Panel? Todos los archivos seran removidos. (S/N)"
    read -r UNINSTALLPANEL

    if [[ "$UNINSTALLPANEL" =~ [Ss] ]]; then
        uninstallpanel_backup
    fi
    if [[ "$UNINSTALLPANEL" =~ [Nn] ]]; then
        echo "[!] Removal aborted."
    fi
}

uninstallpanel_backup(){
    echo ""
    echo "[!] quieres mantener tu database y backup tu archivo .env? (S/N)"
    read -r UNINSTALLPANEL_CHANGE

    if [[ "$UNINSTALLPANEL_CHANGE" =~ [Ss] ]]; then
        BACKUPPANEL=true
        uninstallpanel_confirm
    fi
    if [[ "$UNINSTALLPANEL_CHANGE" =~ [Nn] ]]; then
        BACKUPPANEL=false
        uninstallpanel_confirm
    fi
}

uninstallpanel_confirm(){
    if  [ "$BACKUPPANEL" =  "true" ]; then
        mv /var/www/pterodactyl/.env .
         rm -rf /var/www/pterodactyl || exit || warning "Panel is not installed!" # Removes panel files
         rm /etc/systemd/system/pteroq.service # Removes pteroq service worker
         unlink /etc/nginx/sites-enabled/pterodactyl.conf # Removes nginx config (if using nginx)
         unlink /etc/apache2/sites-enabled/pterodactyl.conf # Removes Apache config (if using apache)
         rm -rf /var/www/pterodactyl # Removing panel files
        systemctl restart nginx
        clear
        echo ""
        echo "[!] Pterodactyl Panel Fue desinstalado."
        echo "    Tu database del panel no fue eliminada"
        echo "    y tu archivo .env esta en tu directorio actual"
        echo ""
        fi
    if  [ "$BACKUPPANEL" =  "false" ]; then
         rm -rf /var/www/pterodactyl || exit || warning "Panel no esta Instalado!" # Removes panel files
         rm /etc/systemd/system/pteroq.service # Removes pteroq service worker
         unlink /etc/nginx/sites-enabled/pterodactyl.conf # Removes nginx config (if using nginx)
         unlink /etc/apache2/sites-enabled/pterodactyl.conf # Removes Apache config (if using apache)
         rm -rf /var/www/pterodactyl # Removing panel files
        mariadb -u root -e "DROP DATABASE panel;" # Remove panel database
        mysql -u root -e "DROP DATABASE panel;" # Remove panel database
        systemctl restart nginx
        clear
        echo ""
        echo "[!] Pterodactyl Panel Fue desinstalado."
        echo "    Archivos, Servicios, Configuraciones y todo fue borrado."
        echo ""
        fi
}

### Switching Domains ###

switch(){
    if  [ "$SSLSWITCH" =  "true" ]; then
        echo ""
        echo "[!] Cambiar Dominios"
        echo ""
        echo "    El script esta cambiando tu Dominio Pterodactyl."
        echo "      Esto puede tomar unos segundos por los Certificados SSL, SSL Certificados estan Siendo Generados"
        rm /etc/nginx/sites-enabled/pterodactyl.conf
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx-ssl.conf || exit || warning "Pterodactyl Panel not installed!"
        sed -i -e "s@<domain>@${DOMAINSWITCH}@g" /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl stop nginx
        certbot certonly --standalone -d $DOMAINSWITCH --staple-ocsp --no-eff-email -m $EMAILSWITCHDOMAINS --agree-tos || exit || warning "Errors accured."
        systemctl start nginx
        echo ""
        echo "[!] Change domains"
        echo ""
        echo "    Dominio Cmbiado a $DOMAINSWITCH"
        echo "    Este Script no Actualiza la URL de tu APP, Puedes"
        echo "    actualizarla en /var/www/pterodactyl/.env"
        echo ""
        echo "    Si utiliza certificados de Cloudflare para su Panel, lea esto:"
        echo "    El script utiliza Lets Encrypt para completar el cambio de su dominio."
        echo "    si normalmente utiliza certificados de Cloudflare",
        echo "    puedes cambiarlo manualmente en su configuración que está en el mismo lugar que antes".
        echo ""
        fi
    if  [ "$SSLSWITCH" =  "false" ]; then
        echo "[!] Cambiando tu dominio... Esto no tomará mucho tiempo!"
        rm /etc/nginx/sites-enabled/pterodactyl.conf || exit || echo "Se produjo un error. No se pudo eliminar el archivo." || exit
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx.conf || exit || warning "Pterodactyl Panel not installed!"
        sed -i -e "s@<domain>@${DOMAINSWITCH}@g" /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl restart nginx
        echo ""
        echo "[!] Cambiar Dominios"
        echo ""
        echo "    Su dominio ha sido cambiado a $DOMAINSWITCH"
        echo "    Este script no actualiza la URL de tu aplicación, tú puedes hacerlo"
        echo "    actualízalo en /var/www/pterodactyl/.env"
        fi
}

switchemail(){
    echo ""
    echo "[!] Cambiar dominios"
    echo "    Para instalar su nuevo certificado de dominio en su Panel, su dirección de correo electrónico debe compartirse con Let's Encrypt."
    echo "    Le enviarán un correo electrónico cuando su certificado esté a punto de caducar. Un certificado dura 90 días a la vez y puede renovar sus certificados de forma gratuita y sencilla, incluso con este script".
    eco ""
    echo "    Cuando creaste tu certificado para tu panel antes, también te pidieron tu dirección de correo electrónico. Es exactamente lo mismo aquí, con tu nuevo dominio."
    echo "    Por lo tanto, ingrese su correo electrónico. Si no tiene ganas de dar su correo electrónico, entonces el script no puede continuar. Presione CTRL + C para salir."
    eco ""
    echo "    Por favor ingresa tu correo electrónico"

    read -r EMAILSWITCHDOMAINS
    switch
}

switchssl(){
    echo "[!] Seleccione el que mejor describa su situación"
    warning "    [1] Quiero SSL en mi Panel en mi nuevo dominio"
    warning "    [2] No quiero SSL en mi Panel en mi nuevo dominio"
    read -r option
    case $option in
        1 ) option=1
            SSLSWITCH=true
            switchemail
            ;;
        2 ) option=2
            SSLSWITCH=false
            switch
            ;;
        * ) echo ""
            echo "Por faor Ingresa una Opcion Valida."
    esac
}

switchdomains(){
    echo ""
    echo "[!] Cambiar dominios"
    echo "    Ingrese el dominio (panel.midominio.ltd) al que desea cambiar."
    read -r DOMAINSWITCH
    switchssl
}

### OS Check ###

oscheck(){
    echo "Reisando tu OS.."
    if { [ "$dist" = "ubuntu" ] && [ "$version" = "18.04" ] || [ "$version" = "20.04" ] || [ "$version" = "22.04" ]; } || { [ "$dist" = "centos" ] && [ "$version" = "7" ]; } || { [ "$dist" = "debian" ] && [ "$version" = "11" ] || [ "$version" = "12" ]; }; then
        options
    else
        echo "Tu OS, $dist $version, No es Soportado"
        exit 1
    fi
}

### Options ###

options(){
    if [ "$dist" = "centos" ] && { [ "$version" = "7" ]; }; then
        echo "    Tus oportunidades han sido limitadas debido a CentOS 7."
        eco ""
        echo "    ¿Qué te gustaría hacer?"
        echo "    [1] Panel de instalación".
        echo "    [2] Instalar Wings".
        echo "    [3] Eliminar panel".
        echo "    [4] Quitar Wings".
        echo "Input 1-4"
        read -r option
        case $option in
            1 ) option=1
                INSTALLBOTH=false
                panel
                ;;
            2 ) option=2
                INSTALLBOTH=false
                wings
                ;;
            2 ) option=3
                uninstallpanel
                ;;
            2 ) option=4
                wings_remove
                ;;
            * ) echo ""
                echo "Por favor ingresa una Opcio valida de 1-4"
        esac
    else
        echo "¿Qué te gustaría hacer?"
        echo "[1] Panel de instalación"
        echo "[2] Instalar Wings"
        echo "[3] Panel y Wings"
        echo "[4] Instalar PHPMyAdmin"
        echo "[5] Eliminar PHPMyAdmin"
        echo "[6] Quitar Wings"
        echo "[7] Eliminar panel"
        echo "[8] Cambiar dominio de pterodactyl"
        echo "Input 1-8"
        read -r option
        case $option in
            1 ) option=1
                INSTALLBOTH=false
                panel
                ;;
            2 ) option=2
                INSTALLBOTH=false
                wings
                ;;
            3 ) option=3
                INSTALLBOTH=true
                panel
                ;;
            4 ) option=4
                phpmyadmin
                ;;
            5 ) option=5
                removephpmyadmin
                ;;
            6 ) option=6
                wings_remove
                ;;
            7 ) option=7
                uninstallpanel
                ;;
            8 ) option=8
                switchdomains
                ;;
            * ) echo ""
                echo "Por favor ingresa una opción válida del 1 al 8"
        esac
    fi
}

### Start ###

clear
echo ""
echo "Pterodactyl Installer @ v2.1"
echo "Copyright 2024, ItzRaikk, <contacto@itzraikk.de>"
echo "https://github.com/itzraikk/Pterodactyl-Installer"
echo ""
echo "Este Script no esta asociado con la Documentación oficial de Pterodactyl."
echo ""
oscheck
