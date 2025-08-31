#!/bin/bash

if ! command -v lxc >/dev/null; then
    exit 0 # no containers
fi

. ./update-snap.sh lib

# Check lxc works
if ! lxc list >/dev/null 2>&1; then
    echo "Error executing lxc list. Perhaps lxc was not installed properly" >/dev/stderr
    exit 0
fi

# Build list of running containers
mapfile -t lxc_list_running < <(lxc list --format csv | grep -E '^[^,]+,RUNNING' | grep -o -E '^[^,]+')

function update_running_lxc {
    local lxc_name="$1"
    mapfile -t ips < <(lxc list -c4 --format csv "$lxc_name" | sed -E 's/ \([^)]*\) ?//g')
    for ip in "${ips[@]}"; do
        if ssh -o PreferredAuthentications=publickey "$ip" /bin/true >/dev/null 2>&1; then
            install_run_update_all "$ip" "$lxc_name"
            break
        fi
    done
}

function install_run_update_all {
    local ip="$1"
    local lxc_name="$2"
    local homedir
    if ! homedir=$(ssh "$ip" pwd); then
        return 1 # cannot access the container
    fi
    homedir="${homedir}/tmp/update-all"

    if ! ssh "$ip" sh -c 'test -d "$1/.git"' _ "$homedir" >/dev/null 2>&1; then
        ssh "$ip" sh -c 'mkdir -p "$1"' _ "$homedir"
        for file in ./*.sh; do
            lxc file push "${file}" "${lxc_name}/${homedir}/"
        done
    fi
    ssh "$ip" sh -c 'cd "$1"; ./update-all.sh' _ "$homedir"
}

host_is_disabled=$(is_host_disabled api.snapcraft.io)
if [ "$host_is_disabled" = "1" ]; then
  echo "Enabling api.snapcraft.io..."
  enable_host api.snapcraft.io 127.0.0.1
fi

for lxc_name in "${lxc_list_running[@]}"; do
    update_running_lxc "${lxc_name}"
done

if [ "$host_is_disabled" = "1" ]; then
  echo "Disabling back api.snapcraft.io..."
  disable_host api.snapcraft.io 127.0.0.1
fi
