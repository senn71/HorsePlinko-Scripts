#!/usr/bin/env bash
# =============================================================================
# lock-accounts.sh  |  BUNDLE: accounts
# PURPOSE : Lock the accounts you name: lock the password, remove the shell,
#           expire the account, and take it out of the sudo group.
#           Reversible: usermod -U <name>; usermod -s /bin/bash <name>; chage -E -1 <name>
# WHY NOT DELETE? Locking keeps evidence and can't break an app that expects
#           the account to exist.
# SAFETY  : Refuses to touch protected accounts (scoring/admin users).
#           Never use `pkill -u` on a UID 0 account: it matches the UID, not the
#           name, and kills every root process on the box.
# USAGE   : sudo bash lock-accounts.sh toor ardian kheating
# =============================================================================
PROTECTED="root jmoney plinktern"     # <-- never lock these
[ $# -eq 0 ] && { echo "Usage: $0 <user> [user...]"; exit 1; }

for u in "$@"; do
  if echo " $PROTECTED " | grep -q " $u "; then echo "[skip] $u is protected"; continue; fi
  getent passwd "$u" >/dev/null || { echo "[skip] $u does not exist"; continue; }
  usermod -L "$u" && usermod -s /usr/sbin/nologin "$u" && chage -E 0 "$u"
  gpasswd -d "$u" sudo >/dev/null 2>&1
  echo "[locked] $u (uid $(id -u "$u"))"
done
echo; echo "Accounts still able to use a password:"
awk -F: '$2 !~ /^[!*]/ && $2!="" {print "  " $1}' /etc/shadow
