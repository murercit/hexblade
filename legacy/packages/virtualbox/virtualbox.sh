#!/bin/bash -xe

cmd_clean() {
  rm -rf target || true
  [[ ! -d target ]]
}

cmd_guest_group() {
  usermod -aG vboxsf "${1?'uername'}"
}

cmd_host_group() {
  usermod -aG vboxusers "${1?'username'}"
}

cmd_guest_dir() {
    mkdir -p /var/hexblade/shared
    chown -R root:vboxsf /var/hexblade

    if [[ "x$hexblade_user" != "x" ]]; then
      cmd_guest_group "$hexblade_user"
    elif [[ "x$UID" == "x0" && "x$SUDO_USER" != "x" && "x$SUDO_UID" != "x0" ]]; then
      cmd_guest_group "$SUDO_USER"
    elif [[ "x$UID" != "x0" ]]; then
      cmd_guest_group "$USER"
    fi 
}

cmd_guest_text() {
    apt -y install virtualbox-guest-dkms virtualbox-guest-utils
}

cmd_guest_gui() {
    apt -y install virtualbox-guest-x11
}

cmd_guest() {
    cmd_guest_text
    cmd_guest_dir
    cmd_guest_gui
}

cmd_install() {
  cmd_clean || true
  mkdir -p target/virtualbox

  apt install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg-agent \
      software-properties-common

  mkdir -p /etc/apt/hardkeys
  curl -fsSL https://www.virtualbox.org/download/oracle_vbox.asc | gpg --dearmor > /etc/apt/hardkeys/oracle_vbox.gpg
  curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | gpg --dearmor > /etc/apt/hardkeys/oracle_vbox_2016.gpg

  echo "deb [signed-by=/etc/apt/hardkeys/oracle_vbox.gpg,/etc/apt/hardkeys/oracle_vbox_2016.gpg] http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | tee /etc/apt/sources.list.d/virtualbox.list
  echo "# deb-src [signed-by=/etc/apt/hardkeys/oracle_vbox.gpg,/etc/apt/hardkeys/oracle_vbox_2016.gpg] http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | tee -a /etc/apt/sources.list.d/virtualbox.list

  apt -y update
  apt-cache search virtualbox | grep ^virtualbox
  apt install -y virtualbox-6.1 dkms

  if [[ "x$hexblade_user" != "x" ]]; then
    cmd_host_group "$hexblade_user"
  elif [[ "x$UID" == "x0" && "x$SUDO_USER" != "x" && "x$SUDO_UID" != "x0" ]]; then
    cmd_host_group "$SUDO_USER"
  elif [[ "x$UID" != "x0" ]]; then
   cmd_host_group "$USER"
  fi

  # Install usb 30 support extention: https://www.virtualbox.org/wiki/Downloads
  wget --progress=dot -e dotbytes=64K -c \
    -O target/virtualbox/Oracle_VM_VirtualBox_Extension_Pack.vbox-extpack \
    'https://download.virtualbox.org/virtualbox/6.1.18/Oracle_VM_VirtualBox_Extension_Pack-6.1.18.vbox-extpack'
  vboxmanage extpack install \
    target/virtualbox/Oracle_VM_VirtualBox_Extension_Pack.vbox-extpack \
    --accept-license=33d7284dc4a0ece381196fda3cfe2ed0e1e8e7ed7f27b9a9ebc4ee22e24bd23c || true

  cmd_clean
}

cd "$(dirname "$0")"; _cmd="${1?"cmd is required"}"; shift; "cmd_${_cmd}" "$@"
