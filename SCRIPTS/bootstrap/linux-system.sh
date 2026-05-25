#!/usr/bin/env bash

function install_drivers()
{
    install firmware-linux lshw

    intel=$(lshw | grep CPU | grep Intel | wc -l)
    [[ ${intel} -gt 0 ]] && install intel-microcode
    amd=$(lshw | grep CPU | grep amd | wc -l)
    [[ ${amd} -gt 0 ]] && install amd64-microcode

    isATI=$(lspci -nn | grep VGA | grep ATI | wc -l)
    [[ ${isATI} -ne 0 ]] && install firmware-linux-nonfree libgl1-mesa-dri xserver-xorg-video-ati

    install firmware-realtek

    install wpasupplicant wireless-tools network-manager
    install network-manager-gnome

    unclaimed=$(sudo lshw | grep UNCLAIMED)
    c=$(echo ${unclaimed} | wc -l)
    [[ ${c} -ne 0 ]] && echo "Drivers UNCLAIMED" && echo "${unclaimed}" && exit 1

    unclaimed=$(sudo lspci | grep UNCLAIMED)
    c=$(echo ${unclaimed} | wc -l)
    [[ ${c} -ne 0 ]] && echo "Drivers UNCLAIMED" && echo "${unclaimed}" && exit 1

    install \
        libavcodec-extra \
        ffmpeg

    install \
        pavucontrol

    install \
        bluetooth \
        pulseaudio-module-bluetooth \
        bluewho \
        blueman \
        bluez
}