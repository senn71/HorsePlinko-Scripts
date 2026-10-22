#!/usr/bin/env bash
# =============================================================================
# harden-ssh.sh  |  BUNDLE: ssh
# PURPOSE : Apply SSH hardening through a drop-in file that loads FIRST
#           (/etc/ssh/sshd_config.d/00-hardening.conf). sshd uses the first value
#           it sees for each setting, so this beats the main file and any
#           drop-in an attacker adds later with a higher number.
# KEEPS   : PasswordAuthentication yes, because scoring logs in with a password.
# SAFETY  : Runs `sshd -t` and only restarts SSH if the config is valid.
#           Keep a second session open; test a NEW login as the scoring user.
# USAGE   : sudo bash harden-ssh.sh
# VERIFY  : sudo sshd -T | grep -Ei 'permitrootlogin|allowusers|passwordauth'
# =============================================================================
set -e
ALLOWED_USERS="jmoney plinktern"     # <-- scoring user + admin user
CONF=/etc/ssh/sshd_config.d/00-hardening.conf

grep -qi '^Include /etc/ssh/sshd_config.d/\*.conf' /etc/ssh/sshd_config || \
  sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' /etc/ssh/sshd_config

cp -a /etc/ssh/sshd_config "/etc/ssh/sshd_config.bak.$(date +%H%M)"
mkdir -p /etc/ssh/sshd_config.d
cat > "$CONF" <<CFG
PermitRootLogin no
PermitEmptyPasswords no
PasswordAuthentication yes
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
PermitUserEnvironment no
PermitUserRC no
MaxAuthTries 4
LoginGraceTime 30
AllowUsers $ALLOWED_USERS
CFG
chmod 600 "$CONF"

if sshd -t; then
  if systemctl list-unit-files | grep -q '^ssh.service'; then SVC=ssh; else SVC=sshd; fi
  systemctl restart "$SVC"
  echo "[OK] Hardened and restarted $SVC. Test a NEW login now."
  echo "     Optional lock: sudo chattr +i /etc/ssh/sshd_config $CONF"
else
  echo "[!] Config test FAILED. SSH was NOT restarted. Fix $CONF."
  exit 1
fi
