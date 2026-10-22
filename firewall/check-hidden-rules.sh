#!/usr/bin/env bash
# =============================================================================
# check-hidden-rules.sh  |  BUNDLE: firewall
# PURPOSE : Show firewall rules that were added BEHIND ufw's back.
#           `ufw status` only lists ufw's own rules. An attacker with root can
#           insert rules directly with iptables/nft, e.g.
#             -I INPUT  -p tcp --dport 80 -j DROP     (requests never arrive)
#             -A OUTPUT -p tcp --sport 80 -j DROP     (replies never leave)
#           Both make a site time out from outside while it works locally.
# USAGE   : sudo bash check-hidden-rules.sh
# FIX     : repeat a bad rule with -D instead of -A/-I, e.g.
#           sudo iptables -D OUTPUT -p tcp -m tcp --sport 80 -j DROP
# CHANGES : Nothing.
# =============================================================================
echo "== Rules not belonging to ufw (only the 3 '-P' policy lines are normal) =="
iptables -S | grep -v ufw
echo; echo "== INPUT chain order (anything above ufw-before-* runs first) =="
iptables -L INPUT -n --line-numbers | head -8
echo; echo "== raw / mangle tables (should only be -P ... ACCEPT) =="
iptables -t raw -S; iptables -t mangle -S
echo; echo "== nftables tables (ufw normally only uses ip/ip6 filter) =="
nft list tables 2>/dev/null
echo; echo "== Suspicious lines in ufw rule files =="
grep -nE 'dport 80|sport 80|-A OUTPUT|-A INPUT' /etc/ufw/after.rules /etc/ufw/after6.rules /etc/ufw/before.rules 2>/dev/null \
  | grep -v 'ufw-' || echo "(none)"
echo; echo "== Is ufw enabled at boot? =="
systemctl is-enabled ufw
