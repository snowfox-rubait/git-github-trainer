# 12 – Config and Aliases

## Where config lives

| Level | File | Flag | Wins |
|---|---|---|---|
| system | `/etc/gitconfig` | `--system` | lowest |
| global (you) | `~/.gitconfig` or `~/.config/git/config` | `--global` | |
| local (this repo) | `.git/config` | `--local` (default) | highest |

```bash
git config --list --show-origin          # every setting and the file it came from
git config --get user.email              # effective value here
git config --global --edit               # open in $EDITOR
git config --global --unset <key>
```

## A recommended `~/.gitconfig`

Merge the parts you want into your existing file (keep your `user`, signing and `gpg` blocks from `02-setup-ssh-signing.md`):

```ini
[core]
    editor = nvim
    excludesfile = ~/.config/git/ignore     # your global .gitignore
    autocrlf = input                        # normalize CRLF→LF on commit (Linux/macOS); on Windows use "true"

[init]
    defaultBranch = main

[pull]
    ff = only                               # `git pull` never makes surprise merge commits

[push]
    autoSetupRemote = true                  # first `git push` sets upstream (Git ≥ 2.37)
    followTags = true

[fetch]
    prune = true                            # drop stale origin/* refs automatically

[merge]
    conflictStyle = zdiff3                  # show the base in conflict markers

[rerere]
    enabled = true                          # remember conflict resolutions

[rebase]
    autoStash = true
    autoSquash = true                       # honor fixup!/squash! commits with -i

[diff]
    algorithm = histogram                   # usually nicer diffs than the default
    colorMoved = default

[commit]
    verbose = true                          # show the diff in the commit message editor

[branch]
    sort = -committerdate                   # most recently used branches first

[help]
    autocorrect = prompt                    # offer to run the command you probably meant

[url "git@github.com:"]
    pushInsteadOf = https://github.com/     # rewrite push URLs only (not insteadOf; see 02)
```

Each of these is a one-liner: `git config --global pull.ff only`, etc.

## Aliases

```bash
git config --global alias.st  "status -sb"
git config --global alias.co  "switch"
git config --global alias.cb  "switch -c"
git config --global alias.br  "branch -vv"
git config --global alias.cm  "commit -m"
git config --global alias.ca  "commit --amend --no-edit"
git config --global alias.unstage "restore --staged"
git config --global alias.last "log -1 --stat"
git config --global alias.lg  "log --oneline --graph --decorate --all"
git config --global alias.df  "diff --staged"
git config --global alias.wip "!git add -A && git commit -m 'wip' --no-verify"
git config --global alias.pf  "push --force-with-lease --force-if-includes"
git config --global alias.sync "!git fetch --all --prune && git pull --ff-only"
git config --global alias.gone "!git branch -vv | awk '/: gone]/{print \$1}'"   # local branches whose remote was deleted
```

A leading `!` runs a shell command. Use them: `git lg`, `git st`.

Don't alias away your safety: aliasing `reset --hard` or `clean -fd` to something short is how people lose work.

`gh` has its own aliases: `gh alias set co 'pr checkout'`.

## Global gitignore

```bash
mkdir -p ~/.config/git
printf '.DS_Store\n*.swp\n.idea/\n.vscode/\n' > ~/.config/git/ignore
```

(`~/.config/git/ignore` is read automatically even without `core.excludesfile`.)

## Conditional config

Different identity/signing per directory, see `03-first-repo.md` (`includeIf "gitdir:~/work/"`).

## Hooks (local automation)

Scripts in `.git/hooks/` (not versioned) run at git events: `pre-commit`, `commit-msg`, `pre-push`. Share them via a framework such as **pre-commit** (`pip install pre-commit`, `.pre-commit-config.yaml`) or `core.hooksPath`:

```bash
git config core.hooksPath .githooks        # versioned hooks directory in the repo
chmod +x .githooks/pre-commit
```

Skip once: `git commit --no-verify` (use deliberately; CI should enforce the same checks).

## `.gitattributes`

```gitattributes
* text=auto eol=lf          # consistent line endings
*.png binary
*.lock -diff                # don't show noisy lockfile diffs
```

For big binaries use **Git LFS** (`pacman -S git-lfs`, `git lfs install`, `git lfs track "*.psd"`).
