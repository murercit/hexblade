#!/bin/bash -xe

function cmd_vm_delete  () {
    local hex_vm_name="${1?'vm_name'}"
    [[ -d "/mnt/hexblade/vbox/$hex_vm_name" ]]
    VBoxManage unregistervm --delete "$hex_vm_name" || true
    find "/mnt/hexblade/vbox/$hex_vm_name" -name "disk*.vmdk" | while read k; do
        VBoxManage closemedium disk "$k" --delete || true
    done
    rmdir "/mnt/hexblade/vbox/$hex_vm_name"
}

function cmd_vm_create_from_iso() {
    local hex_vm_iso="${1?'vm_iso'}"
    local hex_vm_name="${2?'vm_name'}"
    [[ ! -d "/mnt/hexblade/vbox/$hex_vm_name" ]]
    mkdir -p /mnt/hexblade/vbox
    VBoxManage createvm --name "$hex_vm_name" --ostype "Ubuntu_64" --register --basefolder "/mnt/hexblade/vbox/$hex_vm_name"
    VBoxManage modifyvm "$hex_vm_name" --ioapic on          
    VBoxManage modifyvm "$hex_vm_name" --memory 2048 --vram 128      
    VBoxManage modifyvm "$hex_vm_name" --nic1 nat
    VBoxManage createhd --filename "/mnt/hexblade/vbox/$hex_vm_name/disk1.vmdk" --size 80000 --format VMDK              
    VBoxManage storagectl "$hex_vm_name" --name "SATA" --add sata --controller IntelAhci --portcount 1
    VBoxManage storageattach "$hex_vm_name" --storagectl "SATA" --port 0 --device 0 --type hdd --medium  "/mnt/hexblade/vbox/$hex_vm_name/disk1.vmdk"                
    VBoxManage storagectl "$hex_vm_name" --name "IDE" --add ide --controller PIIX4       
    VBoxManage storageattach "$hex_vm_name" --storagectl "IDE" --port 1 --device 0 --type dvddrive --medium "$hex_vm_iso"       
    VBoxManage modifyvm "$hex_vm_name" --boot1 dvd --boot2 disk --boot3 none --boot4 none 
    VBoxManage modifyvm "$hex_vm_name" --cpus 2
}

function cmd_vm_start() {
    local hex_vm_name="${1?'vm_name'}"
    VBoxManage startvm "$hex_vm_name" --type gui -E AAA=BBB
    if ! VBoxManage guestproperty wait "$hex_vm_name" "/VirtualBox/GuestInfo/OS/LoggedInUsers" --timeout 180000 --fail-on-timeout; then
        VBoxManage controlvm "$hex_vm_name" poweroff || true
        false
    fi
}

function cmd_vm_exec() {
    local hex_vm_name="${1?'vm_name'}"
    local hex_vm_exe="${2?'file to exec'}"
    local hex_vm_timeout="${3?'vm_timeout_ms'}"
    VBoxManage guestcontrol "$hex_vm_name" --username ubuntu --password ubuntu run --timeout "$hex_vm_timeout" --wait-stdout --wait-stderr -- /usr/bin/chmod -v +x "/tmp/file"
}

function cmd_vm_upexec() {
    local hex_vm_name="${1?'vm_name'}"
    local hex_vm_file="${2?'file to exec'}"
    VBoxManage guestcontrol "$hex_vm_name" --username ubuntu --password ubuntu copyto --follow "$hex_vm_file" "/tmp/file"
    VBoxManage guestcontrol "$hex_vm_name" --username ubuntu --password ubuntu run --timeout 2000 --wait-stdout --wait-stderr -- /usr/bin/chmod -v +x "/tmp/file"
    VBoxManage guestcontrol "$hex_vm_name" --username ubuntu --password ubuntu run --exe "/tmp/file" --timeout 300000 -E x1=x2 --wait-stdout --wait-stderr
}

set +x; cd "$(dirname "$0")"; _cmd="${1?"cmd is required"}"; shift; set -x; "cmd_${_cmd}" "$@"