#!/usr/bin/env bash
## 2019-04-26 redhat7 Update openssh
#https://www.cnblogs.com/ltlinux/p/9472518.html
#https://www.cnblogs.com/liangjingfu/p/9635657.html
#https://www.laofuxi.com/797.html
#https://blog.51cto.com/techsnail/2138927?source=dra

yum install gcc zlib-devel pam-devel wget vim -y --nogpgcheck &> /dev/null

##openssl-1.1.1
cd /tmp
wget -c https://www.openssl.org/source/openssl-1.1.1b.tar.gz
#wget -c https://openbsd.hk/pub/OpenBSD/OpenSSH/portable/openssh-8.0p1.tar.gz
wget -c ftp://ftp.yzu.edu.tw/pub/OpenBSD/OpenSSH/portable/openssh-8.0p1.tar.gz
cp /usr/lib64/libcrypto.so.10 /usr/lib64/libcrypto.so.10.old
cp /usr/lib64/libssl.so.10 /usr/lib64/libssl.so.10.old
rpm -e --nodeps $(rpm -qa | grep openssl)
tar -zxvf openssl-1.1.1b.tar.gz &> /dev/null
cd /tmp/openssl-1.1.1b
echo "Is working ..."
./config --prefix=/usr --openssldir=/etc/ssl --shared zlib 2>&1 >/dev/null
make &> /dev/null
make test &> /dev/null
make install &> /dev/null
/usr/bin/openssl version
if [[ $? = 0 ]]; then
	echo -e "\n\033[32;40m[Openssl Success !]\033[0m"
else
	echo -e "\n\033[31;40m[Openssl Failed !]\033[0m"
fi

##openssh8.0p1
mv /etc/ssh /etc/ssh.old
rpm -e --nodeps $(rpm -qa|grep openssh)
cd /tmp
tar -zxvf openssh-8.0p1.tar.gz &> /dev/null
cd /tmp/openssh-8.0p1
./configure --prefix=/usr --sysconfdir=/etc/ssh --with-md5-passwords --with-zlib --with-ssl-dir=/usr &>/dev/null
make &>/dev/null
make install &> /dev/null
cp contrib/redhat/sshd.init /etc/init.d/sshd
chkconfig --add sshd
chkconfig sshd on
sed -i "32a PermitRootLogin yes" /etc/ssh/sshd_config
/usr/bin/ssh -V
if [[ $? = 0 ]]; then
	echo -e "\n\033[32;40m[Openssh Success !]\033[0m"
else
	echo -e "\n\033[31;40m[Openssh Failed !]\033[0m"
fi

systemctl restart sshd
