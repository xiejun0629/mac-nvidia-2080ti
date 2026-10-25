#!/bin/bash
set -u
APP="/Applications/Install macOS Sequoia.app"
LOG=/Users/user/1401-work/startosinstall.log
[ -x "$APP/Contents/Resources/startosinstall" ] || { echo "NO-APP"; exit 1; }
[ -e /System/Volumes/Data/macOS\ Install\ Data ] && { echo "MID-EXISTS-ABORT"; exit 2; }
sudo -n pmset -a sleep 0 disksleep 0 displaysleep 0 || { echo "SUDO-FAIL"; exit 3; }
sudo -n nohup "$APP/Contents/Resources/startosinstall" --agreetolicense --nointeraction >"$LOG" 2>&1 &
echo "STARTED pid=$! log=$LOG $(date '+%F %T')"
