#!/bin/bash

file_path=(
	"/home/ubuntu/api"
	"/home/ubuntu/gezi"
	"/home/ubuntu/simu"
)

for dir in ${file_path[@]}
do
	file=`ls -t $dir | egrep "*.zip"`  # 按时间排序获取文件名称
	file_count=`ls $dir | egrep "*.zip" | wc -l` # 获取文件数量

	# 文件数量大于指定天数执行删除操作
	if [ $file_count -gt 3 ]; then   		
		file_list=()
		for i in $file
		do
			file_list[${#file_list[*]}]=$i
		done
		for del in ${file_list[@]:3}
		do
			rm -rf $dir/$del
		done
	fi
done

