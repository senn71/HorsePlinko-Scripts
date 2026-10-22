#!/usr/bin/env bash
# =============================================================================
# hunt.sh  |  BUNDLE: hunting
# PURPOSE : Read-only sweep for the persistence a red team leaves behind.
#           Run it right after hardening, then every 30-60 minutes.
# CHECKS  :
#   - /etc/ld.so.preload (forces a library into EVERY program; should not exist)
#   - PAM lines that run programs at login (pam_exec)
#   - login scripts: /etc/profile.d, ssh rc files, tagged red-team blocks
#   - systemd units in /etc/systemd/system and /usr/local/lib/systemd
#   - boot/network hooks: networkd-dispatcher, udev rules, cron.d, crontabs
#   - files changed in the last N minutes (default: 360)
#   - processes running from memory (/proc/self/fd, memfd, deleted binaries)
#   - listening ports and established connections
# USAGE   : sudo bash hunt.sh [minutes-back] > /tmp/hunt.txt ; less /tmp/hunt.txt
# CHANGES : Nothing.
# =============================================================================
MIN="${1:-360}"
s() { echo; echo "===== $1 ====="; }

s "ld.so.preload (should not exist)";   cat /etc/ld.so.preload 2>/dev/null || echo "(none, good)"
s "PAM lines that run programs";        grep -rn -E 'pam_exec|pam_script' /etc/pam.d/ 2>/dev/null || echo "(none, good)"
s "SSH rc files";                       ls -la /etc/ssh/sshrc /root/.ssh/rc /home/*/.ssh/rc 2>/dev/null || echo "(none, good)"
s "Effective SSH settings";             sshd -T 2>/dev/null | grep -Ei 'permitrootlogin|allowusers|forcecommand|authorizedkeysfile'
s "Tagged red-team blocks";             grep -rln -E 'REDTEAM' /etc /root /home 2>/dev/null || echo "(none)"
s "profile.d scripts";                  ls -lt /etc/profile.d/
s "Custom systemd units";               ls -lt /etc/systemd/system/*.service 2>/dev/null
s "/usr/local/lib/systemd (normally empty)"; ls -la /usr/local/lib/systemd 2>/dev/null || echo "(missing, good)"
s "networkd-dispatcher hooks";          ls -la /etc/networkd-dispatcher/*/ 2>/dev/null
s "udev rules";                         ls -lt /etc/udev/rules.d/ 2>/dev/null
s "cron";                               cat /etc/crontab; ls -la /etc/cron.d/; ls /var/spool/cron/crontabs/ 2>/dev/null
s "Timers";                             systemctl list-timers --all --no-pager
s "Files changed in last $MIN min";     find /etc /lib/systemd /usr/lib/systemd /usr/local /var/spool/cron -xdev -type f -mmin -"$MIN" 2>/dev/null
s "Processes running from memory, temp dirs, or deleted files"
for p in /proc/[0-9]*; do
  exe=$(readlink "$p/exe" 2>/dev/null) || continue
  case "$exe" in
    *deleted*|*memfd*|/proc/*|/tmp/*|/dev/shm/*|/var/tmp/*)
      echo "PID ${p#/proc/}: $exe  ($(tr '\0' ' ' < "$p/cmdline" | cut -c1-80))";;
  esac
done
ps -eo pid,user,cmd | grep -E '/proc/self/fd|/dev/shm|/tmp/' | grep -v grep
s "Listening ports";                    ss -tulpn
s "Established connections";            ss -tanp state established
s "Logged-in users";                    who
echo
echo "TIP: for any suspicious PID run  pstree -aps <PID>  and  systemctl status <PID>"
echo "     BEFORE killing it, so you learn what started it."
