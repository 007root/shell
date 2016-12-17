#!/bin/bash


game_dir=`ps aux | grep gameService | grep home | awk  '{print $12}' | awk -F "/game" '{print $1}'`
log_dir=/home/log

for dir in $game_dir
do
	internal_dir=`echo $dir | awk -F "/" '{print $3}'`
	file_count=`ls ${log_dir}/${internal_dir}/*.zip | grep -oE '[0-9]{8}' |wc -l`
	file_date=`ls -t ${log_dir}/${internal_dir}/*.zip | grep -oE '[0-9]{8}'`
	if [ $file_count -gt 3 ]; then
		file_list=()
		for i in $file_date
		do
			file_list[${#file_list[*]}]=$i
		done
		for d in ${file_list[@]:3}
		do
			rm -rf ${log_dir}/${internal_dir}/game$d.zip
		done
	fi

done

