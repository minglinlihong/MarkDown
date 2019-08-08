#！/usr/bin/env bash
#安装jdk,tomcat

##下载软件
set -x
cd /tmp
wget -c --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
https://download.oracle.com/otn/java/jdk/8u101-b13/jdk-8u101-linux-x64.tar.gz?AuthParam=1565060938_11f832ef80bc0a00eac67cef7ad42655

wget -c http://mirror.bit.edu.cn/apache/tomcat/tomcat-8/v8.5.42/bin/apache-tomcat-8.5.42.tar.gz
#wget -c http://mirrors.sohu.com/mysql/MySQL-5.7/mysql-5.7.26-el7-x86_64.tar.gz ##使用国内镜像源会快一点点
#wget -c http://nginx.org/download/nginx-1.12.2.tar.gz
#wget -c https://www.php.net/distributions/php-7.2.21.tar.gz
set +x

yum  -y groupinstall  "Development Tools"   ##安装开发工具，编译时会用到
##安装jdk
[ -f /tmp/jdk-8u101-linux-x64.tar.gz ] && tar -xf /tmp/jdk-8u101-linux-x64.tar.gz -C /usr/local
cat >> /etc/profile <<-EOF
##jdk
export JAVA_HOME=/usr/local/jdk1.8.0_101
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
[ -f /tmp/apache-tomcat-8.5.42.tar.gz ] && tar -xf /tmp/apache-tomcat-8.5.42.tar.gz -C /usr/local
java -version
retval=$?
if [[ $retval -eq 0 ]]; then
    /usr/bin/sh /usr/local/apache-tomcat-8.5.42/bin/startup.sh &>/dev/null
    
    if ps -elf|grep "tomcat"|egrep -v "grep" &>/dev/null; then
        echo "tomcat successful installed"
    else
        echo "tomcat not installed,please jdk or other"
    fi
else
    echo "check jdk"
fi
