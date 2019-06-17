#!/usr/bin/env bash
#redhat7.5 vsftpd tftp
#
#实例中发现用户名密码登录出错，删除/opt/vsftp/pass文件，重新创建pass文件并生成db_load -T -t hash -f /opt/vsftp/pass /opt/vsftp/pass.db文件即可
#cd /tmp
#rpm -ivh xinetd-2.3.15-13.el7.x86_64.rpm tftp-5.2-22.el7.x86_64.rpm  tftp-server-5.2-22.el7.x86_64.rpm  vsftpd-3.0.2-25.el7.x86_64 (1).rpm

firewall-cmd --zone=public --add-port=21/tcp --permanent
firewall-cmd --zone=public --add-port=9507-9527/tcp --permanent
firewall-cmd --zone=public --add-port=69/udp --permanent
firewall-cmd --zone=public --add-port=31009/tcp --permanent
firewall-cmd --reload


groupadd -g 99 -r nobody
useradd -u 99 -g 99 -r -M -s /sbin/nologin nobody
useradd -s /sbin/nologin ftp2
mkdir /etc/vsftpd/vconf/
mkdir /opt/vsftp
touch /opt/vsftp/pass
touch /etc/vsftpd/chroot_list
mkdir -p /var/vsftp/ftpUser1
chown -R ftp2:ftp2 /var/vsftp/ftpUser1
chmod -R 755 /var/vsftp/ftpUser1

##虚拟用户账号密码
cat >/etc/vsftpd/chroot_list <<-EOF
ftpUser1
EOF
cat >/opt/vsftp/pass <<-EOF
ftpUser1 
tisson2019J
test1
654321
EOF
db_load -T -t hash -f /opt/vsftp/pass /opt/vsftp/pass.db
cp /etc/pam.d/vsftpd /etc/pam.d/vsftpd.bak
cat >/etc/pam.d/vsftpd <<-EOF
auth    sufficient      /lib64/security/pam_userdb.so     db=/opt/vsftp/pass
account sufficient      /lib64/security/pam_userdb.so     db=/opt/vsftp/pass
EOF

##主配置文件
cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak
cat >/etc/vsftpd/vsftpd.conf <<-EOF
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
#connect_from_port_20=YES
#port_enable=YES
xferlog_std_format=YES
listen=NO
listen_ipv6=YES
pasv_enable=YES
pasv_min_port=9507
pasv_max_port=9527
chroot_local_user=NO
chroot_list_enable=YES
chroot_list_file=/etc/vsftpd/chroot_list
allow_writeable_chroot=YES
listen_port=31121
guest_enable=YES
guest_username=ftp2
virtual_use_local_privs=NO
user_config_dir=/etc/vsftpd/vconf
reverse_lookup_enable=NO
vsftpd_log_file=/var/log/vsftpd.log
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
EOF

##虚拟用户配置文件
touch /etc/vsftpd/vconf/ftpUser1
cat > /etc/vsftpd/vconf/ftpUser1 <<-EOF
local_root=/var/vsftp/ftpUser1
anon_umask=077
anon_world_readable_only=NO
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
EOF

systemctl start vsftpd.service
firewall-cmd --list-all
