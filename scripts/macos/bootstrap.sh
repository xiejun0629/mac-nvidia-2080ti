#!/bin/bash
# 1401 macOS desktop bootstrap: enable SSH + passwordless sudo + DNS.
# Run in macOS Terminal:  bash /Volumes/OCESP/bootstrap.sh
U="$(id -un)"
KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP8YU9coKJWbv02Zbo8xCHMhjh1Ei4vPPXydWnhNav2P root@user-server'
mkdir -p "$HOME/.ssh"; touch "$HOME/.ssh/authorized_keys"
grep -qF "$KEY" "$HOME/.ssh/authorized_keys" || echo "$KEY" >> "$HOME/.ssh/authorized_keys"
chmod 700 "$HOME/.ssh"; chmod 600 "$HOME/.ssh/authorized_keys"
chown -R "$U" "$HOME/.ssh" 2>/dev/null
echo "KEY-OK"
cat > /tmp/nm1401_root.sh <<'ROOTEOF'
#!/bin/bash
U="$1"
echo "$U ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/1401
chmod 440 /etc/sudoers.d/1401
visudo -cf /etc/sudoers.d/1401 && echo SUDOERS-OK || echo SUDOERS-BAD
systemsetup -setremotelogin on 2>&1
launchctl enable system/com.openssh.sshd 2>&1
launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist 2>&1
launchctl load -w /System/Library/LaunchDaemons/ssh.plist 2>&1
launchctl kickstart -k system/com.openssh.sshd 2>&1
SVC=$(networksetup -listallnetworkservices 2>/dev/null | tail -n +2 | grep -v '^\*' | head -1)
if [ -n "$SVC" ]; then networksetup -setdnsservers "$SVC" 203.0.113.10 203.0.113.10 2>&1; fi
dscacheutil -flushcache 2>&1
if nc -z 127.0.0.1 22 2>/dev/null; then echo PORT22-OPEN; else echo PORT22-CLOSED; fi
ROOTEOF
chmod 755 /tmp/nm1401_root.sh
osascript -e "do shell script \"/bin/bash /tmp/nm1401_root.sh $U\" with administrator privileges"
echo "OSASCRIPT-RC=$?"
sleep 1
echo "--- network ---"
ifconfig | grep 'inet ' | head -4
ping -c 2 -t 2 192.168.1.223 2>&1 | tail -2
if nc -z 127.0.0.1 22 2>/dev/null; then echo "=== SSH-READY ==="; else echo "=== SSH-FAILED ==="; fi
