#!/usr/bin/env bash
#centos6.9 oracle11gR2
#Refer to the links: https://www.cnblogs.com/zydev/p/5827207.html http://blog.51cto.com/1767340368/2091706
#Oracle default password is "oracle"
#2018.8.24

hostname oracledb.01
sed -i "s/HOSTNAME=localhost.localdomain/HOSTNAME=oracledb.01/" /etc/sysconfig/network
ip=`ifconfig |awk -F'[: ]+' 'NR==2{print $4'}`
echo "$ip oracledb.01" >> /etc/hosts
##stop firewall
sed -i "s/enforcing/disabled/" /etc/selinux/config
setenforce 0
service iptables stop
chkconfig iptables off
chkconfig ip6tables off
##install software
yum install -y expect unzip vim wget binutils compat-libcap1 compat-libstdc++ gcc gcc-c++ glibc glibc-devel ksh libgcc libstdc++ libstdc++-devel libaio libaio-devel make sysstat
#create user
/usr/sbin/groupadd oinstall
/usr/sbin/groupadd dba
/usr/sbin/useradd -g oinstall -G dba oracle
echo "oracle" |passwd --stdin oracle
id oracle
if [ $? != 0 ];then
	echo "oracle create failed" > /tmp/oracle_err.log
	exit 1
fi

##system kernel
cp /etc/sysctl.conf /etc/sysctl.conf.bak
cat >> /etc/sysctl.conf <<-EOF
##Oracle
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 536870912
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
EOF
/sbin/sysctl -p

cp /etc/security/limits.conf /etc/security/limits.conf.bak
cat >> /etc/security/limits.conf <<-EOF
##Oracle
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft stack 10240
oracle hard stack 10240
EOF

cp /etc/pam.d/login /etc/pam.d/login.bak
cat >> /etc/pam.d/login <<-EOF
##Oracle
session required /lib64/security/pam_limits.so
session required pam_limits.so
EOF

cp /etc/profile /etc/prefile.bak
cat >> /etc/profile <<-EOF
##Oracle
if [ $USER = "oracle" ]; then
   if [ $SHELL = "/bin/ksh" ]; then
       ulimit -p 16384
       ulimit -n 65536
    else
       ulimit -u 16384 -n 65536
   fi
fi
EOF
source /etc/profile

##The installation directory and variable
mkdir -p /u01/app/
chown -R oracle:oinstall /u01/app/
chmod -R 775 /u01/app/
cp /home/oracle/.bash_profile /home/oracle/.bash_profile.bak

cat >> /home/oracle/.bash_profile <<-EOF
##for oracle
export ORACLE_BASE=/u01/app/oracle
export ORACLE_SID=dbsrv2
#export ROACLE_PID=ora11g
#export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export LD_LIBRARY_PATH=/u01/app/oracle/product/11.2.0/db_1/lib:/usr/lib
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1
export PATH=$PATH:/u01/app/oracle/product/11.2.0/db_1/bin
export LANG="zh_CN.UTF-8"
export NLS_LANG="SIMPLIFIED CHINESE_CHINA.AL32UTF8"
export NLS_DATE_FORMAT='yyyy-mm-dd hh24:mi:ss'
EOF
source /home/oracle/.bash_profile

# #!!!上传文件到/opt/oracle目录或者直接下载，(文件过大，建议上传)，我这里是从其他机器copy过来的。
# /usr/bin/expect<<-EOF
# set timeout 100
# spawn scp root@192.168.135.108:/opt/oracle/linuxamd64_12102_database_* /opt/oracle
# expect {
# "*yes/no" { send "yes\r"; exp_continue }
# "*password:" { send "00000000\r" }
# }
# expect eof
# EOF
       
# su - oracle <<EOF
# cd /opt/oracle;
# #wget http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_database_1of2.zip;
# #wget http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_database_2of2.zip;
# unzip linuxamd64_12102_database_1of2.zip;
# unzip linuxamd64_12102_database_2of2.zip;
# exit;
# EOF

##unzip oracle
unzip /tmp/linux.x64_11gR2_database_1of2.zip -d /tmp
unzip /tmp/linux.x64_11gR2_database_2of2.zip -d /tmp
mkdir /home/oracle/etc
cp /tmp/database/response/* /home/oracle/etc/
chown -R oracle:oinstall /home/oracle/etc/
chmod 700 /home/oracle/etc/*
chown -R oracle:oinstall /tmp/database

##modify the db_install.rsp
sed -i 's#oracle.install.option=#oracle.install.option=INSTALL_DB_SWONLY#g' /home/oracle/etc/db_install.rsp
sed -i 's#ORACLE_HOSTNAME=#ORACLE_HOSTNAME=oracledb.01#g' /home/oracle/etc/db_install.rsp
sed -i 's#UNIX_GROUP_NAME=#UNIX_GROUP_NAME=oinstall#g' /home/oracle/etc/db_install.rsp
sed -i 's#INVENTORY_LOCATION=#INVENTORY_LOCATION=/u01/app/oraInventory/#' /home/oracle/etc/db_install.rsp
sed -i 's#SELECTED_LANGUAGES=#SELECTED_LANGUAGES=en,zh_CN#g' /home/oracle/etc/db_install.rsp
sed -i 's#ORACLE_HOME=#ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1#g' /home/oracle/etc/db_install.rsp
sed -i 's#ORACLE_BASE=#ORACLE_BASE=/u01/app/oracle#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.InstallEdition=#oracle.install.db.InstallEdition=EE#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.isCustomInstall=false#oracle.install.db.isCustomInstall=false#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.DBA_GROUP=#oracle.install.db.DBA_GROUP=dba#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.OPER_GROUP=#oracle.install.db.OPER_GROUP=oinstall#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.config.starterdb.type=#oracle.install.db.config.starterdb.type=GENERAL_PURPOSE#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.config.starterdb.globalDBName=#oracle.install.db.config.starterdb.globalDBName=orcl#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.config.starterdb.SID=#oracle.install.db.config.starterdb.SID=dbsrv2#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.config.starterdb.memoryLimit=#oracle.install.db.config.starterdb.memoryLimit=81920#g' /home/oracle/etc/db_install.rsp    ##自动管理内存
sed -i 's#oracle.install.db.config.starterdb.password.ALL=#oracle.install.db.config.starterdb.password.ALL=oracle#g' /home/oracle/etc/db_install.rsp
sed -i 's#SECURITY_UPDATES_VIA_MYORACLESUPPORT=#SECURITY_UPDATES_VIA_MYORACLESUPPORT=false#g' /home/oracle/etc/db_install.rsp
sed -i 's#DECLINE_SECURITY_UPDATES=#DECLINE_SECURITY_UPDATES=true#g' /home/oracle/etc/db_install.rsp

##action db_install_rsp
su - oracle <<-EOF
source /home/oracle/.bash_profile
cd /tmp/database
./runInstaller -ignorePrereq  -silent -force -responseFile /home/oracle/etc/db_install.rsp
EOF
sleep 600
sh /u01/app/oraInventory/orainstRoot.sh
sh /u01/app/oracle/product/11.2.0/db_1/root.sh

##action netca.rsp 监听程序
su - oracle <<-EOF
source /home/oracle/.bash_profile
netca /silent /responsefile /home/oracle/etc/netca.rsp
EOF

##action dbca.rsp 建库
sed -i 's#GDBNAME = "orcl11g.us.oracle.com"#GDBNAME = "dbsrv2"#g' /home/oracle/etc/dbca.rsp
sed -i 's#SID = "orcl11g"#SID = "dbsrv2"#g' /home/oracle/etc/dbca.rsp
sed -i 's/\#CHARACTERSET = "US7ASCII"/CHARACTERSET = "AL32UTF8"/g' /home/oracle/etc/dbca.rsp
su - oracle <<-EOF
source /home/oracle/.bash_profile
dbca -silent -responseFile etc/dbca.rsp
oracle
oracle
EOF

##configure oracle service start/stop
sed -i 's#ORACLE_HOME_LISTNER=$1#ORACLE_HOME_LISTNER=/u01/app/oracle/product/11.2.0/db_1/#g' /u01/app/oracle/product/11.2.0/db_1/bin/dbstart
sed -i 's#dbsrv2:/u01/app/oracle/product/11.2.0/db_1:N#dbsrv2:/u01/app/oracle/product/11.2.0/db_1:Y#g' /etc/oratab
