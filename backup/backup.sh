#!/usr/bin/env bash
# =============================================================================
# backup.sh  |  BUNDLE: backup
# PURPOSE : Snapshot this box's configuration, website, SSH keys, crontabs, and
#           a text "picture" of ports/users/services, then stream it all to a
#           safe, out-of-scope backup host in a single SSH connection.
# WHY     : Restoring one file from a backup takes a minute; a full revert loses
#           all your work. Take a "clean" backup before changing anything and a
#           "hardened" one after.
# USAGE   : sudo bash backup.sh <label>      e.g.  sudo bash backup.sh clean
# CHANGES : Nothing on this box (temp folder is deleted at the end).
# =============================================================================
BACKUP_HOST="plinktern@172.16.13.5"   # <-- out-of-scope box (edit for your team)
WEB_ROOT="/var/www"                    # <-- confirm with: sudo apache2ctl -S
LABEL="${1:-snap}"
DEST="backups/$(hostname)/$(date +%H%M)-$LABEL"
WORK="$(mktemp -d)"

echo "[*] Taking text snapshots..."
ss -tulpn                > "$WORK/ports.txt"
ss -tanp                 > "$WORK/connections.txt"
ps auxf                  > "$WORK/processes.txt"
getent passwd            > "$WORK/users.txt"
getent group             > "$WORK/groups.txt"
systemctl list-units --type=service --state=running --no-pager > "$WORK/services.txt"
systemctl list-unit-files --state=enabled --no-pager           > "$WORK/enabled-units.txt"
systemctl list-timers --all --no-pager                         > "$WORK/timers.txt"
iptables-save            > "$WORK/iptables.txt" 2>/dev/null
find / -xdev -perm -4000 -type f 2>/dev/null > "$WORK/suid.txt"
find / -xdev -iname "*auth*key*" -path "*.ssh*" 2>/dev/null -exec md5sum {} \; > "$WORK/authkeys.txt"

echo "[*] Archiving files..."
tar -czpf "$WORK/etc.tar.gz" /etc 2>/dev/null
tar -czpf "$WORK/ssh-keys.tar.gz" /root/.ssh /home/*/.ssh 2>/dev/null
tar -czpf "$WORK/cron-spool.tar.gz" /var/spool/cron 2>/dev/null
[ -d "$WEB_ROOT" ] && tar -czpf "$WORK/web.tar.gz" "$WEB_ROOT"

echo "[*] Sending to $BACKUP_HOST (enter its password)..."
tar -czf - -C "$WORK" . | ssh "$BACKUP_HOST" "mkdir -p ~/$DEST && tar -xzf - -C ~/$DEST" \
  && echo "[OK] Saved to $BACKUP_HOST:~/$DEST"
rm -rf "$WORK"
