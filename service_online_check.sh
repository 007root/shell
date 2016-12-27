#!/bin/bash

# 发送邮件需要在服务器安装 mailx 命令
# 添加发件人信息
# 配置 /etc/mail.rc 追加一下内容
# set from=admin@sina.com smtp=smtp.sina.com
# set smtp-auth-user=admin@sina.com smtp-auth-password=adminpassword smtp-auth=login



# 添加计划任务每分钟执行，避免与系统任务冲突;每次执行等待15秒
sleep 15

# 获取服务器状态
stat=`/usr/local/bin/forever list --no-colors | grep -i "stopped"`
if [ ! -z "$stat" ]; then
    game_id=`/usr/local/bin/forever list --no-colors | grep -i "stopped" | awk '{print $3}'`
    for id in $game_id
    do  
   	game_name=`/usr/local/bin/forever list  --no-colors | grep "$id" | awk '{print $6}'`
	game_log=`tail -30 /root/.forever/${id}.log`
	# 尝试重启三次服务
	for ((i=1;i<=3;i++))
	do
		/usr/local/bin/forever restart $id &> /dev/null
		sleep 1.5
		re_stat=`/usr/local/bin/forever list --no-colors | grep "$id" | grep -i "stopped"`
		if [ ! -z "$re_stat" ]; then
			# 三次重启未成功，发邮件
			if [ $i -eq 3 ]; then
				echo "$game_log" | mailx -s "Error" Administrator@qq.com
			fi
			continue
		else
			break
		fi
	done
    done
fi
