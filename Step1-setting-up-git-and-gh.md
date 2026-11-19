this will be ssh and oauth heavy instead of https based.

make sure that you have git, github cli and openssh or dropbear

for arch, the command is like : `sudo pacman -S git github-cli openssh`

then you need to authenticate in each tools. 

let's start with git first. 

run these commands :

```
git config --global user.name "Your User Name"
git config --global user.email "youremail@example.com" # or your github provided email if you want to keep your's private e.g. ID+username@users.noreply.github.com
git config --global init.defaultBranch main
```

generate ssh key if you already don't have one.

```
ssh-keygen -t ed25519 -C "youremail@example.com" -f ~/.ssh/id_ed25519
```
this will ask for passphrase. 

if you don't want to keep retyping the passphrase, run this once : 

```
systemctl --user enable --now ssh-agent.service
```

Point your shell at its socket (add to ~/.zshrc / ~/.bashrc, or your Hyprland env):
```
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
```

Then make SSH load keys into the agent on first use, in ~/.ssh/config:
```
Host github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    IdentitiesOnly yes
```

then run this : 
```
chmod 700 ~/.ssh && chmod 600 ~/.ssh/config ~/.ssh/id_ed25519
```


Log in with gh and let it upload the key
```
gh auth login
```

Pick these answers:

GitHub.com
SSH as the preferred git protocol
Select your id_ed25519.pub when asked which key to upload
Give the key a title (e.g. arch-desktop)
Login with a web browser: it shows a one-time code, you paste it at github.com/login/device

verify : 

```
ssh -T git@github.com     # "Hi <username>! You've successfully authenticated..."
gh auth status            # logged in, protocol: ssh
gh config get git_protocol
```

force ssh everywhere : 

```
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

Next I’d suggest signing commits with the same SSH key, since it’s a few lines of config and gives you the “Verified” badge on GitHub. There’s one extra step people often miss: GitHub treats the signing key as separate from the auth key, so you have to upload the same public key a second time, as a “Signing Key”.

```
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true

gh ssh-key add ~/.ssh/id_ed25519.pub --type signing --title "arch-desktop-signing"
```

If gh ssh-key add complains about scopes, run gh auth refresh -h github.com -s admin:ssh_signing_key first.

```
echo "you@example.com $(cat ~/.ssh/id_ed25519.pub)" > ~/.ssh/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

Use the same email as your user.email. Then test in your trainer repo:
```
git commit --allow-empty -m "test signed commit"
git log --show-signature -1
git push
```


