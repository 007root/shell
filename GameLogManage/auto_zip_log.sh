#!/bin/bash


DAT=`date +%Y%m%d`
game_dir=`ps aux | grep gameService | grep home | awk  '{print $12}' | awk -F "/game" '{print $1}'`
game_pid=`/usr/local/bin/forever list | grep gameService | awk '{print $3}'`
log_dir=/home/log

# mv file
for dir in $game_dir
do
	internal_dir=`echo $dir | awk -F "/" '{print $3}'`
	if [ ! -d $log_dir/$internal_dir ]; then
		mkdir $log_dir/$internal_dir
	fi

	mv $dir/game*.log $log_dir/$internal_dir

done

# restart service
for id in $game_pid
do
	/usr/local/bin/forever restart $id &>/dev/null
done

# zip file
for dir in $game_dir
do

	internal_dir=`echo $dir | awk -F "/" '{print $3}'`
	zip $log_dir/$internal_dir/game${DAT}.zip $log_dir/$internal_dir/game*.log
	rm -rf $log_dir/$internal_dir/*.log

done





