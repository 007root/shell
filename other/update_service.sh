#!/bin/bash

echo -e "ServerName:\033[32m accountService gameService chargeService updateService gmtools manage\033[0m"
read -p "Input the service name for update: " ser_name

if [ -z $ser_name ]; then
	echo -e "\033[31mNo Input\033[0m"
	exit 1
fi

remote_ip="192.168.1.138"
game_stop_port="9001"
acc_stop_port="8006"
charge_stop_port="8004"
gmtools_stop_port="4003"
manage_stop_port="4002"
update_stop_port="8100"
remote_dir="/home/$ser_name"
nginx_config=/etc/nginx/nginx.conf

alias SSH="ssh $remote_ip"
alias nginx_reload="/etc/nginx/sbin/nginx -s reload"


#################  Get running info    #######################
remote_run_port=`SSH "forever --no-colors list | grep $ser_name" | awk '{print $6}'`
if [[ `SSH "grep "Name:" /proc/$remote_run_port/status &>/dev/null ; echo $?"` -ne 0  ]]; then
	echo -e "\033[31mCan't find need update service\033[0m"
	exit 4
fi
remote_run_uid=`SSH "forever --no-colors list | grep $ser_name" | awk '{print $3}'`

################  Set update info      ######################
if [ $ser_name == "gameService" ]; then
	if [ $remote_run_port == $game_stop_port ]; then
		stop_port="9002"
	else
		stop_port=$game_stop_port
	fi
	src_dir="GameService"
elif [ $ser_name == "accountService" ]; then
	if [ $remote_run_port == $acc_stop_port ]; then
		stop_port="8007"
	else
		stop_port=$acc_stop_port
	fi
	src_dir="AccountService"
elif [ $ser_name == "chargeService" ]; then
	if [ $remote_run_port == $charge_stop_port ]; then
		stop_port="8005"
	else
		stop_port=$charge_stop_port
	fi
	src_dir="ChargeService"
elif [ $ser_name == "gmtools" ]; then
	if [ $remote_run_port == $gmtools_stop_port ]; then
		stop_port="4004"
	else
		stop_port=$gmtools_stop_port
	fi
	src_dir=$ser_name
elif [ $ser_name == "manage" ]; then
	if [ $remote_run_port == $manage_stop_port ]; then
		stop_port="4001"
	else
		stop_port=$manage_stop_port
	fi
	src_dir=$ser_name
elif [ $ser_name == "updateService" ]; then
	if [ $remote_run_port == $update_stop_port ]; then
		stop_port="8101"
	else
		stop_port=$update_stop_port
	fi
	src_dir="UpdateService"
fi

################    Check Directory    ######################
if [ `SSH "[ -e $remote_dir ]" ; echo $?` -ne 0 ]; then
	echo -e "\033[31mCan't find input service\033[0m"	
	exit 2
#elif [ ! -d ./`echo $ser_name | sed 's/[a-z]/\U&/'` ]; then
elif [ ! -d ./$src_dir ]; then
	echo -e "\033[31mCan't find the source service dir\033[0m"
	exit 3
fi


####################  Confirm  #######################
echo -e "\033[31msource_dir:\033[0m`pwd`/$src_dir, \033[31mdestination:\033[0m$remote_ip:$remote_dir, \033[31mupdate\033[0m $ser_name"
read -p "Please confirm (y/n) " confirm
if [[ $confirm != "y" || -z $confirm ]]; then
	exit 5
fi

####################    Main      #####################
CheckService() {
	if [[ -n $stat_flag || -z $log_flag ]]; then
		scp $remote_ip:/root/.forever/$remote_up_uid.log . &> /dev/null
		SSH "forever stop $remote_up_uid"
		echo -e "\033[31m$ser_name Service update faild. Information `pwd`/$remote_up_uid.log \033[0m"
	else
		sed -i "s/#server $remote_ip:$stop_port/server $remote_ip:$stop_port/" $nginx_config
		sed -i "s/server $remote_ip:$remote_run_port/#server $remote_ip:$remote_run_port/" $nginx_config
		nginx_reload
		echo -e "\033[32m$ser_name Service update successful :) ....\033[0m"
		SSH "forever stop $remote_run_uid" &> /dev/null
	fi
}
StartService() {
	echo -e "\033[31mSTART SERVICE ...\033[0m"
	SSH "cd $remote_dir/$stop_port/ && forever start $ser_name $stop_port" &> /dev/null
	sleep 1
}


echo -e "\033[31mCOPY FILES ... \033[0m"
scp -r  ./$src_dir/* $remote_ip:$remote_dir/$stop_port/ &> /dev/null

if [[ $ser_name == "accountService" || $ser_name == "gameService" ]]; then
	echo -e "\033[31mUPDATEDB ...\033[0m"
	SSH "cd $remote_dir/$stop_port/ && node $ser_name updatedb" &> /dev/null
	sleep 1

	# start service	
	StartService

	# check service
	echo -e "\033[31mCHECK SERVICE ...\033[0m"
	remote_up_uid=`SSH "forever --no-colors list | grep $stop_port" | awk '{print $3}'`
	log_flag=`SSH "cat /root/.forever/${remote_up_uid}.log | grep -o '$remote_ip:$stop_port'"`
	stat_flag=`SSH "forever --no-colors list | grep $stop_port | grep -i stopped"`
	CheckService 
elif [[ $ser_name == "gmtools" || $ser_name == "manage" ]];then

	# start service
	StartService
	
	remote_up_uid=`SSH "forever --no-colors list | grep $stop_port" | awk '{print $3}'`
	log_flag=`SSH "cat /root/.forever/${remote_up_uid}.log | grep -o 'listening on port $stop_port'"`
	stat_flag=`SSH "forever --no-colors list | grep $stop_port | grep -i stopped"`
	CheckService
elif [ $ser_name == "updateService" ]; then

	# start service	
	StartService
	
	remote_up_uid=`SSH "forever --no-colors list | grep $stop_port" | awk '{print $3}'`
	log_flag=`SSH "cat /root/.forever/${remote_up_uid}.log | grep -o 'begin start server'"`
	stat_flag=`SSH "forever --no-colors list | grep $stop_port | grep -i stopped"`
	CheckService
elif [ $ser_name == "chargeService" ]; then

	# start service	
	StartService
	
	remote_up_uid=`SSH "forever --no-colors list | grep $stop_port" | awk '{print $3}'`
	log_flag=`SSH "cat /root/.forever/${remote_up_uid}.log | grep -o 'info: service start'"`
	stat_flag=`SSH "forever --no-colors list | grep $stop_port | grep -i stopped"`
	CheckService
fi




