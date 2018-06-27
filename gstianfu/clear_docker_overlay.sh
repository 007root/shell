#!/bin/bash


docker_name=`sudo docker ps -a | awk '{print $NF}' | grep -v NAME`
for i in ${docker_name[@]}
do
    sudo docker inspect $i >> /tmp/docker_msg
done

for x in `sudo ls /var/lib/docker/overlay2`
do
    if [[ $i != l ]]; then
        grep $x /tmp/docker_msg >/dev/null || sudo rm -rf /var/lib/docker/overlay2/$x
    fi
done
rm -rf /tmp/docker_msg

