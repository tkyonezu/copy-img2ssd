#!/bin/bash

logmsg() {
  echo ">>> $1"
}

logmsg "Set sudo nopasswd"
echo "${USER} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/010_${USER}-nopasswd
sudo chmod 440 /etc/sudoers.d/010_${USER}-nopasswd

exit 0
