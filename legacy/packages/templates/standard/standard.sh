#!/bin/bash -xe


cmd_install() {
    ../../tools/tools.sh install
    ../../firewall/firewall.sh install_deny

    ../../graphics/graphics.sh xterm
    
    ../../lxterminal/lxterminal.sh install
    
    ../../graphics/graphics.sh mousepad
    ../../graphics/graphics.sh xfce4-screenshooter
    ../../graphics/graphics.sh pcmanfm
    ../../graphics/graphics.sh firefox

    ../../graphics/graphics.sh network-manager-gnome

    ../../sound/sound.sh pulseaudio

    ../../openbox/openbox.sh install
    ../../lxdm/lxdm.sh install
}

cd "$(dirname "$0")"; _cmd="${1?"cmd is required"}"; shift; "cmd_${_cmd}" "$@"
