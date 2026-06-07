# Pawkup

Pawkup is a small Bash CLI for local and cloud backups using `restic` and optional `rclone`.

It is designed to run as your normal user, store configuration in your home directory, and make restore decisions explicit.

## Features

- Local restic backups.
- Cloud restic backups through rclone.
- Interactive setup and restore picker.
- Include and exclude path files.
- User systemd timer for scheduled backups.
- Repository checks and retention management.
- Password rotation helper.

## Requirements

- Linux with Bash.
- `restic`.
- `python3`.
- `systemd` for scheduling and sleep/shutdown inhibition.
- `rclone` for cloud backups.
- `rsync` is recommended for restores.

On Debian/Ubuntu:

```bash
sudo apt update
sudo apt install -y bash restic python3 rclone rsync
```

`install.sh` checks for missing runtime dependencies and asks before installing only the packages that are not already present.

## Install

```bash
git clone https://github.com/zig-zag-zig/pawkup.git
cd pawkup
./install.sh
```

The default install location is:

```text
~/.local/bin/pawkup
~/.local/libexec/pawkup/
```

Make sure `~/.local/bin` is on your `PATH`.

Install somewhere else:

```bash
./install.sh --prefix "$HOME/.local"
```

## Quick Start

Open the interactive menu:

```bash
pawkup
```

Run a local backup:

```bash
pawkup backup --local-only
```

Preview the effective backup selection:

```bash
pawkup backup --dry-run --local-only
```

List local restore points:

```bash
pawkup restore --source local list
```

Restore through the picker:

```bash
pawkup restore
```

## Configuration

Pawkup stores configuration under:

```text
~/.config/pawkup/
```

Important files:

```text
backup.env
restic-password
include-paths.txt
exclude-paths.txt
```

The default local repository is:

```text
~/pawkup
```

The default rclone config path is:

```text
~/.config/rclone/rclone.conf
```

## Include And Exclude Paths

`include-paths.txt` accepts one path per line.

Examples:

```text
.
Documents
~/Projects/*
/etc/ssh
```

Relative paths are resolved under `$HOME`. Absolute paths stay absolute.

`exclude-paths.txt` also accepts one entry per line. Excludes are validated against the active include set so a broad exclude cannot silently cancel an explicitly included path.

## Scheduling

Use the interactive menu or:

```bash
pawkup
```

Scheduled backups are installed as a user systemd timer:

```text
~/.config/systemd/user/pawkup-backup.service
~/.config/systemd/user/pawkup-backup.timer
```

Check timer status:

```bash
systemctl --user list-timers pawkup-backup.timer --all
```

## Restore Safety

Pawkup should be run as your normal user, not root.

Staged restores must be inside `$HOME`.

Blank target means restore to original paths. If the snapshot includes system paths outside `$HOME`, Pawkup warns before continuing. The privileged copy path uses non-interactive `sudo -n`; that means it will fail unless your system allows the specific sudo operation without prompting.

Review system restores carefully. Restoring over live system paths can overwrite important files.

## Uninstall

```bash
./uninstall.sh
```

Uninstall removes the installed CLI/helper files and disables the Pawkup user timer. It leaves your configuration, repositories, password file, and logs in place.

## Development

Run syntax checks:

```bash
bash -n bin/pawkup libexec/pawkup/pawkup_* tests/run_pawkup_tests install.sh uninstall.sh
```

Run tests:

```bash
tests/run_pawkup_tests
```

Optional shell lint:

```bash
shellcheck bin/pawkup libexec/pawkup/pawkup_* tests/run_pawkup_tests install.sh uninstall.sh
```

## License

MIT
