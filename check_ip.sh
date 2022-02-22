#!/bin/bash
#date 2022-2-22 14:30
#author E-mail  minglinlihong@163.com
#探测内网在用网络

> /tmp/up.txt
> /tmp/down.txt

for i in 128.28.26.{1..254};do
        ping -c 1 -w 1 $i &> /dev/null
        if [ $? -eq 0 ];then
                echo "$i is up!"|tee -a /tmp/up.txt
        else
                echo "$i is down!"|tee -a /tmp/down.txt
        fi
done
