# Repository Guidelines

This repository is a collection of **Pop!_OS workstation optimization notes, systemd units, udev rules, and install scripts**. Changes here can affect system stability—prefer small, well-documented edits with clear rollback steps.

## Project Structure & Module Organization

- `README.md` – high-level overview and entry points.
- `HARDWARE.md` / `ISSUES.md` – hardware inventory and issue tracking.
- `rtx5090/` – GPU-specific fixes (systemd unit, shutdown hook, installer).
- `power-management/` – sleep/hibernate disablement and performance profile persistence.
- `bios/` – exported BIOS profiles and restore instructions.
- `pop-os-docs/` – upstream Pop!_OS documentation clone (separate git repo; ignored by this repo’s `.gitignore`).

When adding a new optimization, create a component folder (e.g., `audio/`, `network/`) with a `README.md` explaining: problem → root cause → solution → install/rollback → verification commands.

## Build, Test, and Development Commands

There is no global build. Common local actions are:

- Apply RTX fix: `./rtx5090/install-nvidia-fix.sh`
- Apply power changes: follow `power-management/README.md`
- Verify runtime state: `systemctl --failed`, `journalctl -b | grep -iE 'xid'`, `nvidia-smi`
- View Pop docs locally (optional): `cd pop-os-docs && mdbook serve` (requires `mdbook`)

## Coding Style & Naming Conventions

- Markdown: keep sections scannable; include copy-pastable command blocks.
- Shell (`bash`): use `set -e`, quote variables, and prefer explicit paths (e.g., `/usr/bin/nvidia-smi` in units).
- File naming:
  - Installers: `install-<topic>.sh`
  - systemd units: `*.service`
  - udev rules: `*.rules`
  - system configs: `*.conf`

## Testing Guidelines

No automated test suite. Every change should include manual verification steps in the relevant `README.md` (commands + expected output) and a rollback section.

## Commit & Pull Request Guidelines

- Commits: use short, imperative subjects (seen in history), e.g. `Add systemd service to persist Performance power profile`.
- PRs: include summary, affected hardware/OS assumptions, exact install destinations (e.g., `/etc/systemd/system`), verification commands, and rollback steps. If behavior is user-visible, attach logs/snippets (e.g., `nvidia-smi` output).
