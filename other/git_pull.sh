#/bin/bash


cd /home/mirror
agent=`ls /tmp/ssh-*/* 2>/dev/null | head -1`
if [[ ! -z $agent ]];then
    echo "SSH_AUTH_SOCK=$agent; export SSH_AUTH_SOCK;" > /tmp/agent.cf
else
    ssh-agent -s | head -n 1 > /tmp/agent.cf
fi
source /tmp/agent.cf
ssh-add
export LC_ALL=C

while IFS= read -r -d $'\0' REPO_DIR; do
    pushd $REPO_DIR
    echo -n "$(date +"%F %T") "
    echo -n "$REPO_DIR "
    /usr/bin/git remote update
    popd
done < <(find repos/ -name *.git -print0)
