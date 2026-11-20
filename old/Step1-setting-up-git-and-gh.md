# Step 1: Setting Up Git and GitHub CLI (SSH & Commit Signing)

This guide covers setting up **Git** and the **GitHub CLI (`gh`)** with a secure, SSH-first workflow. It configures SSH authentication, persistent agent caching, and SSH-based commit/tag signing for verified commits on GitHub.

---

## 1. Install Required Packages

On Arch Linux, install Git, GitHub CLI, and OpenSSH:

```bash
sudo pacman -S git github-cli openssh
```

---

## 2. Configure Git Identity

Configure your default username, email, and primary branch. 

> [!TIP]
> If you want to keep your personal email private, use your GitHub noreply address from **GitHub Settings → Emails** (e.g., `ID+username@users.noreply.github.com`).

```bash
git config --global user.name "Your Name"
git config --global user.email "ID+username@users.noreply.github.com"
git config --global init.defaultBranch main
```

---

## 3. Generate an SSH Key Pair

Create a modern Ed25519 key pair with an identifiable label:

```bash
ssh-keygen -t ed25519 -C "arch-desktop" -f ~/.ssh/id_ed25519
```
*(Enter a secure passphrase when prompted.)*

Enforce proper directory and file permissions:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
```

---

## 4. Configure `ssh-agent` and SSH Client

To avoid retyping your passphrase on every Git operation, configure the user-level systemd `ssh-agent` service and configure SSH to add keys automatically.

### 4.1 Enable the agent service
```bash
systemctl --user enable --now ssh-agent.service
```

### 4.2 Set `SSH_AUTH_SOCK` environment variable
Make sure your environment points to the user agent socket:

```bash
mkdir -p ~/.config/environment.d
echo 'SSH_AUTH_SOCK=%t/ssh-agent.socket' > ~/.config/environment.d/ssh-agent.conf
```

* Alternatively, if you use **Hyprland**, add this to `~/.config/hypr/hyprland.conf`:
  ```ini
  env = SSH_AUTH_SOCK,$XDG_RUNTIME_DIR/ssh-agent.socket
  ```
* For your current terminal session before logging out/in:
  ```bash
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
  ```

### 4.3 Configure `~/.ssh/config`
Add a Host entry for GitHub:

```ssh-config
Host github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    IdentitiesOnly yes
```

Ensure permissions on the config file:
```bash
chmod 600 ~/.ssh/config
```

Load your key into the agent:
```bash
ssh-add ~/.ssh/id_ed25519
```

---

## 5. Authenticate with GitHub CLI (`gh`)

Request the `admin:ssh_signing_key` scope during login so you can upload your signing key in the next step without an extra `gh auth refresh`.

```bash
gh auth login -h github.com -p ssh -w -s admin:ssh_signing_key
```

### Interactive Prompts:
1. **Account**: `GitHub.com`
2. **Preferred protocol for Git operations**: `SSH`
3. **Upload SSH public key**: Select `~/.ssh/id_ed25519.pub`
4. **Title for key**: `arch-desktop`
5. **Authenticate**: Open browser, enter one-time code at `github.com/login/device`.

Set the global protocol to SSH:
```bash
gh config set git_protocol ssh
# gh auth setup-git # this command is also used but in this case we won't be needing it.
```

*(Optional but recommended)* Force Git to rewrite HTTPS URLs to SSH:
```bash
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

---

## 6. Configure SSH Commit & Tag Signing

GitHub treats **Authentication Keys** and **Signing Keys** separately. You must upload the public key a second time with the `signing` type to receive the **Verified** badge.

### 6.1 Configure Git to sign with SSH
```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true
```

### 6.2 Upload the signing key to GitHub
```bash
gh ssh-key add ~/.ssh/id_ed25519.pub --type signing --title "arch-desktop-signing"
```

### 6.3 Configure local allowed signers
Allow Git to verify your signed commits locally:

```bash
echo "$(git config --get user.email) $(cat ~/.ssh/id_ed25519.pub)" > ~/.ssh/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

---

## 7. Verification Checklist

Run these commands to verify each part of the setup:

```bash
# 1. Test SSH connection to GitHub (confirm fingerprint matches GitHub's published fingerprints)
ssh -T git@github.com
# Expected output: "Hi <username>! You've successfully authenticated..."

# 2. Check GitHub CLI authentication and active scopes
gh auth status
# Expected output: Logged in, Protocol: ssh, Token scopes: ... admin:ssh_signing_key

# 3. Check CLI git protocol
gh config get git_protocol
# Expected output: ssh

# 4. Check that both authentication and signing keys are present
gh ssh-key list

# 5. Check key loaded in agent
ssh-add -l

# 6. Test a signed commit (inside a git repository)
git commit --allow-empty -m "test: signed commit"
git log --show-signature -1
# Expected output: "Good "git" signature for <email> with ED25519 key ..."

# 7. Push and inspect on GitHub
git push
# Should show "Verified" badge next to the commit
```

---

## 8. Common Pitfalls & Notes

* **`gh repo create` syntax**: `--origin` is not a valid flag. Use `--source=. --push` (and `--remote=<name>` only if targeting a custom remote name).
* **Repository names**: Avoid characters like `&` in repo names; use hyphens (`-`) instead.
* **API vs Transport**: `gh` uses OAuth tokens for GitHub REST/GraphQL API interactions; SSH keys only handle Git transport (`git clone`, `git push`, `git fetch`).
* **Repeated passphrase prompts**: If you are repeatedly prompted for a passphrase despite running `ssh-agent`, verify that `echo $SSH_AUTH_SOCK` is set and points to `$XDG_RUNTIME_DIR/ssh-agent.socket`.
