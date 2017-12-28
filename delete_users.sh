#!/bin/bash
#delete_users.sh
#2017-12-28
#by minglin

for USER in user{1..5};do

        if id ${USER} &>/dev/null;then
                userdel -r ${USER}
                echo "Delete ${USER} success!!"
        else
                echo "${USER} is not exists!"
        fi
done
