#!/usr/bin/env bash
# =============================================================================
# web-triage.sh  |  BUNDLE: web
# PURPOSE : Ten-second check of every common reason a scored website goes red.
#           Prints one line per layer so you can see exactly where it breaks.
# LAYERS  : service -> systemd unit -> Apache config -> site files -> firewall
#           -> local HTTP -> database
# USAGE   : sudo bash web-triage.sh
# ALSO RUN FROM YOUR LAPTOP:
#           curl -m 5 -s -o /dev/null -w "%{http_code}\n" http://<server>/login.php
#           local 200 + remote 000 = traffic is being dropped (check-hidden-rules.sh)
# CHANGES : Nothing.
# =============================================================================
SITE_CONF="/etc/apache2/sites-available/plinkcom.conf"   # <-- edit
WEB_ROOT="/var/www/plinkcom/public"                       # <-- edit
TEST_PAGE="login.php"
DB_HOST="172.16.13.40"; DB_PORT=3306                      # <-- edit

echo "APACHE SERVICE : $(systemctl is-active apache2)"
echo "UNIT ExecStart : $(systemctl cat apache2 2>/dev/null | grep -E '^ExecStart=' | head -1)"
echo "DOCUMENTROOT   : $(grep -iE '^\s*DocumentRoot' "$SITE_CONF" | xargs)"
echo "CONFIG TEST    : $(apache2ctl configtest 2>&1 | tail -1)"
if [ -f "$WEB_ROOT/$TEST_PAGE" ]; then echo "SITE FILES     : present"; else echo "SITE FILES     : MISSING ($WEB_ROOT/$TEST_PAGE)"; fi
[ -f "$WEB_ROOT/.htaccess" ] && echo ".HTACCESS      : EXISTS (check it)"
echo "PORT 80 LISTEN : $(ss -tlnp | grep -c ':80 ') listener(s)"
echo "HIDDEN FW RULES: $(iptables -S | grep -v ufw | grep -c '^-A') (should be 0)"
echo "LOCAL HTTP     : $(curl -s -m 5 -o /dev/null -w '%{http_code}' "http://localhost/$TEST_PAGE")"
if timeout 3 bash -c "</dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
  echo "DB PORT        : open"
else
  echo "DB PORT        : CLOSED (database box problem)"
fi
echo "LD_PRELOAD FILE: $([ -e /etc/ld.so.preload ] && echo PRESENT || echo none)"
