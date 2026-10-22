# HPCC4 Blue Team Scripts (Ubuntu / SSH + Web)

Scripts I wrote and used defending an Ubuntu 22.04 server (SSH + Apache/PHP web app)
during the **Horse Plinko Cyber Challenge 4 (HPCC4)**, a collegiate cyber defense
competition. The red team had root on the box and planted many forms of persistence;
these scripts cover the full loop: back up, harden, hunt, contain, and restore.

> **Use only on systems you own or are explicitly authorized to defend.**
> Every script is either read-only or asks you to name exactly what it changes.
> Read a script before running it, and keep a second SSH session open while you
> change SSH, PAM, or firewall settings.

## Layout

| Folder | What the bundle is for | Scripts |
| --- | --- | --- |
| `backup/` | Copy configs and the website to an out-of-scope box, and pull them back | `backup.sh`, `fetch-backup.sh` |
| `ssh/` | Harden the SSH server without locking out the scoring user | `harden-ssh.sh` |
| `accounts/` | Find and lock backdoor accounts (hidden UID 0, extra sudoers, empty passwords) | `audit-users.sh`, `lock-accounts.sh` |
| `hunting/` | Find persistence (preload rootkits, fake services, boot hooks, fileless implants) and quarantine it | `hunt.sh`, `quarantine.sh` |
| `firewall/` | Set a ufw baseline and catch rules hidden outside ufw | `ufw-baseline.sh`, `check-hidden-rules.sh` |
| `web/` | Diagnose a down website in seconds and restore the site | `web-triage.sh`, `restore-web.sh` |

## Typical order on a fresh box

1. `backup/backup.sh clean` before changing anything
2. Change passwords (`passwd`, `sudo passwd <scoring-user>`) and update the scoreboard
3. `ssh/harden-ssh.sh`, then test a **new** login as the scoring user
4. `accounts/audit-users.sh`, then `accounts/lock-accounts.sh <names>`
5. `hunting/hunt.sh`, then `hunting/quarantine.sh <paths>`
6. `firewall/ufw-baseline.sh 22 80`
7. `backup/backup.sh hardened`
8. When something goes red: `web/web-triage.sh`, `firewall/check-hidden-rules.sh`

## Configuration

Edit the variables at the top of each script (backup host, ports, users).
Nothing secret is stored in this repo: no passwords, keys, or tokens.

## Lessons learned (what the red team actually did)

- Hidden UID 0 accounts (`toor`, and a normal-looking name) and a misspelled `authroized_keys`
- `/etc/ld.so.preload` loading a library that mangled terminal output
- A user's login shell swapped for a fake "roulette" program
- Fake systemd services with system-sounding names, plus watchdog scripts that restarted each other
- Boot-time re-installers in `networkd-dispatcher` hooks, `udev` rules, and `cron.d`
- A fileless implant (`bash -p /proc/self/fd/3`) that re-dropped deleted binaries
- Apache's systemd unit changed to `ExecStart=sleep 1000`
- Apache `DocumentRoot` pointed at a hidden web-shell directory, then the web root deleted
- Firewall rules added directly with `iptables` (including an **OUTPUT** drop on source port 80) that `ufw status` never showed
- A `pam_exec` line in PAM that rejected every login

Key takeaways: **process** persistence survives file cleanup (kill the process *and* remove its
trigger), restarts don't help while boot hooks remain, and `ufw status` is not the whole firewall.
