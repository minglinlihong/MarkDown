#!/usr/bin/env bash
#安装jdk,tomcat,mysql,nginx,php,redis,memcached
##
packge_dir=/home/tools-4.0/packge
conf_dir=/home/tools-4.0/conf

##数据库密码，需要修改
dbaddr=127.0.0.1
dbuser=user1
database=db1
dbpasswd=123456

yum -y groupinstall  "Development Tools"   ##安装开发工具，编译时会用到
yum -y install unzip
##安装jdk
#
if [ ! -d /opt/apache-tomcat-8.5.42 ];then
    [ -f ${packge_dir}/jdk-8u101-linux-x64.tar.gz ] && tar -xf ${packge_dir}/jdk-8u101-linux-x64.tar.gz -C /opt/
    cat >> /etc/profile <<-"EOF"
    ##jdk
    export JAVA_HOME=/opt/jdk1.8.0_101
    export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib/tools.jar
    export PATH=$JAVA_HOME/bin:$PATH
    EOF
    source /etc/profile
    java -version > /dev/null
    retval=$?
    if [[ $retval -ne 0 ]]; then
        echo "jdk not installed"
    else
        echo "jdk successful installed"
    fi

    ##安装tomcat
    [ -f ${packge_dir}/apache-tomcat-8.5.42.zip ] && unzip -q ${packge_dir}/apache-tomcat-8.5.42.zip -d /opt/
    chmod 755 /opt/apache-tomcat-8.5.42/bin/*.sh
    java -version
    retval=$?
    if [[ $retval -eq 0 ]]; then
        /usr/bin/sh /opt/apache-tomcat-8.5.42/bin/startup.sh &>/dev/null
        if ps -elf|grep "tomcat"|egrep -v "grep" &>/dev/null; then
            echo "tomcat successful installed"
        else
            echo "tomcat not installed,please jdk or other"
        fi
    else
        echo "please check jdk"
    fi
else
    echo "jdk and tomcat maybe already exist,please check it"
fi

##安装mysql
[ -f ${packge_dir}/mysql-community-release-el6-5.noarch.rpm ] && rpm -ivh ${packge_dir}/mysql-community-release-el6-5.noarch.rpm
if [ $? == 0 ];then
    yum -y install mysql-community-server
    cat >/etc/my.cnf<<-EOF
# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/5.6/en/server-configuration-defaults.html
[mysqld]
character-set-server=utf8
lower_case_table_names=1
wait_timeout=31536000
interactive_timeout=31536000
max_allowed_packet = 40M
skip-name-resolve
skip-grant-tables
log-bin = mysql-bin
[client]
default-character-set = utf8
[mysql]
default-character-set = utf8
#
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
symbolic-links=0
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES 
[mysqld_safe]
log-error=/var/log/mysqld.log
EOF
    ###
    ###修改数据库密码，创建数据库
    if `mysql -D $database -e "show databases" | grep $databas|grep -v grep`;then
        mysql -N -e "use mysql;update user set password=password('$dbpasswd') where user='root';flush privileges;"
        mysql -uroot -h$dbaddr -p$dbpasswd -N -e "create database $database;"
        mysql -uroot -h$dbaddr -p$dbpasswd -N -e "grant all on $database.* to $dbuser@'%' identified by '$dbpasswd';"
        mysql -uroot -h$dbaddr -p$dbpasswd -N -e "grant all on $database.* to $dbuser@'localhost' identified by '$dbpasswd';"
    else
        echo "$database already exist,please it"
    fi
    systemctl enable mysqld
    systemctl start mysqld
    echo "mysql 安装成功"
else
    echo "please check mysql"
fi
###安装mysql库文件
if [ ! -d "/home/tools-4.0/mysql" ]; then
    unzip -q ${packge_dir}/mysql.zip
    echo "mysql 解压完成！"
else
    echo "mysql library already exist,please check!"
fi 



#mysql -uroot '-pkUeAt=u#L2*Z' -e "set password for 'root'@'localhost'=password('123456');" -b --connect-expired-password

##安装nginx
if ! id nginx &>/dev/null;then
    yum install pcre pcre-devel openssl openssl-devel -y
    [ -f ${packge_dir}/nginx-1.12.2.tar.gz ] && tar -xf ${packge_dir}/nginx-1.12.2.tar.gz -C /tmp/
    useradd -s /sbin/nologin nginx
    cd /tmp/nginx-1.12.2
    ./configure --prefix=/usr/local/nginx --with-http_ssl_module --user=nginx  --group=nginx && make && make install
    mkdir /usr/local/nginx/vhosts
    mv ${conf_dir}/config.conf /usr/local/nginx/vhosts
    mv ${conf_dir}/config2.conf /usr/local/nginx/vhosts
    cat ${conf_dir}/nginx.conf > /usr/local/nginx/conf/nginx.conf
    sed -i '10c pid \t\t/var/run/nginx.pid;' /usr/local/nginx/conf/nginx.conf
    echo "hello world"
    cp ${conf_dir}/nginx /etc/init.d/
    chmod +x /etc/init.d/nginx
    chkconfig --add nginx
    chkconfig nginx on
    service nginx start
    echo "nginx successful installed"
else
    echo "nginx user already exist,please check nginx"
fi

##安装PHP5.6.30
if ! id php-fpm &>/dev/null;then
	##安装php5.6.30的依赖
	useradd -s /sbin/nologin php-fpm
	yum install libxml2-devel curl-devel libvpx-devel libjpeg-turbo-devel libpng-devel freetype-devel -y

	##安装libmcrypt
	tar -xf ${packge_dir}/libmcrypt-2.5.8.tar.gz -C /tmp/
	cd /tmp/libmcrypt-2.5.8
	./configure
	make && make install

	##安装已经编译过的php
	tar -zxf ${packge_dir}/php5.6.30.tar.gz -C /usr/local/
	cp ${conf_dir}/init.d.php-fpm /etc/init.d/php-fpm
	chmod 755 /etc/init.d/php-fpm
	chkconfig --add php-fpm
	chkconfig php-fpm on
	service php-fpm start
	echo "php-fpm is running..."
else
	echo "php-fpm user already exist,please check php"
fi
echo -e '##\nexport PATH=$PATH:/usr/local/php/bin' >> /etc/profile
##以下是编译安装PHP5.6.30，上面使用编译过的PHP是为了节省编译的时间
# tar -xf ${packge_dir}/php-5.6.30.tar.gz
# cd php-5.6.30
# ./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --enable-fpm --with-fpm-user=php-fpm \
# --with-fpm-group=php-fpm --with-mysql --with-mysqli --with-mysql-sock=/tmp/mysql.sock --with-libxml-dir --with-gd \
# --with-jpeg-dir --with-png-dir --with-freetype-dir --with-iconv-dir --with-zlib-dir --with-mcrypt --enable-soap \
# --enable-gd-native-ttf --enable-ftp --enable-mbstring --enable-exif --disable-ipv6 --with-pear --with-curl --with-openssl \
# --with-vpx-dir --with-gettext --enable-bcmath --enable-sockets
# make && make install
# cp php.ini-production /usr/local/php/etc/php.ini
# mv /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
# /usr/local/php/sbin/php-fpm -t 			###测试php-fpm是否能用了
# cp ${packge_dir}/php-7.2.21/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm 	##php-fpm的启动脚本
# chmod 755 /etc/init.d/php-fpm
# chkconfig --add php-fpm
# chkconfig php-fpm on
# service php-fpm start
# cat >/etc/profile<<-"EOF"
# ##php
# export PATH=$PATH:/usr/local/php/bin
# EOF
# source /etc/profile
# php -v

# 
#安装redis 

if [ -x $(which redis-server) ];then
    echo "redis has been installed successful"
    exit 3
else
    tar -xf ${packge_dir}/redis-3.0.5.tar.gz -C /home/tools-4.0/
    cd /home/tools-4.0/redis-3.0.5/src
    make && make install
    cp /home/tools-4.0/redis-3.0.5/redis.conf /home/tools-4.0/redis-3.0.5/redis1.conf
    cp /home/tools-4.0/redis-3.0.5/redis.conf /home/tools-4.0/redis-3.0.5/redis2.conf
    cp /home/tools-4.0/redis-3.0.5/redis.conf /home/tools-4.0/redis-3.0.5/redis3.conf
    sed -i '50c port 4501' /home/tools-4.0/redis-3.0.5/redis1.conf
    sed -i '50c port 4502' /home/tools-4.0/redis-3.0.5/redis2.conf
    sed -i '50c port 4503' /home/tools-4.0/redis-3.0.5/redis3.conf
    /usr/local/bin/redis-server /home/tools-4.0/redis-3.0.5/redis1.conf &
    /usr/local/bin/redis-server /home/tools-4.0/redis-3.0.5/redis2.conf &
    /usr/local/bin/redis-server /home/tools-4.0/redis-3.0.5/redis3.conf &
fi

#
##安装memcached
if [ -x $(which memcached) ];then
    echo "memcached has been installed successful"
    exit 3
else
    yum install libevent libevent-devel -y
    cd /tmp
    [ -f ${packge_dir}/memcached-1.4.25.tar.gz ] && tar -xf ${packge_dir}/memcached-1.4.25.tar.gz -C /home/tools-4.0/
    cd /home/tools-4.0/memcached-1.4.25
    ./configure && make && make install
    /usr/local/bin/memcached -d -p 11215 -u root -m 64 -c 1024 -P /var/run/memcached_11215.pid
    /usr/local/bin/memcached -d -p 11201 -u root -m 64 -c 1024 -P /var/run/memcached_11201.pid
fi


###导入python2的redis-py库模块
if [ -f ${packge_dir}/redis-2.10.5.tar.gz ];then
    if [ ! -d /usr/lib/python2.7/site-packages/redis ] ;then
        tar -xf ${packge_dir}/redis-2.10.5.tar.gz -C /tmp
        cd /tmp/redis-2.10.5
        /usr/bin/python setup.py install
    else
        echo "please check 导入python2的redis-py库模块"
    fi
fi

###判断redis与memcached是否已经安装并启动
if ps -elf|grep "redis"|egrep -v "grep"; then
    echo -e "\033[40;32m redis successful installed \033[0m"
else
    echo -e "\033[31;40m redis not installed !!! \033[0m"
fi

if ps -elf|grep "memcached"|egrep -v "grep"; then
    echo -e "\033[40;32m memcached successful installed \033[0m"
else
    echo -e "\033[31;40m memcached not installed !!! \033[0m"
fi

if [ -d /usr/lib/python2.7/site-packages/redis ] ;then
    echo -e "\033[40;32m redis import successful for python2 \033[0m"
else
    echo -e "\033[31;40m redis import not installed !!! \033[0m"
fi
