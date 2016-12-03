#!/bin/bash

echo -e "ServerName:\033[32msanguo sanguo01 wow\033[0m"
read -p "Input the service name for update: " ser_name


nginx_config=/etc/nginx/nginx.conf
alias nginx_reload="/etc/nginx/sbin/nginx -s reload"
remote_ip="192.168.1.138"


if [ -z "$ser_name" ]; then
	echo -e "\033[31mNo Input\033[0m"
	exit 1
fi


for ser_name in ${ser_name[@]}
do
	remote_dir="/home/accountService/$ser_name"
	
	################  Get running info    #######################
	unset stop_port
	stop_port=`ls $remote_dir 2>/dev/null | grep -oE "[0-9]{4}"`
	remote_run_port=`forever --no-colors list | grep ${ser_name}_ | awk '{print $6}' | awk -F"_" '{print $2}'`
	remote_run_uid=`forever --no-colors list | grep ${ser_name}_ | awk '{print $3}'`
	################    Check Directory & Service   ######################
	if [ -z "$stop_port" ]; then
		echo -e "\033[31mCan't update $ser_name accountService...\033[0m"
		echo -e "\033[31mCan't find remote dir:$remote_dir\033[0m"	
		continue
	elif [ -z "$remote_run_port" ]; then
		echo -e "\033[31mCan't find need update $ser_name service \033[0m"
		continue
	elif [ ! -d ./AccountService ]; then
		echo -e "\033[31mCan't update $ser_name accountService...\033[0m"
		echo -e "\033[31mCan't find the source service dir\033[0m"
		continue
	fi
	
	###############     Copy files       #######################
	for run_port in ${remote_run_port[@]}
	do
		stop_port=(${stop_port[@]/$run_port/})
	done
	
	tag=True
	for dir in ${stop_port[@]}
	do
		if [ $tag == "True" ]; then
			echo -e "\033[32mStart update $ser_name accountService...\033[0m"
			tag=False
		fi
		echo -e "\033[32mCopy files to $remote_dir/$dir \033[0m"
		cp -r  ./AccountService/* $remote_dir/$dir &> /dev/null
	done
	
	
	####################    Main      #####################
	CheckService() {
		if [[ -n $stat_flag || -z $log_flag ]]; then
			scp $remote_ip:/root/.forever/$remote_up_uid.log . &> /dev/null
			forever stop $remote_up_uid
			echo -e "\033[31m$ser_name Service update faild. Information `pwd`/$remote_up_uid.log \033[0m"
			break
		else
			sed -i "s/#server $remote_ip:$port/server $remote_ip:$port/" $nginx_config
			sed -i "s/server $remote_ip:$remote_run_port/#server $remote_ip:$remote_run_port/" $nginx_config
			nginx_reload
			forever stop $remote_run_uid &>/dev/null
			echo -e "\033[32m${ser_name}_$port Service update successful :) ....\033[0m"
		fi
	}
	StartService() {
		echo -e "\033[32mSTART SERVICE ...\033[0m"
		cd $remote_dir/$port/ && forever start accountService ${ser_name}_$port &>/dev/null
		sleep 1
	}
	
	for port in ${stop_port[@]}
	do
		echo -e "\033[32mUPDATEDB ...\033[0m"
		cd $remote_dir/$port/ && node accountService updatedb &> /dev/null
		sleep 1
		# start service	
		StartService
		# check service
		echo -e "\033[32mCHECK SERVICE ...\033[0m"
		remote_up_uid=`forever --no-colors list | grep ${ser_name}_$port | awk '{print $3}'`
		log_flag=`cat /root/.forever/${remote_up_uid}.log | grep -o '$remote_ip:$port'`
		stat_flag=`forever --no-colors list | grep ${ser_name}_$port | grep -i stopped`
		CheckService 
	done
	
done




