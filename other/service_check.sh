#!/bin/bash
#服务器列表
ip=(10.0.0.2 10.0.0.3 10.0.0.4)

# 检测服务器运行是否正常
for i in ${ip[@]}
do

	pin=`ping -c 3 $i >/dev/null || echo 'no'`
	if [ "$pin" == "no" ]; then
		ip=(${ip[*]/$i/})
		echo "$i server is down" | mailx -s 'Warning' admin@host.com
	fi
done

# 检测服务运行是否正常
for x in ${ip[*]}
do
	stat=`ssh $x "forever list | grep -i stopped"`
	disk=`ssh $x "df -h | grep /$" | awk '{print $5}'|awk -F"%" '{print $1}'`
	disk_use=`ssh $x "df -h | grep /$" | awk '{print $3}'`
	if [ ! -z "$stat" ]; then
		echo "$x forever is stop " | mailx -s 'Warning' admin@host.com 
	fi
	# 检测磁盘使用率
	if [ $disk -ge 50 ]; then
		echo "$x Disk usage beyond 50% ; useing ($disk_use)" | mailx -s 'Warning' admin@host.com
	fi

done


