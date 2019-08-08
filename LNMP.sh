#！/usr/bin/env bash
#mysql,nginx,php

##下载软件
set -x
cd /tmp
wget -c http://mirrors.sohu.com/mysql/MySQL-5.7/mysql-5.7.26-el7-x86_64.tar.gz ##使用国内镜像源会快一点点
wget -c http://nginx.org/download/nginx-1.12.2.tar.gz
wget -c https://www.php.net/distributions/php-7.2.21.tar.gz
set +x

yum  -y groupinstall  "Development Tools"   ##安装开发工具，编译时会用到

##安装mysql
[ -f /tmp/mysql-5.7.26-el7-x86_64.tar.gz ] && tar -xf /tmp/mysql-5.7.26-el7-x86_64.tar.gz -C /usr/local
ln -s /usr/local/mysql-5.7.26-el7-x86_64 /usr/local/mysql
groupadd mysql
useradd -g mysql -r -s /sbin/nologin -M -d /data/mysqldata mysql
chown -R mysql:mysql /usr/local/mysql
mkdir -p /data/mysqldata
chmod -R 770 /data/mysqldata
chown -R mysql:mysql /data/mysqldata
cd /usr/local/mysql
./bin/mysqld --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysqldata --initialize &> /tmp/my_passwd.txt
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
ldconfig
echo "PATH=$PATH:/usr/local/mysql/bin" > /etc/profile.d/mysql.sh
source /etc/profile.d/mysql.sh
chkconfig mysqld on
cat > /etc/my.cnf <<-"EOF"
[mysqld]
basedir=/usr/local/mysql #mysql路径
datadir=/data/mysqldata #mysql数据目录
socket=/tmp/mysql.sock
user=mysql
server_id=1 #MySQLid 后面2个从服务器需设置不同
port=3306
EOF
/usr/sbin/service mysqld start
retval=$?
if [[ $retval -eq 0 ]]; then
    echo "mysql successful installed"
else
    echo "mysql not installed,please check"
fi

old_passwd=$(sed -n '$'p /tmp/my_passwd.txt |awk -F': ' '{print $NF}')
new_passwd="123456"
/usr/local/mysql/bin/mysql -uroot -p"${old_passwd}" -b --connect-expired-password <<-EOF
set password for 'root'@'localhost'=password("$new_passwd");
flush privileges;
EOF

#mysql -uroot '-pkUeAt=u#L2*Z' -e "set password for 'root'@'localhost'=password('123456');" -b --connect-expired-password

/usr/local/mysql/bin/mysql -uroot -p"${new_passwd}" -e "show databases;"
if [[ $retval -eq 0 ]]; then
    echo "mysql successful installed"
else
    echo "mysql not installed,please check"
fi

##安装nginx
yum install pcre pcre-devel openssl openssl-devel -y
[ -f /tmp/nginx-1.12.2.tar.gz ] && tar -xf /tmp/nginx-1.12.2.tar.gz
useradd -s /sbin/nologin nginx
cd /tmp/nginx-1.12.2
./configure --prefix=/usr/local/nginx --with-http_ssl_module --user=nginx  --group=nginx && make && make install

##nginx启动脚本
cat >/etc/init.d/nginx<<-"EOF"
#!/bin/sh
#
# nginx - this script starts and stops the nginx daemon
#
# chkconfig:   - 85 15
# description: Nginx is an HTTP(S) server, HTTP(S) reverse \
#               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /etc/nginx/nginx.conf
# config:      /etc/sysconfig/nginx
# pidfile:     /var/run/nginx.pid

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0

nginx="/usr/local/nginx/sbin/nginx"
prog=$(basename $nginx)

NGINX_CONF_FILE="/usr/local/nginx/conf/nginx.conf"

[ -f /etc/sysconfig/nginx ] && . /etc/sysconfig/nginx

lockfile=/var/lock/subsys/nginx

start() {
    [ -x $nginx ] || exit 5
    [ -f $NGINX_CONF_FILE ] || exit 6
    echo -n $"Starting $prog: "
    daemon $nginx -c $NGINX_CONF_FILE
    retval=$?
    echo
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}
stop() {
    echo -n $"Stopping $prog: "
    killproc $prog -QUIT
    retval=$?
    echo
    [ $retval -eq 0 ] && rm -f $lockfile
    return $retval
killall -9 nginx
}
restart() {
    configtest || return $?
    stop
    sleep 1
    start
}
reload() {
    configtest || return $?
    echo -n $"Reloading $prog: "
    killproc $nginx -HUP
RETVAL=$?
    echo
}
force_reload() {
    restart
}
configtest() {
$nginx -t -c $NGINX_CONF_FILE
}
rh_status() {
    status $prog
}
rh_status_q() {
    rh_status >/dev/null 2>&1
}
case "$1" in
    start)
        rh_status_q && exit 0
    $1
        ;;
    stop)
        rh_status_q || exit 0
        $1
        ;;
    restart|configtest)
        $1
        ;;
    reload)
        rh_status_q || exit 7
        $1
        ;;
    force-reload)
        force_reload
        ;;
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
            ;;
    *)    
      echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload|configtest}"
        exit 2
esac
EOF
chmod +x /etc/init.d/nginx

##nginx配置文件
cat > /usr/local/nginx/conf/nginx.conf <<-"EOF"
# For more information on configuration, see:# * Official English Documentation: http://nginx.org/en/docs/# * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
worker_processes auto;
error_log logs/error.log;
pid /var/run/nginx.pid;

# Load dynamic modules. See /usr/share/nginx/README.dynamic.include /usr/share/nginx/modules/*.conf;

events {
worker_connections 1024;
}

http {
log_format main '$remote_addr - $remote_user [$time_local] "$request" '
'$status $body_bytes_sent "$http_referer" '
'"$http_user_agent" "$http_x_forwarded_for"';

access_log logs/access.log main;

sendfile on;
tcp_nopush on;
tcp_nodelay on;
keepalive_timeout 65;
types_hash_max_size 2048;

default_type application/octet-stream;
# Load modular configuration files from the /etc/nginx/conf.d directory.
# See http://nginx.org/en/docs/ngx_core_module.html#include
# for more information.

server {
listen 80;
server_name localhost;
root /usr/local/nginx/html;

location / {
index index.php index.html index.htm;
}

error_page 500 502 503 504 /50x.html;
location = /50x.html {
root /usr/local/nginx/html;
}

location ~ \.php$ {
fastcgi_pass 127.0.0.1:9000;
fastcgi_index index.php;
fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
include fastcgi_params;
            }

    }
}
EOF

service nginx start

if ps -elf|grep "nginx"|egrep -v "grep" &>/dev/null; then
    echo "nginx installed successful "
else
    echo "nginx not installed"
fi
chkconfig nginx on

##安装php
useradd -s /sbin/nologin php-fpm
yum install libxml2-devel curl-devel libjpeg-turbo-devel libpng-devel freetype-devel -y
[ -f /tmp/php-7.2.21.tar.gz ] && tar -xf /tmp/php-7.2.21.tar.gz -C /tmp
if [ -d /tmp/php-7.2.21 ] ;then
    cd /tmp/php-7.2.21
    ./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --enable-fpm --with-fpm-user=php-fpm --with-fpm-group=php-fpm \
    --with-mysqli --with-mysql-sock=/tmp/mysql.sock --with-libxml-dir --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --with-iconv-dir \
    --with-zlib-dir --with-mcrypt --enable-soap --enable-ftp --enable-mbstring --enable-exif --disable-ipv6 \
    --with-pear --with-curl --with-openssl --with-gettext --enable-bcmath --enable-sockets &>/dev/null && make &>/dev/null && make install
    cp /tmp/php-7.2.21/php.ini-production /usr/local/php/etc/php.ini
    mv /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
    mv /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
    /usr/local/php/sbin/php-fpm -t
    if [[ $? -eq 0 ]]; then
        echo "php-fpm installed successful"
    else
        echo "php-fpm not installed"
    fi
    cp /tmp/php-7.2.21/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
    chmod 755 /etc/init.d/php-fpm
    service php-fpm start

    if ps -elf|grep "php-fpm"|egrep -v "grep" &>/dev/null; then
        echo "php-fpm successful installed"
    else
        echo "php-fpm not installed"
    fi
    chkconfig php-fpm on

    cat >/etc/profile.d/php.sh<<-"EOF"
    export PATH=$PATH:/usr/local/php/bin
    EOF
    source /etc/profile.d/php.sh

    php -v &>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "php successful installed"
    else
        echo "php not installed,please check"
    fi

    ##nginx+php for test
    cat >/usr/local/nginx/html/test.php<<-EOF
    <?php
    phpinfo();
    ?>
    EOF

    curl -I http://127.0.0.1/test.php
    if [[ $? -eq 0 ]]; then
        echo "php+nginx successful installed"
    else
        echo "php+nginx not installed,please check"
    fi
else
    echo "check /tmp/php-7.2.21"
    exit 2
fi
