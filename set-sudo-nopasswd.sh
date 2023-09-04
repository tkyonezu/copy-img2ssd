#!/bin/bash

logmsg() {
  echo ">>> $1"
}

logmsg "Set sudo nopasswd"
echo "rocky ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/010_rocky-nopasswd
sudo chmod 440 /etc/sudoers.d/010_rocky-nopasswd

exit 0
