#!/bin/bash -xe

[[ "x$UID" == "x0" ]]

function cmd_strap() {
    local _hex_mirror="${HEXBLADE_UBUNTU_MIRROR_COUNTRY:-br}"
    debootstrap focal /mnt/hexblade/basesys "http://${_hex_mirror}.archive.ubuntu.com/ubuntu/"

}

function cmd_baseconf() {
    cp -vR etc/* /mnt/hexblade/basesys/etc
    echo 'America/Sao_Paulo' | tee /mnt/hexblade/basesys/etc/timezone
    arch-chroot /mnt/hexblade/basesys ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
    echo 'LANG="en_US.UTF-8"' | tee /mnt/hexblade/basesys/etc/default/locale
    arch-chroot /mnt/hexblade/basesys locale-gen en_US.UTF-8
    echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean false | arch-chroot /mnt/hexblade/basesys debconf-set-selections
    DEBIAN_FRONTEND=noninteractive arch-chroot /mnt/hexblade/basesys dpkg-reconfigure -f non-interactive tzdata
}

function cmd_basepack() {
    arch-chroot /mnt/hexblade/basesys apt -y update
    DEBIAN_FRONTEND=noninteractive arch-chroot /mnt/hexblade/basesys apt -y install ubuntu-standard \
        language-pack-en-base \
        software-properties-common \
        vim wget curl openssl git vim \
        nmap ncat pv zip connect-proxy tcpdump bc \
        network-manager net-tools locales \
        cryptsetup lvm2 btrfs-progs

    echo -e "network:\n  version: 2\n  renderer: NetworkManager" | tee /mnt/hexblade/basesys/etc/netplan/01-netcfg.yaml

    if [[ -d /sys/firmware/efi ]]; then
        arch-chroot /mnt/hexblade/basesys apt -y install grub-efi
    else
        arch-chroot /mnt/hexblade/basesys apt -y install grub-pc
    fi
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="verbose nosplash"' > /mnt/hexblade/basesys/etc/default/grub.d/hexblade-linux-cmdline.cfg
}

function cmd_kernel_def() {
    #DEBIAN_FRONTEND=noninteractive arch-chroot /mnt/hexblade/installer apt -y install "linux-image-5.4.0-54-generic" "linux-headers-5.4.0-54-generic"
    #DEBIAN_FRONTEND=noninteractive arch-chroot /mnt/hexblade/installer apt -y install "linux-image-generic" "linux-headers-generic"
    DEBIAN_FRONTEND=noninteractive arch-chroot /mnt/hexblade/basesys apt -y install --install-recommends linux-generic
}

function cmd_kernel_hwe() {
    DEBIAN_FRONTEND=noninteractive arch-chroot /mnt/hexblade/basesys apt -y install linux-generic-hwe-20.04
}

function cmd_initramfs() {
    arch-chroot /mnt/hexblade/installer update-initramfs -u -k all
}

function cmd_boot() {
    local hexblade_grub_dev="${1?'hexblade_grub_dev is required'}"
    arch-chroot /mnt/hexblade/installer update-grub
    arch-chroot /mnt/hexblade/installer grub-install "$hexblade_grub_dev"
    cmd_initramfs
}

function cmd_install() {
    [[ ! -d /mnt/hexblade/basesys ]]
    mkdir -p /mnt/hexblade/basesys
    mount -t tmpfs -o size=6g tmpfs /mnt/hexblade/basesys
    cmd_strap
    cmd_baseconf
    cmd_basepack
    cmd_kernel_hwe
}

cd "$(dirname "$0")"; _cmd="${1?"cmd is required"}"; shift; "cmd_${_cmd}" "$@"
