#!/usr/bin/env bash
. /etc/profile
if [ -x $(which redis-server) ];then
	echo "redis has been installed successful"
	exit 3
else
	yum  -y groupinstall  "Development Tools"  && yum install wget -y  ##安装开发工具，编译时会用到
	cd /tmp
	wget -c http://download.redis.io/releases/redis-3.0.5.tar.gz
	wget -c https://pypi.python.org/packages/source/r/redis/redis-2.10.5.tar.gz
	wget -c http://www.memcached.org/files/memcached-1.4.25.tar.gz

	##redis
	cd /tmp
	tar -xf /tmp/redis-3.0.5.tar.gz -C /home
	cd /home/redis-3.0.5/src
	make && make install
	cp /home/redis-3.0.5/redis.conf /home/redis-3.0.5/redis1.conf
	cp /home/redis-3.0.5/redis.conf /home/redis-3.0.5/redis2.conf
	cp /home/redis-3.0.5/redis.conf /home/redis-3.0.5/redis3.conf
	sed -i '50c port 4501' /home/redis-3.0.5/redis1.conf
	sed -i '50c port 4502' /home/redis-3.0.5/redis2.conf
	sed -i '50c port 4503' /home/redis-3.0.5/redis3.conf
	/usr/local/bin/redis-server /home/redis-3.0.5/redis1.conf &
	/usr/local/bin/redis-server /home/redis-3.0.5/redis2.conf &
	/usr/local/bin/redis-server /home/redis-3.0.5/redis3.conf &

	##memcached
	yum install libevent libevent-devel -y
	cd /tmp
	[ -f /tmp/memcached-1.4.25.tar.gz ] && tar -xf /tmp/memcached-1.4.25.tar.gz -C /tmp
	cd /tmp/memcached-1.4.25
	./configure && make && make install
	/usr/local/bin/memcached -d -p 11215 -u root -m 64 -c 1024 -P /var/run/memcached_11215.pid
	/usr/local/bin/memcached -d -p 11201 -u root -m 64 -c 1024 -P /var/run/memcached_11201.pid

	##导入python2的redis-py库模块
	cd /tmp
	tar -xf redis-2.10.5.tar.gz -C /tmp
	cd /tmp/redis-2.10.5
	/usr/bin/python setup.py install

	##判断程序是否已经安装并启动
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
fi
