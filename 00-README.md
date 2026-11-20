# Git & GitHub CLI Handbook

A personal reference for Git and `gh`, organized by **the question you're asking**, not by tutorial order. Every command here was checked against `git 2.43` and `gh 2.89`; the risky claims (undo commands, conflict behavior, `ours`/`theirs`, `revert -m`) were run in a scratch repo.

## How to use it

| You are thinking... | Open |
|---|---|
| "What is the index? What is HEAD? Why are there so many undo commands?" | `01-mental-model.md` |
| "New machine, set up git + gh + SSH + signing" | `02-setup-ssh-signing.md` |
| "Start a project / clone one / use a second GitHub account" | `03-first-repo.md` |
| "The everyday loop: status, add, commit, push, stash" | `04-daily-workflow.md` |
| "Branches, merging, tags, detached HEAD" | `05-branching-and-tags.md` |
| "I messed up. Undo it." | `06-undo-and-recovery.md` |
| "Who changed this? When did it break?" | `07-inspecting-history.md` |
| "Remotes, push rejected, forks, syncing" | `08-remotes-and-forks.md` |
| "CONFLICT!" | `09-merge-conflicts.md` |
| "Rebase, squash, cherry-pick, clean up history" | `10-history-rewriting.md` |
| "Issues, PRs, releases, CI from the terminal" | `11-github-cli.md` |
| "Make git nicer: config, aliases" | `12-config-and-aliases.md` |
| "What should I do, as a habit?" | `13-best-practices.md` |
| "I got this error message" | `14-troubleshooting.md` |
| "Just give me the command" | `15-cheatsheet.md` |

Hands-on labs live in `practice/` (run them in a throwaway directory; they create their own repos under a temp dir).

## Legend

- **[DESTRUCTIVE]**: can permanently lose uncommitted work or rewrite shared history. Read the warning, and prefer the safer alternative listed beside it.
- **[REWRITES HISTORY]**: changes commit hashes. Safe on commits only you have; dangerous once others have pulled them.
- `<angle brackets>`: replace with your value.

## Five golden rules

1. **Commit early, commit often.** Committed work is recoverable via `git reflog` for weeks. Uncommitted work is not.
2. **Never work directly on `main`.** One branch per change; merge through a PR.
3. **Run `git status` before and `git diff --staged` before every commit.** Most bad commits are caught here.
4. **Never rewrite history others have pulled.** Use `git revert` instead.
5. **Before any `[DESTRUCTIVE]` command, run the dry-run or look-first version** (`git clean -n`, `git status`, `git diff`, `git stash`).

## Conventions in the examples

- Default branch is `main`; remote is `origin`.
- `#` comments explain flags. Don't paste them if your shell complains (zsh/bash are fine, comments are valid).
- In zsh, quote reflog and stash refs if you hit globbing errors: `git stash pop 'stash@{0}'`.

## Practice labs

| Script | What it does |
|---|---|
| `practice/conflict-lab.sh` | 3 throwaway repos left mid-conflict (content, modify/delete, rebase) |
| `practice/undo-lab.sh` | 4 recovery exercises with answers |

Both use an isolated git config in their temp directory (no signing, fixed identity) and never touch your `~/.gitconfig` or any real repo. Delete the printed lab directory when finished.
