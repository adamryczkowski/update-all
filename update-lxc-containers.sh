#!/bin/bash

if ! which lxc >/dev/null; then
    exit 0 #no containers
fi

lxc list 2>/dev/null >/dev/null

if [ ! $? -eq 0 ]; then
    echo "Error in executing lxc list. Perhaps lxc was not installed properly" >/dev/stderr
    exit 0 #error when accessing containers. We are not going to fix it here, so just return.
fi


lxc_list_stopped=$(lxc list --format csv | grep -E '^[^,]+,STOPPED' | grep -o -E '^[^,]+')

lxc_list_running=( $(lxc list --format csv | grep -E '^[^,]+,RUNNING' | grep -o -E '^[^,]+') )

function update_running_lxc {
    local lxc_name=$1
    ips=( $(lxc list -c4 --format csv $lxc_name | sed -E "s/ \([^\)]+\) ?//g") )
    
    for ip in "${ips[@]}"; do
        if ssh -o PreferredAuthentications=publickey ${ip} /bin/true >/dev/null; then
            install_run_update_all ${ip} ${lxc_name}
            break
        fi
    done   
}

function install_run_update_all {
    local ip=$1
    local lxc_name=$2
    local homedir=$(ssh $ip pwd)
    if ! [ $? -eq 0 ]; then
        return 1; # cannot access the container
    fi
    homedir="${homedir}/tmp/update-all"

    if ! ssh $ip ls "${homedir}/.git" 2>/dev/null >/dev/null; then
        ssh $ip mkdir -p "${homedir}" 
        for file in $(pwd)/*.sh; do
            lxc file push "${file}" "$2/${homedir}/"
        done
    fi
    ssh $ip "cd $homedir; ./update-all.sh"
}


for lxc_name in "${lxc_list_running[@]}"; do
    update_running_lxc "${lxc_name}"
done

