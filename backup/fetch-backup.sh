#!/usr/bin/env bash
# =============================================================================
# fetch-backup.sh  |  BUNDLE: backup
# PURPOSE : Pull one backup archive from the backup host and unpack it into
#           /tmp/restore so you can DIFF it against the live system before
#           copying anything back.
# WHY     : Never restore all of /etc blindly. It can undo password changes and
#           good fixes. Compare first, then copy back only the file that changed.
# USAGE   : bash fetch-backup.sh <path-under-~/backups/HOSTNAME/>
#           e.g. bash fetch-backup.sh 0912-clean/etc.tar.gz
# THEN    : sudo diff -r /tmp/restore/etc/ssh /etc/ssh
#           sudo cp -a /tmp/restore/etc/ssh/sshd_config /etc/ssh/sshd_config
# CHANGES : Only /tmp/restore.
# =============================================================================
BACKUP_HOST="plinktern@172.16.13.5"   # <-- edit for your team
REMOTE="$1"
if [ -z "$REMOTE" ]; then
  echo "Usage: $0 <path under ~/backups/$(hostname)/>   Available:"
  ssh "$BACKUP_HOST" "ls -R ~/backups/$(hostname)/ | head -40"
  exit 1
fi

mkdir -p /tmp/restore && cd /tmp/restore || exit 1
scp "$BACKUP_HOST:~/backups/$(hostname)/$REMOTE" ./archive.tar.gz || exit 1
sudo tar -xzpf archive.tar.gz -C /tmp/restore
echo "[OK] Unpacked into /tmp/restore. Compare with: sudo diff -r /tmp/restore/etc/<dir> /etc/<dir>"
