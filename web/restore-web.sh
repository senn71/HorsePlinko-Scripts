#!/usr/bin/env bash
# =============================================================================
# restore-web.sh  |  BUNDLE: web
# PURPOSE : Put the website back after files were deleted or defaced, using a
#           web backup unpacked once into /tmp/restore-web.
#           First run downloads + unpacks; later runs restore in seconds.
# HOW     : `cp -a` restores missing/changed files with original owners and
#           permissions. It does NOT delete extra files, so the script lists
#           files that exist live but not in the backup (possible web shells).
# USAGE   : sudo bash restore-web.sh <path-under-~/backups/HOSTNAME/>
#           sudo bash restore-web.sh            (re-use what's already unpacked)
# =============================================================================
BACKUP_HOST="plinktern@172.16.13.5"   # <-- edit
SITE_DIR="/var/www/plinkcom"           # <-- edit
STAGE="/tmp/restore-web"

if [ -n "$1" ]; then
  mkdir -p "$STAGE" && cd "$STAGE" || exit 1
  scp "$BACKUP_HOST:~/backups/$(hostname)/$1" ./web.tar.gz || exit 1
  tar -xzpf web.tar.gz -C "$STAGE"
fi
[ -d "$STAGE$SITE_DIR" ] || { echo "Nothing staged in $STAGE$SITE_DIR. Pass a backup name."; exit 1; }

mkdir -p "$SITE_DIR"
cp -a "$STAGE$SITE_DIR/." "$SITE_DIR/"
systemctl reload apache2
echo "Files on the live site that aren't in the backup (possible web shells):"
diff -rq "$STAGE$SITE_DIR" "$SITE_DIR" | grep "^Only in $SITE_DIR" || echo "  (none)"
echo "LOCAL HTTP: $(curl -s -m 5 -o /dev/null -w '%{http_code}' http://localhost/login.php)"
