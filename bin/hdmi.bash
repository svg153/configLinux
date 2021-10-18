#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# TODO: https://askubuntu.com/questions/630202/run-script-when-monitor-is-connected
# TODO: https://bbs.archlinux.org/viewtopic.php?id=195300

hdmi_on(){
    sudo sed -i 's/^IgnoreLid=.*/IgnoreLid=true/' /etc/UPower/UPower.conf
    sudo systemctl restart upower.service
}

hdmi_off(){
    sudo sed -i 's/^IgnoreLid=.*/IgnoreLid=false/' /etc/UPower/UPower.conf
    sudo systemctl restart upower.service
}

hdmi_connected=$(xrandr | grep HDMI | wc -l)
if [[ ${hdmi_connected} -eq 1 ]]; then
    hdmi_on
else
    hdmi_off
fi