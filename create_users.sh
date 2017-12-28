#!/bin/bash
#create_users.sh
#2017-12-28
#by minglin

for USER in user{1..5};do
        if ! id $USER &>/dev/null;then
                pass=$(echo $RANDOM |md5sum|cut -c 1-8)
                useradd $USER
                echo $pass |passwd --stdin $USER &>/dev/null
                echo -e "$USER\t$pass" >>users.txt
                echo "$USER create success!"
        else
                echo $USER exists
        fi
done
