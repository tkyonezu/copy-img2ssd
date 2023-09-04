#!/bin/bash

logmsg() {
  echo ">>> $1"
}

logmsg "Start Set Japanese"

logmsg "Install Japanese packages"
sudo dnf install -y glibc-langpack-ja langpacks-ja

logmsg "Set System Locale to Japanese"
sudo localectl set-locale LANG=ja_JP.utf8

logmsg "Set Japanese Keyboard"
sudo localectl set-keymap jp

logmsg "Set Japanese Time zone"
sudo timedatectl set-timezone Asia/Tokyo

logmsg "End of Set Japanese"

exit 0
