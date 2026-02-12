# Lima AI Sandbox

A reproducible, ephemeral Ubuntu VM managed by [Lima](https://github.com/lima-vm/lima), pre-configured with the Gemini CLI, Node.js, and host volume mounts. Designed to keep AI toolchains and repository operations isolated from the host.

> **IMPORTANT: PLACEHOLDERS USED IN THIS GUIDE**
> Commands in this documentation use `< >` to denote placeholders. **Do not copy and paste these commands directly without substituting your actual values.**
> * `<VM_SSH_PORT>`: The port defined in your `.env` file (e.g., `8222`).
> * `<path-to-private-key>`: The local path to the SSH private key used for the VM (e.g., `~/.ssh/id_ed25519`).
> * `<vm-username>`: The username configured for your VM (usually matches your host username).

## Architecture & State

Understanding how Lima handles state is critical for modifying this sandbox:

* **Idempotent Provisioning:** Unlike standard cloud servers, Lima executes `provision` scripts on **every single boot**. To prevent 3-minute boot times and configuration overwrites, our YAML uses hidden marker files (`/etc/.lima_system_init_done` and `~/.lima_user_init_done`). Heavy installations run *only* on the first boot.
* **Persistent Storage:** Your home directory (`~`), installed software (`apt`/`npm`), and system configurations (like `sudoers`) are permanently saved to the virtual disk. They survive reboots and mount edits.
* **Host-Mounted Persistence (.gemini):** The `.gemini` configuration folder is explicitly mounted from the host into the VM. This ensures that your Gemini authentication (OAuth tokens) and `installation_id` persist even if you completely delete and recreate the VM.
* **Volatile Storage (`/tmp`):** Ubuntu natively wipes its internal `/tmp` directory on every restart. While our host mounts live inside `/tmp/`, do not store unmounted VM files there, or they will be deleted during the next boot.

---

## Configuration

**1. Secrets & Paths**
All secrets, host paths, and VM configurations are defined in `.env`. Update this file before starting the VM to ensure proper substitution.

*(Note on Mac `envsubst`: The YAML avoids internal bash variables like `$HOME` in favor of `~` and hardcoded paths to prevent Mac's `envsubst` from corrupting the Linux scripts before boot).*

**2. SSH Setup**
Ensure your public key is available at the path defined in your configuration. The provisioning script appends this to the VM's `authorized_keys` alongside Lima's internal control keys.

**3. Init Password**
The `VM_INIT_PASS` variable sets the password for the first boot. Because of our "true init" marker files, you can safely log into the VM, type `passwd` to change it, and Lima will never overwrite your new password on subsequent reboots.

**4. AI Base Instructions & Auth**
System instructions and authentication data for Gemini are loaded from the host via the mounted `.gemini` directory.
* **Instructions Path:** `.gemini/system-instructions.md`
* **Auth Storage:** The CLI will automatically write authentication tokens to this mounted folder, preserving them across VM rebuilds.

---

## Usage

**Create the VM**
Uses the wrapper script to inject environment variables and boot the instance:
```bash
./create.sh lima-gemini.yaml