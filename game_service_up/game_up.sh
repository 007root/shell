#!/bin/bash

nginx_config=/etc/nginx/nginx.conf
alias nginx_reload="/etc/nginx/sbin/nginx -s reload"
#remote_ip="192.168.1.138"

remote_ip=$1
ser_name=($2 $3)
alias SSH="ssh $remote_ip"


if [ -z "$ser_name" ]; then
	echo -e "\033[31mNo Input\033[0m"
	exit 1
fi


for ser_name in ${ser_name[@]}
do

	remote_dir="/gameService/$ser_name"
	
	################  Get running info    #######################
	unset stop_port
	stop_port=`SSH "ls $remote_dir 2>/dev/null" | grep -oE "[0-9]{4}"`
	remote_run_port=`SSH "forever --no-colors list | grep $ser_name" | awk '{print $6}' | awk -F"_" '{print $2}'`
	remote_run_uid=`SSH "forever --no-colors list | grep $ser_name" | awk '{print $3}'`
	################    Check Directory & Service   ######################
	if [ -z "$stop_port" ]; then
		echo -e "\033[31mCan't update $ser_name gameService...\033[0m"
		echo -e "\033[31mNo such remote dir:$remote_dir\033[0m"	
		continue
	elif [ -z "$remote_run_port" ]; then
		echo -e "\033[31mCan't find need update $ser_name service \033[0m"
		continue
	elif [ ! -d ./GameService ]; then
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
			echo -e "\033[32mStart update $ser_name ......\033[0m"
			tag=False
		fi
		echo -e "\033[32mCopy files to $remote_dir/$dir \033[0m"
		scp -r  ./GameService/* $remote_ip:$remote_dir/$dir &> /dev/null
	done
	
	
	####################    Main      #####################
	CheckService() {
		if [[ -n $stat_flag || -z $log_flag ]]; then
			scp $remote_ip:/root/.forever/$remote_up_uid.log . &> /dev/null
			SSH "forever stop $remote_up_uid"
			echo -e "\033[31m$ser_name Service update faild. Information `pwd`/$remote_up_uid.log \033[0m"
			break
		else
			echo -e "\033[32m${ser_name}_$up Service update successful :) ....\033[0m"
			let count+=1
		fi
	}
	StartService() {
		echo -e "\033[32mSTART SERVICE ...\033[0m"
		SSH "cd $remote_dir/$up/ && forever start gameService ${ser_name}_$up" &>/dev/null
		sleep 1
	}
	
	flag=True
	count=0
	for up in ${stop_port[@]}
	do
		if [ $flag == "True" ]; then
			echo -e "\033[32mUPDATEDB ...\033[0m"
			SSH "cd $remote_dir/$up/ && node gameService updatedb" &> /dev/null
			flag=False
			sleep 1
		fi
		# start service	
		StartService
		# check service
		echo -e "\033[32mCHECK SERVICE ...\033[0m"
		remote_up_uid=`SSH "forever --no-colors list | grep ${ser_name}_$up" | awk '{print $3}'`
		log_flag=`SSH "cat /root/.forever/${remote_up_uid}.log | grep -o '$remote_ip:$up'"`
		stat_flag=`SSH "forever --no-colors list | grep ${ser_name}_$up | grep -i stopped"`
		CheckService 
	done
	
	if [ $count -eq 2 ]; then
		for port in ${stop_port[@]}
		do
			sed -i "s/#server $remote_ip:$port/server $remote_ip:$port/" $nginx_config
		done
		for port in ${remote_run_port[@]}
		do
			sed -i "s/server $remote_ip:$port/#server $remote_ip:$port/" $nginx_config
		done
		nginx_reload
		for uid in ${remote_run_uid[@]}
		do
			SSH "forever stop $uid" &>/dev/null
		done
	else
		for port in ${stop_port[@]}
		do
			stop_uid=`SSH "forever list --no-colors | grep ${ser_name}_$port" | awk '{print $3}'`
			if [  -n "$stop_uid" ]; then
				SSH "forever stop $stop_uid" &>/dev/null
			fi
		done
		echo "$ser_name update roullback"
	fi
done




