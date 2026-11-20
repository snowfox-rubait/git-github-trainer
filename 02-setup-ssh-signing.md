# 02 – Setup: Git, `gh`, SSH and Commit Signing (Arch Linux)

Goal: SSH-based authentication for git transport, `gh` for the GitHub API, and SSH-signed commits showing **Verified** on GitHub.

**Two separate credentials exist; don't mix them up:**

| Credential | Used for | Stored |
|---|---|---|
| SSH key | `git clone/fetch/push` (transport) | `~/.ssh/` + ssh-agent |
| OAuth token | `gh` commands (issues, PRs, API) | OS keyring, or plaintext `~/.config/gh/hosts.yml` (see 5.3) |

GitHub also treats SSH **authentication keys** and **signing keys** as separate uploads, even when it's the same key file.

---

## 1. Install

```bash
sudo pacman -S git github-cli openssh
```

## 2. Identity and defaults

```bash
git config --global user.name  "Your Name"
git config --global user.email "ID+username@users.noreply.github.com"   # GitHub Settings → Emails
git config --global init.defaultBranch main
```

The commit email must be one verified on your GitHub account (the noreply address counts) or commits won't show Verified.

## 3. Generate the SSH key

```bash
ssh-keygen -t ed25519 -C "arch-desktop" -f ~/.ssh/id_ed25519   # set a passphrase
chmod 700 ~/.ssh
```

(`ssh-keygen` already creates the private key with mode 600; the `chmod 600` is harmless but redundant.)

Optional hardening: a hardware key (`ssh-keygen -t ed25519-sk`) keeps the private key off disk.

## 4. ssh-agent (systemd user service)

```bash
systemctl --user enable --now ssh-agent.service
```

If the unit isn't found, check `systemctl --user list-unit-files | grep ssh-agent` and the Arch Wiki "SSH keys" page for a hand-written unit.

### 4.1 Point `SSH_AUTH_SOCK` at the agent

```bash
mkdir -p ~/.config/environment.d
echo 'SSH_AUTH_SOCK=${XDG_RUNTIME_DIR}/ssh-agent.socket' > ~/.config/environment.d/ssh-agent.conf
```

> **Fix vs. the old notes:** `environment.d` does **not** expand systemd *specifiers* like `%t`; those only work in unit files. Use `${XDG_RUNTIME_DIR}`.

`environment.d` is only read by the systemd user manager. If Hyprland (or any compositor) is started from a TTY without importing that environment, add it explicitly:

```ini
# ~/.config/hypr/hyprland.conf
env = SSH_AUTH_SOCK,$XDG_RUNTIME_DIR/ssh-agent.socket
```

Current shell, before re-login:

```bash
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
```

### 4.2 `~/.ssh/config`

```ssh-config
Host github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    IdentitiesOnly yes
```

```bash
chmod 600 ~/.ssh/config
ssh-add ~/.ssh/id_ed25519      # prompts for passphrase once
```

The agent does **not** survive a reboot; with `AddKeysToAgent yes` you type the passphrase once per login on first use.

## 5. Authenticate `gh`

```bash
gh auth login -h github.com -p ssh -w -s admin:ssh_signing_key
```

- `-h` host, `-p ssh` protocol, `-w` browser device-flow, `-s` extra scope (needed to upload the signing key).
- Because `-h` and `-p` are given, those prompts are skipped. You'll still be asked whether to upload your public key (say yes, title `arch-desktop`).

### 5.1 Verify

```bash
gh auth status
gh config get git_protocol      # ssh
```

(`gh auth login -p ssh` already sets the protocol, so `gh config set git_protocol ssh` is only needed if it shows something else. `gh auth setup-git` is for HTTPS credential helpers and isn't needed here.)

### 5.2 Rewrite URLs: use `pushInsteadOf`, not `insteadOf`

```bash
git config --global url."git@github.com:".pushInsteadOf "https://github.com/"
```

> **Fix vs. the old notes:** the notes recommended `insteadOf`, which forces **every** `https://github.com/...` URL (clones, fetches, AUR `git+https` sources in `makepkg`, container builds) through SSH, and breaks wherever your agent isn't available. `pushInsteadOf` only rewrites URLs used for **pushing**, which is the part you actually want.

### 5.3 Where is the token stored?

`gh auth status` shows `(keyring)` or the path of `hosts.yml`. Without a Secret Service provider (gnome-keyring, KeePassXC, etc.) running, `gh` falls back to **plaintext** `~/.config/gh/hosts.yml`. Fix it by running a keyring, or accept it knowingly (mode 600 file in your home).

## 6. SSH commit and tag signing

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true
gh ssh-key add ~/.ssh/id_ed25519.pub --type signing --title "arch-desktop-signing"
```

Local verification (`git log --show-signature`):

```bash
echo "$(git config --get user.email) $(cat ~/.ssh/id_ed25519.pub)" >> ~/.ssh/allowed_signers   # >> to append more identities
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

### Trade-offs to know

- The **same key** is used for auth and signing. If it leaks, both are compromised. Acceptable for a personal machine; use a separate signing key if you want separation.
- `commit.gpgsign true` globally means **every** commit needs the key in an agent. In scripts, containers, CI, or another machine it fails with `error: Load key ... / agent refused operation`. Escape hatch: `git commit --no-gpg-sign`, or `git -c commit.gpgsign=false commit ...`.
- `git rebase` re-signs rewritten commits with **your** key and committer identity. Rebasing someone else's commits makes them appear signed by you.

## 7. Verification checklist

```bash
ssh -T git@github.com                       # "Hi <user>! You've successfully authenticated"
gh auth status                              # logged in, scopes include admin:ssh_signing_key
gh ssh-key list                             # shows BOTH an authentication and a signing entry
ssh-add -l                                  # key loaded in agent
git commit --allow-empty -m "test: signed commit"
git log --show-signature -1                 # Good "git" signature for <email> with ED25519 key ...
git push                                    # then check for the Verified badge on GitHub
```

On first `ssh -T`, compare the offered fingerprint to GitHub's published ones (https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints) before typing `yes`.

## 8. Pitfalls

- `gh repo create`: there is no `--origin` flag. Use `--source=. --push` (and `--remote=<name>` only for a custom remote name).
- Repo names: avoid `&` and spaces; use hyphens.
- Repeated passphrase prompts: `echo $SSH_AUTH_SOCK` must equal `$XDG_RUNTIME_DIR/ssh-agent.socket`, and `ssh-add -l` must list the key.
- Commits not Verified: check (a) signing key uploaded with `--type signing`, (b) commit email is verified on your account, (c) `git log --show-signature -1` shows a good local signature.
- Second GitHub account: you need its own key + `Host` alias + signing key. See `03-first-repo.md`.
