#！/bin/env bash
#default password is "oracle"
#密码：oracle	SID:cdb1
#环境：centos7.5 oracle_12c_r2 CPU:>2核 disk:>30G memory:>2G
#https://www.cnblogs.com/zydev/p/5827207.html
#https://blog.csdn.net/sunbocong/article/details/78193187
#http://blog.51cto.com/12790274/2062955
#http://blog.itpub.net/22664653/viewspace-1062585/
#https://stackoverflow.com/questions/50473777/fatal-dbt-10503-invalid-template-file-specified
#2018.11.11

#安装依赖，创建用户和组，preinstall自动配置环境
yum install vim unzip wget net-tools -y
cd /etc/yum.repos.d/
wget http://public-yum.oracle.com/public-yum-ol7.repo
yum install net-tools oracle-rdbms-server-12cR1-preinstall.x86_64 -y --nogpgcheck
#less /var/log/oracle-rdbms-server-11gR2-preinstall/results/orakernel.log

##关闭防火墙
sed -i "s/enforcing/disabled/" /etc/selinux/config
setenforce 0
systemctl stop firewalld

##创建数据库目录 The installation directory and variable
mkdir -p /u01/app/oracle
chmod -R 775 /u01/app
chown -R oracle:oinstall /u01

cp /home/oracle/.bash_profile /home/oracle/.bash_profile.bak
cat >> /home/oracle/.bash_profile <<-EOF
##for oracle
export ORACLE_BASE=/u01/app/oracle
export ORACLE_SID=cdb1
export ROACLE_PID=ora12c
#export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export LD_LIBRARY_PATH=/u01/app/oracle/product/12.2.0/db_1/lib:/usr/lib
export ORACLE_HOME=/u01/app/oracle/product/12.2.0/db_1
export PATH=$PATH:/u01/app/oracle/product/12.2.0/db_1/bin
export LANG="zh_CN.UTF-8"
export NLS_LANG="SIMPLIFIED CHINESE_CHINA.AL32UTF8"
export NLS_DATE_FORMAT='yyyy-mm-dd hh24:mi:ss'
EOF
source /home/oracle/.bash_profile

##unzip oracle
##你应该先下载oracle 12c r2的安装包上传到服务器才可以运行以下命令
##https://www.oracle.com/technetwork/cn/database/enterprise-edition/downloads/index.html
unzip -d /tmp/ /tmp/linuxx64_12201_database.zip && rm -rf /tmp/linuxx64_12201_database.zip
mkdir /home/oracle/etc
cp /tmp/database/response/* /home/oracle/etc/
chown -R oracle:oinstall /home/oracle/etc/
chmod 700 /home/oracle/etc/*
chown -R oracle:oinstall /tmp/database

##modify the db_install.rsp
sed -i 's#oracle.install.option=#oracle.install.option=INSTALL_DB_SWONLY#g' /home/oracle/etc/db_install.rsp
sed -i 's#UNIX_GROUP_NAME=#UNIX_GROUP_NAME=oinstall#g' /home/oracle/etc/db_install.rsp
sed -i 's#INVENTORY_LOCATION=#INVENTORY_LOCATION=/u01/app/oraInventory/#' /home/oracle/etc/db_install.rsp
sed -i 's#ORACLE_HOME=#ORACLE_HOME=/u01/app/oracle/product/12.2.0/db_1#g' /home/oracle/etc/db_install.rsp
sed -i 's#ORACLE_BASE=#ORACLE_BASE=/u01/app/oracle#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.InstallEdition=#oracle.install.db.InstallEdition=EE#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.OSDBA_GROUP=#oracle.install.db.OSDBA_GROUP=dba#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.OSOPER_GROUP=#oracle.install.db.OSOPER_GROUP=oinstall#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.OSBACKUPDBA_GROUP=#oracle.install.db.OSBACKUPDBA_GROUP=dba#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.OSDGDBA_GROUP=#oracle.install.db.OSDGDBA_GROUP=dba#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.OSKMDBA_GROUP=#oracle.install.db.OSKMDBA_GROUP=dba#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.OSRACDBA_GROUP=#oracle.install.db.OSRACDBA_GROUP=dba#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.config.starterdb.type=#oracle.install.db.config.starterdb.type=GENERAL_PURPOSE#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.config.starterdb.globalDBName=#oracle.install.db.config.starterdb.globalDBName=cdb1#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.config.starterdb.SID=#oracle.install.db.config.starterdb.SID=cdb1#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.config.starterdb.memoryLimit=#oracle.install.db.config.starterdb.memoryLimit=81920#g' /home/oracle/etc/db_install.rsp    ##自动管理内存
sed -i 's#oracle.install.db.config.starterdb.password.ALL=#oracle.install.db.config.starterdb.password.ALL=oracle#g' /home/oracle/etc/db_install.rsp
sed -i 's#oracle.install.db.config.starterdb.characterSet=#oracle.install.db.config.starterdb.characterSet=AL32UTF8#g' /home/oracle/etc/db_install.rsp
sed -i 's#SECURITY_UPDATES_VIA_MYORACLESUPPORT=#SECURITY_UPDATES_VIA_MYORACLESUPPORT=false#g' /home/oracle/etc/db_install.rsp
sed -i 's#DECLINE_SECURITY_UPDATES=#DECLINE_SECURITY_UPDATES=true#g' /home/oracle/etc/db_install.rsp

##action db_install_rsp
su - oracle <<-EOF
source /home/oracle/.bash_profile
cd /tmp/database
./runInstaller -skipPrereqs -silent -force -responseFile /home/oracle/etc/db_install.rsp
EOF
sleep 720
sh /u01/app/oraInventory/orainstRoot.sh
sh /u01/app/oracle/product/12.2.0/db_1/root.sh

##action netca.rsp 监听程序
su - oracle <<-EOF
source /home/oracle/.bash_profile
netca /silent /responsefile /home/oracle/etc/netca.rsp
EOF

##action dbca.rsp 建库
sed -i 's#gdbName=#gdbName=cdb1#g' /home/oracle/etc/dbca.rsp
sed -i 's#sid=#sid=cdb1#g' /home/oracle/etc/dbca.rsp
sed -i 's#templateName=#templateName=General_Purpose.dbc#g' /home/oracle/etc/dbca.rsp
sed -i 's#sysPassword=#sysPassword=oracle#g' /home/oracle/etc/dbca.rsp
sed -i 's#systemPassword=#systemPassword=oracle#g' /home/oracle/etc/dbca.rsp
sed -i 's#dbsnmpPassword=#dbsnmpPassword=oracle#g' /home/oracle/etc/dbca.rsp
sed -i 's#characterSet=#characterSet=AL32UTF8#g' /home/oracle/etc/dbca.rsp
su - oracle <<-EOF
source /home/oracle/.bash_profile
dbca -silent -createDatabase -responseFile /home/oracle/etc/dbca.rsp
EOF

##configure oracle service start/stop
sed -i 's#ORACLE_HOME_LISTNER=$1#ORACLE_HOME_LISTNER=$ORACLE_HOME#g' /u01/app/oracle/product/12.2.0/db_1/bin/dbstart
sed -i 's#cdb1:/u01/app/oracle/product/12.2.0/db_1:N#cdb1:/u01/app/oracle/product/12.2.0/db_1:Y#g' /etc/oratab

echo "Thank you!It's done!!"
