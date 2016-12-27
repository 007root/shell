#!/bin/bash

load=`uptime`
mem=`cat /proc/meminfo | head -4 | awk '{print $1,$2/1024,"MB"}'`
redis_mem=`/redis-6379/src/redis-cli info | grep -i used_mem | sed 's/\r//g'` # redis 获取到换行符为\r\n 会造成发送的邮件变成附件 bin 文件
ser_list=`forever  list | grep -E '_[0-9]{4}' | awk '{print $6}' | awk -F"_" '{print $1}' | sort | uniq`
disk_use=`df -h`


ser="+++++++++++++++++++++++++++   service  +++++++++++++++++++++++++++"
loadt="+++++++++++++++++++++++++++    load    +++++++++++++++++++++++++++"
memt="+++++++++++++++++++++++++++    mem     +++++++++++++++++++++++++++"
redis="+++++++++++++++++++++++++++   redis    +++++++++++++++++++++++++++"
disk="+++++++++++++++++++++++++++    disk    +++++++++++++++++++++++++++"

all="$ser
$ser_list
$memt
$mem
$loadt
$load
$disk
$disk_use
$redis
$redis_mem
"
echo "$all" | mailx -s "Status" wzs789456123@qq.com

