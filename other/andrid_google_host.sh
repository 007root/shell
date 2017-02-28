#!/system/bin/sh

busybox mount -o remount,rw -t auto /system

curl -k https://github.com/racaljk/hosts/blob/master/hosts | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*</td>' | busybox awk -F"<" '{print $1}'  &> /system/etc/hosts
