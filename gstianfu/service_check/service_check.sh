#!/bin/bash

#sleep 20
docker_name=`sudo docker ps  | awk '{print $NF}' | grep -v "NAMES"`
mail_dir=/home/ubuntu/aws/service_check
HOST=`hostname`
mail_title="Error-$HOST"

url_check (){
	url=$1
	name=$2
	stat=0
	http_code=`curl -o /dev/null -s -w %{http_code} $url`	
	if (( $http_code == 000 )); then
		mail_content="Can't access $name $url"
		python $mail_dir/mail.py ${mail_title}-$name $mail_content
		echo $mail_content > ./.${mail_title}-$name
		stat=1
	else	
		if (( $http_code != 200 )); then
			mail_content="Access $name $url $http_code"
			python $mail_dir/mail.py ${mail_title}-$name $mail_content
			echo $mail_content > ./.${mail_title}-$name
			stat=1
		fi
	fi
	
	# send recover mail
	if [[ $stat -eq 0 && -e ./.${mail_title}-$name ]]; then
		err_msg=`cat ./.${mail_title}-$name`
		python $mail_dir/mail.py "Recover-${HOST}-$name" "LastError: $err_msg"
		rm -rf ./.${mail_title}-$name
	fi
} 

for name in $docker_name
do
	# docker exec check
	script_check=`sudo docker exec $name bash -c "[ -e /tmp/check.sh ] && \
						      /bin/bash /tmp/check.sh ||
						      echo 'echo ok' > /tmp/check.sh &&\
						      /bin/bash /tmp/check.sh"`
	if [[ -z $script_check ]]; then
		mail_content="docker exec $name fail..."
		python $mail_dir/mail.py $mail_title $mail_content
	fi
	
	# gezi
	if [[ $name == "gezi" ]]; then

		# gezi program check
		process_count=`sudo docker exec $name bash -c "sudo ps aux | grep 'gezi/wsgi.ini' " | wc -l`
		if (( $process_count != 7 )); then
			mail_content="$name uwsgi is down..."
			python $mail_dir/mail.py $mail_title $mail_content
		fi
	
		# gezi url check
		gezi_url="http://127.0.0.1:9100/test"
		url_check $gezi_url $name

	# gbm_api
	elif [[ $name == "gbm_api" ]]; then
		
		# gbm_api url check
		gbm_api_url="http://127.0.0.1:5001/test"
		url_check $gbm_api_url $name
	fi
done







