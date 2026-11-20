# 03 – Your First Repo, Cloning, and Multiple Identities

## Create a repo from scratch

```bash
mkdir -p myproject && cd myproject
git init                       # creates .git/, default branch from init.defaultBranch
nvim .gitignore                # BEFORE the first commit (see below)
nvim README.md
git status
git add .
git commit -m "init"
```

### Put it on GitHub

**Option A: one command with `gh`** (needs at least one commit, otherwise `--push` fails):

```bash
gh repo create myproject --private --source=. --remote=origin --push
```

- Pass **either** `--private` or `--public`; without one, `gh` prompts (non-interactive runs fail). Default to `--private` and open it up later. Pushing a secret to a public repo is irreversible in practice.
- Useful extras: `-d "description"`, `--add-readme` (for brand-new repos created from scratch on GitHub; not needed when you push an existing local repo), `-l MIT` (license), `-g Python` (gitignore template), `--clone`.

**Option B: manual** (create the empty repo on github.com first):

```bash
git remote add origin git@github.com:<user>/myproject.git
git push -u origin main        # -u sets upstream so later `git push`/`git pull` need no arguments
```

If you get `src refspec main does not match any`, you have no commit yet (or your branch is named `master`; check `git branch`).

## `.gitignore`

Create it **before** the first `git add .`, since ignoring a file that is already tracked does nothing.

```gitignore
# secrets
.env
*.pem
*.key
# build / deps
node_modules/
target/
__pycache__/
dist/
# editor / OS
.vscode/
*.swp
.DS_Store
```

Rules: `dir/` matches directories only; `*.log` matches anywhere; `/build` anchors to the repo root; `!keep.log` re-includes.

Stop tracking something that was already committed (keeps the file on disk):

```bash
git rm --cached path/to/file         # single file
git rm -r --cached path/to/dir       # directory
git commit -m "chore: stop tracking dir"
```

Check why a file is (not) ignored: `git check-ignore -v path/to/file`.

Per-machine ignores (editor files etc.) go in a global file, not each repo:

```bash
git config --global core.excludesfile ~/.config/git/ignore
```

## Clone

```bash
git clone git@github.com:<user>/<repo>.git          # SSH
git clone <url> mydir                               # into a custom folder
git clone --depth 1 <url>                           # shallow: latest snapshot only (fast, limited history)
git clone --branch <name> <url>                     # check out a specific branch
git clone --recurse-submodules <url>                # include submodules
gh repo clone <user>/<repo>                         # same, using gh (also handles fork remotes)
```

Inspect remotes afterward: `git remote -v`.

## Identity per repo (second GitHub account, work vs personal)

A repo needs the right **name/email**, the right **SSH key**, and the right **signing key**.

### Simple: per-repo local config

```bash
git config --local user.name  "Work Name"
git config --local user.email "work@example.com"
git config --local user.signingkey ~/.ssh/id_work.pub
```

> **Correction to the old notes:** this isn't "not recommended". It's the standard per-repo method. It just doesn't scale if you have many repos.

### Scalable: `includeIf` by directory

```ini
# ~/.gitconfig
[user]
    name = Personal Name
    email = ID+me@users.noreply.github.com
    signingkey = ~/.ssh/id_ed25519.pub

[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work
```

```ini
# ~/.gitconfig-work
[user]
    name = Work Name
    email = work@example.com
    signingkey = ~/.ssh/id_work.pub
```

Every repo under `~/work/` now uses the work identity automatically. (Trailing `/` matters.)

### The SSH side: one key per account via `Host` aliases

Because `IdentitiesOnly yes` pins one key per host, a second account needs its own alias:

```ssh-config
Host github-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_work
    AddKeysToAgent yes
    IdentitiesOnly yes
```

Then clone/add remotes using the alias:

```bash
git clone git@github-work:company/repo.git
git remote set-url origin git@github-work:company/repo.git
```

Upload `id_work.pub` to the work account as both an **authentication** and a **signing** key, and add its line to `~/.ssh/allowed_signers`.

### Verify what git will use

```bash
git config user.email          # effective value in this repo
git config --show-origin --get-all user.email
git var GIT_AUTHOR_IDENT
```

Wrong email already committed (last commit only): `git commit --amend --reset-author --no-edit` **[REWRITES HISTORY]**.
