#!/bin/bash -xe


function cmd_lvm_format() {
    local hexblade_lvm_dev="${1?'hexblade_lvm_dev'}"
    local hexblade_lvm_name="${2?'hexblade_lvm_name'}"
    mkfs.ext4 -L "$hexblade_lvm_name" "$hexblade_lvm_dev"
    pvcreate -f "$hexblade_lvm_dev"
    vgcreate "$hexblade_lvm_name" "$hexblade_lvm_dev"
}

function cmd_lvm_add() {
    local hexblade_lvm_name="${1?'hexblade_lvm_name'}"
    local hexblade_lvm_subname="${2?'hexblade_lvm_subname'}"
    local hexblade_lvm_size="${3?'hexblade_lvm_size, use 100%FREE to all free space'}"
    if echo "$hexblade_lvm_size" | grep 'FREE$'; then
        lvcreate -l "$hexblade_lvm_size" "$hexblade_lvm_name" -n "$hexblade_lvm_subname"
    else
        lvcreate -L "$hexblade_lvm_size" "$hexblade_lvm_name" -n "$hexblade_lvm_subname"
    fi
}

set +x; cd "$(dirname "$0")"; _cmd="${1?"cmd is required"}"; shift; set -x; "cmd_${_cmd}" "$@"
