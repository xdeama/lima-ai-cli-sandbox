# Lima AI Sandbox

A reproducible Ubuntu VM managed by [Lima](https://github.com/lima-vm/lima), pre-configured with an AI CLI (Claude Code or Gemini), Node.js, and Docker. Designed to give the AI a sandboxed Linux environment with access to your code — without letting it touch the rest of your Mac.

> **IMPORTANT: PLACEHOLDERS USED IN THIS GUIDE**
> Commands in this documentation use `< >` to denote placeholders. **Do not copy and paste these commands directly without substituting your actual values.**
> * `<VM_NAME>`: The VM name defined in your `.env` file (e.g., `claudevm`).
> * `<VM_SSH_PORT>`: The port defined in your `.env` file (e.g., `8222`).
> * `<path-to-private-key>`: The local path to the SSH private key used for the VM (e.g., `~/.ssh/id_ed25519`).
> * `<vm-username>`: The username configured for your VM (usually matches your host username).

---

## What This Is

[Lima](https://github.com/lima-vm/lima) is a tool for running Linux VMs on macOS using Apple's native Virtualization.framework. Think of it like Docker Desktop, but for full VMs.

This repo contains YAML configuration files that define a Lima VM pre-installed with an AI CLI tool. The VM is isolated from your Mac — the AI can only read/write the specific folders you explicitly share with it via mounts.

**Available templates:**
| File | AI Tool | Extra Tools |
|---|---|---|
| `lima-claude-base.yaml` | Claude Code | git, Node.js, Docker |
| `lima-claude.yaml` | Claude Code | + JDK 21, Gradle |
| `lima-gemini-base.yaml` | Gemini CLI | git, Node.js, Docker |
| `lima-gemini.yaml` | Gemini CLI | + JDK 21, Gradle |

Start with a base template and copy in the project-specific tools you need.

---

## How State Works

Understanding this will save you a lot of confusion.

**The virtual disk** stores your home directory, installed packages, and system config permanently. It survives reboots. It is destroyed when you delete the VM.

**Lima runs provision scripts on every boot** — not just the first. To avoid reinstalling everything on each reboot, the scripts use hidden marker files (`/etc/.lima_system_init_done`, `~/.lima_user_init_done`). If the marker exists, the heavy setup is skipped. This means reboots are fast.

**Host mounts** are folders on your Mac that are shared into the VM. Changes are reflected instantly in both directions. These survive VM deletion because the files live on your Mac, not on the VM disk.

**`/tmp` is wiped on every reboot** by Ubuntu. The host mounts are placed inside `/tmp/` in the VM, but the actual files are on your Mac so they are never lost.

---

## What Gets Mounted and Why

The VM gets read/write access to exactly three folders on your Mac — nothing more.

### 1. SSH Keys (`PATH_LIMA_SSH` → `/tmp/ssh`)
**Read-only.** A folder on your Mac containing a file named `key.pub`. The provisioning script reads this public key on first boot and adds it to the VM's `authorized_keys`, so you can SSH in.

You need to create this folder and copy your public key into it:
```bash
mkdir -p /your/chosen/path/.ssh
cp ~/.ssh/id_ed25519.pub /your/chosen/path/.ssh/key.pub
```

### 2. Repository (`PATH_REPOSITORY` → `/tmp/repository`)
**Read-write.** The code repository you want the AI to work with. Mounting it here means the AI can read and edit your code inside the VM, and the changes appear live on your Mac.

Point this at your project directory:
```bash
PATH_REPOSITORY=/Users/<vm-username>/path/to/your/project
```

### 3. AI Config (`PATH_LIMA_CLAUDE` or `PATH_LIMA_GEMINI` → `~/.claude` or `~/.gemini`)
**Read-write.** The AI CLI's configuration folder from your Mac, mounted directly into the VM's home directory. This is how authentication tokens and settings survive a VM rebuild — they live on your Mac, not on the VM disk.

**For Claude Code:** The CLI also needs `~/.claude.json` (its main auth file). Since Lima can only mount directories (not individual files), this file is stored inside the `.claude` folder on your Mac and symlinked into place in the VM on every boot. See the setup steps below.

> **Warning:** These paths must be valid absolute paths before creating the VM. If a variable is unset or wrong, Lima will silently mount the Mac root filesystem (`/`) as read-only, and you will see `Read-only file system` errors inside the VM. You can verify with `df -h ~/.claude` inside the VM.

---

## Prerequisites

- macOS with [Lima installed](https://github.com/lima-vm/lima#installation): `brew install lima`
- An SSH key pair on your Mac (e.g., `~/.ssh/id_ed25519` + `id_ed25519.pub`)
- A Claude Code or Gemini CLI account with an existing `~/.claude.json` or `~/.gemini` config on your Mac (i.e., you have already authenticated the CLI locally at least once)

---

## Setup (First Time)

**Step 1 — Copy and fill in your config:**
```bash
cp .env-example .env
```
Open `.env` and set every variable. Use absolute paths (no `~` shorthand).

| Variable | What it is |
|---|---|
| `VM_NAME` | Name for the Lima VM instance (e.g. `claudevm`) |
| `VM_USER` | Your username inside the VM — use your Mac username |
| `VM_INIT_PASS` | A temporary password set on first boot. Change it with `passwd` after logging in |
| `VM_SSH_PORT` | Local port forwarded to the VM's SSH server (e.g. `8222`) |
| `PATH_LIMA_SSH` | Folder containing your `key.pub` |
| `PATH_REPOSITORY` | Your project folder |
| `PATH_LIMA_CLAUDE` | Path to your `.claude` config folder |
| `PATH_LIMA_GEMINI` | Path to your `.gemini` config folder |

**Step 2 — Prepare the SSH mount folder:**
```bash
mkdir -p /your/chosen/ssh/path
cp ~/.ssh/id_ed25519.pub /your/chosen/ssh/path/key.pub
```

**Step 3 — Prepare the AI config mount (Claude Code):**

Create the mount folder inside this repo (already gitignored) and copy your auth file into it:
```bash
mkdir -p .claude
cp ~/.claude.json .claude/.claude.json
```
Then set `PATH_LIMA_CLAUDE` in `.env` to the absolute path of that `.claude` folder.

**Step 3 — Prepare the AI config mount (Gemini):**
```bash
mkdir -p .gemini
cp -r ~/.gemini/. .gemini/
```
Then set `PATH_LIMA_GEMINI` in `.env` to the absolute path of that `.gemini` folder.

**Step 4 — Create the VM:**
```bash
./start.sh lima-claude-base.yaml
```
First boot takes a few minutes while packages are installed. Subsequent boots take seconds.

---

## Daily Usage

**Start the VM:**
```bash
limactl start <VM_NAME>
```
Every vm start creates a new vm instance, with a new ssh fingerprint.

**Stop the VM:**
```bash
limactl stop <VM_NAME>
```

**Delete the VM** (delete the vm and it's virutal storage, also deletes the ssh fingerprint from four ssh config):
```bash
./delete.sh <VM_NAME>
```

---

## Connecting

**Via Lima (simplest):**
```bash
limactl shell <VM_NAME>
```

**Via SSH:**
```bash
# Using a specific key
ssh -p <VM_SSH_PORT> -o IdentitiesOnly=yes -i <path-to-private-key> <vm-username>@localhost

# Standard
ssh -p <VM_SSH_PORT> <vm-username>@localhost
```

---

## Editing Volume Mounts on an Existing VM

You can change which folders are shared without deleting the VM. Because of the init marker files, the reboot will take seconds, not minutes:

```bash
limactl stop <VM_NAME>
limactl edit <VM_NAME>
# Save and exit the editor, then:
limactl start <VM_NAME>
```

> **SSH fingerprint warning after edits**
> `limactl edit` assigns a new hardware ID to the VM, which causes Ubuntu to regenerate its SSH host keys. Your next SSH attempt will fail with `REMOTE HOST IDENTIFICATION HAS CHANGED`. This is expected. Fix it by purging the old fingerprint:
> ```bash
> ssh-keygen -R "[localhost]:<VM_SSH_PORT>"
> ```
> Then reconnect and accept the new fingerprint.

---

## Maintenance

Install additional tools manually inside the VM:
```bash
sudo apt-get update
sudo apt-get install -y <package>
```

Update Claude Code:
```bash
npm install -g @anthropic-ai/claude-code
```

Update Gemini CLI:
```bash
npm install -g @google/gemini-cli
```

---

## Cleanup

**Remove cached Lima base images** (frees disk space, images are re-downloaded on next VM creation):
```bash
limactl prune
```

---

## Debugging

**Check VM status:**
```bash
limactl list
```

**VM won't finish booting?** Check the hypervisor log on your Mac:
```bash
less ~/.lima/<VM_NAME>/ha.stderr.log
```

**Is Ubuntu actually up?** Check the serial console output:
```bash
less "$HOME/.lima/<VM_NAME>/serialv.log"
```

**Tools missing or config wrong after SSH?** Check the cloud-init provisioning log inside the VM:
```bash
sudo tail -n 50 /var/log/cloud-init-output.log
```

**Mount looks wrong?** Check what is actually mounted:
```bash
df -h ~/.claude
# or
df -h ~/.gemini
```
If the output shows the Mac root filesystem, `PATH_LIMA_CLAUDE` / `PATH_LIMA_GEMINI` in `.env` is unset or points to the wrong path.
