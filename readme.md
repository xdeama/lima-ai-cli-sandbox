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

**4. AI Base Instructions**
System instructions for Gemini are loaded from the host and mounted directly into the VM profile via:
`ai-system-instructions/system-instructions.md`

---

## Usage

**Create the VM**
Uses the wrapper script to inject environment variables and boot the instance:
```bash
./create.sh lima-gemini.yaml

```

**Start the VM**

```bash
limactl start gemini

```

**Stop the VM**

```bash
limactl stop gemini

```

**Delete the VM**

```bash
limactl stop gemini && limactl delete gemini

```

**Edit Volume Mounts**
To change host mounts on an existing instance without deleting it (requires a VM restart). Because of the init marker files, the reboot will take seconds, not minutes:

```bash
limactl stop gemini
limactl edit gemini
# After saving and exiting the editor:
limactl start gemini

```

> **Handling SSH Fingerprint Changes After Edits**
> When you edit the configuration via `limactl edit`, Lima generates a new hardware Instance ID to force the VM to update its mounts. Ubuntu's `cloud-init` detects this ID change and assumes the VM was cloned, immediately regenerating the server's SSH host keys as a security precaution.
> Because of this, your next SSH attempt will fail with a `REMOTE HOST IDENTIFICATION HAS CHANGED` warning. Do **not** disable `StrictHostKeyChecking`. Instead, securely purge the old local fingerprint and reconnect:
> ```bash
> # 1. Purge the outdated fingerprint from your Mac's known_hosts
> ssh-keygen -R "[localhost]:<VM_SSH_PORT>"
> 
> ```
> 
> 

> # 2. Reconnect and accept the new secure fingerprint
> 
> 
> ssh -p <VM_SSH_PORT> -o IdentitiesOnly=yes -i  @localhost
> ```
> 
> ```
> 
> 

---

## Connecting

You can connect using Lima's built-in shell wrapper or standard SSH.

**Via Lima:**

```bash
limactl shell gemini

```

**Via SSH:**
*(Note: Ensure `<VM_SSH_PORT>` matches the variable defined in your `.env` file)*

```bash
# Strict identity connection
ssh -p <VM_SSH_PORT> -o IdentitiesOnly=yes -i <path-to-private-key> <vm-username>@localhost

# Standard connection
ssh -p <VM_SSH_PORT> <vm-username>@localhost

```

---

## Maintenance & Tools

The VM provisions automatically with Node.js and `@google/gemini-cli`. To run maintenance or install additional tools manually from within the VM:

```bash
sudo apt-get update
sudo apt-get install -y git curl

```

---

## Debugging

If the VM fails to boot, hangs, or provisioning fails, use the following commands to trace the exact point of failure.

**Check Status:**

```bash
limactl list

```

**VM not finishing the boot phase?** Check the hypervisor standard error log:

```bash
less ~/.lima/gemini/ha.stderr.log

```

**Is the OS ready for login? (Host-side check)** Monitor the serial console output to see if Ubuntu has actually reached the login prompt:

```bash
less "$HOME/.lima/gemini/serialv.log"

```

**Provisioning/Setup errors? (VM-side check)** If you can SSH in but tools are missing or configuration failed, check the `cloud-init` logs where the startup scripts output their results. *(Tip: Check if an Ubuntu `/tmp` wipe caused a path collision).*

```bash
sudo tail -n 50 /var/log/cloud-init-output.log
sudo less /var/log/cloud-init-output.log

```