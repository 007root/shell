#!/bin/bash

echo "port range: 1.9001-9004 2.6001-6004 3.7001-7004"
read -p "choice port number: " port_num
read -p "ssh_ip: " ssh_ip
read -p "ServerId: " ser_id
read -p "ServerName: game01...: " ser_name
read -p "ser_ip_port: " ser_ip_port
read -p "game_mysql_addr: " game_mysql_addr
read -p "game_mysql_user: " game_mysql_user
read -p "game_mysql_passwd: " game_mysql_passwd
read -p "game_mysql_databases: " game_mysql_db


TIM=`date +%F`
remote_work_dir=/gameService/work
alias SSH='ssh $ssh_ip'

case $port_num in
1)
	port_range=(9001 9002 9003 9004)
	;;
2)
	port_range=(6001 6002 6003 6004)
	;;
3)
	port_range=(7001 7002 7003 7004)
	;;
*)
	echo  "Cant't find range number"
	exit 1
	;;
esac

# check serverId
NUM="^2[0-9]{4}$"
if [[ $ser_id =~ $NUM ]]; then :
else
	echo 'Please input server id 20000-29999'
	exit 2
fi

# check game name
NAME='^game[0-9]{2,3}$'
if [[ $ser_name =~ $NAME  ]]; then :
else
	echo 'Name format: game01 game02 ...'
	exit 3
fi

# check source dir
if [ ! -d ./GameService  ]; then
	echo -e "\033[31mNo such ./GameService directory\033[0m"
	exit 4
fi


ip_re="^((25[0-4]|2[0-4][0-9]|1[0-9][0-9]|[0-9]{1,2})\.){3}(25[0-4]|2[0-4][0-9]|1[0-9][0-9]|[0-9]{1,2})"
# check private IP
if [[ $ssh_ip =~ $ip_re$ ]]; then 
	ip_pre=`echo $ssh_ip | awk -F"." '{print $1}'`
	if [ $ip_pre -ne 192 ] && [ $ip_pre -ne 10 ]; then
		echo -e "\033[31mThe \"ssh_ip\" must be private IP \033[0m"
		exit 5
	fi
else
	echo 'Enter the correct IP address format for "ssh_ip"'
	exit 6
fi
# check public IP
if [[ $ser_ip_port =~ ${ip_re}:[0-9]{4} ]]; then 
	ip_pre=`echo $ser_ip_port | awk -F":" '{print $1}' | awk -F"." '{print $1}'`
	if [ $ip_pre -eq 192 ] || [ $ip_pre -eq 10 ] || [ $ip_pre -eq 127 ] || [ $ip_pre -ge 224 ]; then
		echo -e "\033[31mThe \"ser_ip_port\" must be public IP \033[0m"
		exit 7
	fi
else
	echo 'Enter the correct IP address format for "ser_ip_port"'
	exit 8
fi

# check port 
if [ `SSH "test -d /gameService";echo $?` -eq 0 ]; then
	remote_port=`SSH "find /gameService -maxdepth 2 -type d" | grep -oE '[0-9]{4}$'`
	for port in ${port_range[@]}
	do
		for rport in $remote_port
		do
			if [ $port == $rport ]; then
				echo -e "\033[31mPort range ${port_range[@]} exist...\033[0m"
				exit 9
			fi
		done
	done
fi


nginx_bin=/usr/local/nginx/sbin/nginx
nginx_conf=/usr/local/nginx/conf/nginx.conf

#ser_id=20002
#ser_name=game02
#ser_ip_port=192.168.1.139:8002
#game_mysql_user=root
#game_mysql_passwd=root
#game_mysql_db=game02
#game_mysql_addr=192.168.1.139

acc_mysql_addr=192.168.1.30
acc_mysql_user=root
acc_mysql_passwd=root

# Update mysql account databases
ser_conf_sql="{\"mysql\":{\"host\":\"$game_mysql_addr\",\"port\":3306,\"user\":\"$game_mysql_user\",\"password\":\"$game_mysql_passwd\",\"database\":\"$game_mysql_db\",\"connectionLimit\":32}}"
ser_stat_sql='{"tag":1,"status":0,"version":"0.0.0.0","order":4,"pkgversion":0}'
create_time=`date "+%F %T"`
sql_stat=`mysql -h $acc_mysql_addr -u$acc_mysql_user -p$acc_mysql_passwd -e "insert into 02Acc.GameService (Id,CreateTime,Name,Address,Status,ServerConfig)values( \
$ser_id,'$create_time','$ser_name','$ser_ip_port','$ser_stat_sql','$ser_conf_sql')";echo $?`
if [ $sql_stat -ne 0 ]; then
	exit 10
fi



# Add nginx upstream 
flag=1
SSH "sed -i '/gameservice begin/i@\tupstream $ser_name {' $nginx_conf"
for port in ${port_range[@]}
do
	if [ $flag -le 2 ]; then
		SSH "sed -i '/gameservice begin/i@\t\tserver $ssh_ip:$port;' $nginx_conf"
	else
		SSH "sed -i '/gameservice begin/i@\t\t#server $ssh_ip:$port;' $nginx_conf"
	fi
	let flag+=1
done
SSH "sed -i '/gameservice begin/i@\t}' $nginx_conf"
wlan_port=`echo $ser_ip_port | awk -F":" '{print $2}'`
# Add nginx server
SSH "sed -i '/gameservice end/i@\tserver {' $nginx_conf"
SSH "sed -i '/gameservice end/i@\t\tlisten $wlan_port;' $nginx_conf"
SSH "sed -i '/gameservice end/i@\t\tlocation / {' $nginx_conf"
SSH "sed -i '/gameservice end/i@\t\t\tproxy_pass http://$ser_name;' $nginx_conf"
SSH "sed -i '/gameservice end/i@\t\t\tproxy_set_header U-Remote-Endpoint \$remote_addr:\$remote_port;' $nginx_conf"
SSH "sed -i '/gameservice end/i@\t\t\tproxy_set_header Host \$http_host;' $nginx_conf"
SSH "sed -i '/gameservice end/i@\t\t\tproxy_set_header Connection \"\";' $nginx_conf"
SSH "sed -i '/gameservice end/i@\t\t}' $nginx_conf"
SSH "sed -i '/gameservice end/i@\t}' $nginx_conf"
SSH "sed -i 's/^@/ /' $nginx_conf"
if [ `SSH "$nginx_bin -t -c $nginx_conf";echo $?` -ne 0  ];then
	echo -e "\033[31mNginx config test faild\033[0m"
else
	SSH "$nginx_bin -s reload"
fi


# def check service func
CheckService() {
                if [[ -n $stat_flag || -z $log_flag ]]; then
                        scp $ssh_ip:/root/.forever/$remote_up_uid.log . &> /dev/null
                        SSH "forever stop $remote_up_uid"
                        echo -e "\033[31m${ser_name}_$dir Service update faild. Information `pwd`/$remote_up_uid.log \033[0m"
                        continue
                else
                        echo -e "\033[32m${ser_name}_$dir Service update successful :) ....\033[0m"
                fi
        }
# Copy gameservice files and start service
if [ `SSH "test -d $remote_work_dir";echo $?` -ne 0 ]; then
	SSH "mkdir -p $remote_work_dir"
fi

scp -r GameService/* $ssh_ip:$remote_work_dir > /dev/null
SSH "cp /gameService/work/gameService.conf{.tmpl,}"
SSH "sed -i '2i\"host\": \"$ssh_ip\",' /gameService/work/gameService.conf"
SSH "sed -ri 's/(\"gameServiceId\":)(.*)/\1 $ser_id/' /gameService/work/gameService.conf"
SSH "sed -ri 's/(\"ServerOpenTime\":\")(.*)(00:00:.*)/\1$TIM \3/' /gameService/work/gameService.conf"

flag=1
for dir in ${port_range[@]}
do
	if [ $flag -le 2  ]; then
		# Before the start of two service
		let flag+=1
		echo -e "\033[32m Copy file to $dir and start ${ser_name}_$dir service... \033[0m"
		SSH  "mkdir -p /gameService/$ser_name/$dir"
		SSH "cp -r /gameService/work/* /gameService/$ser_name/$dir"
		SSH "sed -ri '3s/(\"port\":)(.*)/\1 $dir,/' /gameService/$ser_name/$dir/gameService.conf"
		SSH "cd /gameService/$ser_name/$dir && node gameService updatedb &>/dev/null"
		SSH "cd /gameService/$ser_name/$dir && forever start gameService ${ser_name}_$dir &>/dev/null"
		sleep 1
		remote_up_uid=`SSH "forever --no-colors list | grep ${ser_name}_$dir" | awk '{print $3}'`
		log_flag=`SSH "cat /root/.forever/${remote_up_uid}.log | grep -o '$ssh_ip:$dir'"`
		stat_flag=`SSH "forever --no-colors list | grep ${ser_name}_$dir | grep -i stopped"`
		CheckService
	else
		echo -e "\033[32m Copy file to $dir ...\033[0m"
		SSH  "mkdir -p /gameService/$ser_name/$dir"
		SSH "cp -r /gameService/work/* /gameService/$ser_name/$dir"
		SSH "sed -ri '3s/(\"port\":)(.*)/\1 $dir,/' /gameService/$ser_name/$dir/gameService.conf"
		
	fi
done



