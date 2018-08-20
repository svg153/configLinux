#!/bin/bash

show_wifi_password_by_ssid(){
  local ssid_tmp=${1}
  local ssid_file_info=$(find /etc/NetworkManager/system-connections -name "*${ssid_tmp}")
  local num_ssid_file_info=$(echo ${ssid_file_info} | wc -l)
  if [[ ${num_ssid_file_info} -ne 1 ]] ; then
    echo "ERROR: More than one matchs"
    echo "${ssid_file_info}"
    exit 1
  fi
  local line_pass=$(sudo cat ${ssid_file_info} | grep "psk=")
  [[ $? -ne 0 ]] && echo "ERROR: Needs sudo to find the pass into the file"
  set -f
  local line_pass_array=(${line_pass//=/ })
  local pass="${line_pass_array[1]}"
  echo ${pass}
};

[[ $# -ne 1 ]] && echo "ERROR: Needs a valid SSID" && exit 1
pass=$(show_wifi_password_by_ssid ${1})
echo ${pass}