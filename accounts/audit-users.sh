#!/usr/bin/env bash
# =============================================================================
# audit-users.sh  |  BUNDLE: accounts
# PURPOSE : Read-only audit of /etc/passwd, /etc/group, /etc/shadow, sudoers,
#           and SSH key files, to find backdoor accounts.
# LOOKS FOR:
#   - extra UID 0 accounts (root-equivalent, e.g. "toor")
#   - members of admin groups (sudo, admin, wheel, lxd, docker)
#   - accounts that can log in with a password, or have an empty one
#   - login shells that aren't a normal shell (e.g. swapped for a fake program)
#   - SSH key files, including misspelled look-alikes ("authroized_keys")
# USAGE   : sudo bash audit-users.sh | less
# CHANGES : Nothing.
# =============================================================================
s() { echo; echo "===== $1 ====="; }
s "UID 0 accounts (only root expected)";  awk -F: '$3==0{print $1}' /etc/passwd
s "Human accounts (UID >= 1000)";        awk -F: '$3>=1000 && $3<65534 {print $1, "UID="$3, "shell="$7}' /etc/passwd
s "System accounts with a real shell";   awk -F: '$3<1000 && $7 !~ /(nologin|false|sync)$/ {print $1, $7}' /etc/passwd
s "Unusual login shells";                awk -F: '$7 !~ /(bash|sh|zsh|nologin|false|sync|shutdown|halt)$/ {print $1, $7}' /etc/passwd
s "Admin groups";                        grep -E '^(sudo|admin|wheel|adm|lxd|docker|shadow):' /etc/group
s "Can log in with a password";          awk -F: '$2 !~ /^[!*]/ && $2!="" {print $1}' /etc/shadow
s "EMPTY passwords";                     awk -F: '$2=="" {print $1}' /etc/shadow
s "sudoers rules";                       grep -hv '^#' /etc/sudoers /etc/sudoers.d/* 2>/dev/null | grep -E 'ALL|NOPASSWD'
s "SSH key files (any spelling)";        find / -xdev -iname "*auth*key*" -path "*.ssh*" 2>/dev/null -exec sh -c 'echo "--- $1"; cat "$1"' _ {} \;
s "Logged-in sessions";                  who
