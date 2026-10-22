#!/usr/bin/env bash
# =============================================================================
# ufw-baseline.sh  |  BUNDLE: firewall
# PURPOSE : Default-deny inbound, allow outbound, and open ONLY the ports you
#           list (from any source, since scoring connects from many IPs).
#           Also un-masks ufw in case an attacker masked it so it won't start
#           at boot.
# SAFETY  : SSH (22) is always added first so you can't lock yourself out.
#           Existing sessions survive; test a NEW login afterwards.
# USAGE   : sudo bash ufw-baseline.sh 80            (22 is added automatically)
#           sudo bash ufw-baseline.sh 80 443
# UNDO    : sudo ufw disable
# NOTE    : Don't set "default deny outgoing" without testing it first. In the
#           competition it broke the scored SSH check.
# =============================================================================
systemctl unmask ufw >/dev/null 2>&1
ufw allow 22/tcp
for p in "$@"; do ufw allow "$p/tcp"; done
ufw default deny incoming
ufw default allow outgoing
ufw --force enable
systemctl enable ufw >/dev/null 2>&1
ufw status numbered
echo; echo "Now run check-hidden-rules.sh: 'ufw status' does not show everything."
