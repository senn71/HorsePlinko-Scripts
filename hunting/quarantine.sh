#!/usr/bin/env bash
# =============================================================================
# quarantine.sh  |  BUNDLE: hunting
# PURPOSE : Move suspicious files out of the way WITHOUT deleting them.
#           Unlocks immutable files (chattr -i), moves them into a timestamped
#           folder under /root/quarantine, and removes all permissions.
# WHY     : Moving stops the file from running and keeps evidence (useful for
#           incident-report injects). Disable services FIRST and kill their
#           processes, or copies already running in memory keep going.
# USAGE   : sudo bash quarantine.sh /etc/ld.so.preload /etc/systemd/system/fake.service
# AFTER   : sudo systemctl daemon-reload   (if you moved any .service files)
# =============================================================================
[ $# -eq 0 ] && { echo "Usage: $0 <path> [path...]"; exit 1; }
Q="/root/quarantine/$(date +%H%M%S)"
mkdir -p "$Q"
for f in "$@"; do
  [ -e "$f" ] || { echo "[skip] $f not found"; continue; }
  chattr -i "$f" 2>/dev/null
  name="$(echo "$f" | sed 's#^/##; s#/#__#g')"
  mv "$f" "$Q/$name" && echo "[moved] $f -> $Q/$name"
done
chmod -R 000 "$Q"/* 2>/dev/null
echo "[OK] Quarantine folder: $Q"
