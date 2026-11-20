# 14 – Troubleshooting: error → cause → fix

## Push/pull

| Message | Cause | Fix |
|---|---|---|
| `! [rejected] main -> main (fetch first)` / `non-fast-forward` | Remote has commits you don't | `git pull --rebase` (or `git pull`), resolve, `git push` |
| `hint: You have divergent branches and need to specify how to reconcile them` | `git pull` with both sides changed and no `pull.*` preference | Choose once: `git config --global pull.ff only` (or `pull.rebase true`), then `git pull --rebase` / `git merge` |
| `fatal: Not possible to fast-forward, aborting.` | `--ff-only` and branches diverged | `git pull --rebase` or `git merge origin/<branch>` |
| `error: failed to push some refs ... tip of your current branch is behind` | same as fetch first | pull, then push |
| `fatal: The current branch X has no upstream branch` | never pushed with `-u` | `git push -u origin X` (or `push.autoSetupRemote true`) |
| `src refspec main does not match any` | no commits yet, or branch isn't called `main` | commit something; check `git branch` |
| `remote: error: GH006: Protected branch update failed` | pushing directly to a protected branch | push a feature branch and open a PR |
| `remote: error: File X is 123 MB; this exceeds GitHub's file size limit of 100 MB` | big file in a commit | remove from history (`git filter-repo`) or use Git LFS; deleting in a new commit isn't enough |
| `fatal: refusing to merge unrelated histories` | two repos with no common ancestor (e.g. GitHub-created README vs local init) | `git pull origin main --allow-unrelated-histories` (only if you're sure) |
| `fatal: remote origin already exists.` | adding a remote that exists | `git remote set-url origin <url>` or `git remote remove origin` |
| `Updates were rejected ... stale info` (force-with-lease) | remote changed since your last fetch | `git fetch`, review what's new, integrate, push again |

## Authentication / SSH

| Message | Fix |
|---|---|
| `git@github.com: Permission denied (publickey).` | `ssh-add -l` (key loaded?) → `ssh-add ~/.ssh/id_ed25519`; `ssh -vT git@github.com` to see which key is offered; confirm the **public key is uploaded** to the *right* account; check `~/.ssh/config` `IdentityFile`/`Host` |
| `Could not open a connection to your authentication agent.` | `SSH_AUTH_SOCK` unset: `systemctl --user status ssh-agent`, `echo $SSH_AUTH_SOCK`, see `02-setup-ssh-signing.md` §4 |
| Passphrase asked on every operation | agent not running / key not added; `AddKeysToAgent yes` missing |
| `Host key verification failed` | known_hosts mismatch: verify GitHub's published fingerprint, then `ssh-keygen -R github.com` and reconnect |
| `remote: Repository not found.` | wrong URL/account, or private repo and wrong credentials (GitHub reports 404 for no-access) |
| `gh: To use GitHub CLI in a GitHub Actions workflow, set GH_TOKEN` / `HTTP 401` | `gh auth status`; `gh auth login` again; check env `GH_TOKEN` isn't stale |
| `gh ... needs the "X" scope` / `HTTP 403 Resource not accessible` | `gh auth refresh -s <scope>` (e.g. `delete_repo`, `admin:ssh_signing_key`) |

## Signing

| Message | Fix |
|---|---|
| `error: Load key "...": ... / fatal: failed to write commit object` on `git commit` | signing key not loaded: `ssh-add -l`, `ssh-add <key>`; or one-off `git commit --no-gpg-sign` |
| `Signing failed: agent refused operation` | key needs passphrase and isn't in the agent: `ssh-add ~/.ssh/id_ed25519` |
| Commit shows "Unverified" on GitHub | signing key uploaded as **signing** type? commit email verified on your account? `git log --show-signature -1` locally good? |
| `git log --show-signature` says `No signature` / can't verify | `gpg.ssh.allowedSignersFile` missing or lacks your email+key line |

## Local state

| Message | Fix |
|---|---|
| `fatal: not a git repository (or any of the parent directories): .git` | wrong directory, or you never ran `git init` |
| `fatal: Unable to create '.../.git/index.lock': File exists.` | a git process crashed. Make sure none is running (`pgrep git`), then `rm .git/index.lock` |
| `error: Your local changes to the following files would be overwritten by checkout/merge` | commit or `git stash push -u` first, then retry; don't `--force` |
| `error: pathspec 'x' did not match any file(s) known to git` | typo / branch not fetched (`git fetch`) / file untracked |
| `You are in 'detached HEAD' state` | `git switch -c <name>` to keep commits, or `git switch -` to leave |
| `fatal: You have not concluded your merge (MERGE_HEAD exists).` | finish: resolve + `git commit`, or `git merge --abort` |
| `fatal: It seems that there is already a rebase-merge directory` | `git rebase --continue` or `--abort` (last resort: delete `.git/rebase-merge` after confirming no rebase is active) |
| `warning: LF will be replaced by CRLF` / noisy line-ending diffs | add `.gitattributes` (`* text=auto eol=lf`) and `core.autocrlf` per `12-config-and-aliases.md` |
| File still tracked after adding to `.gitignore` | `git rm --cached <file>` and commit |
| `Please tell me who you are` | set `user.name`/`user.email` (`02-setup-ssh-signing.md` §2) |
| Wrong author/email on my commit | last commit: `git commit --amend --reset-author --no-edit`; several: interactive rebase with `exec git commit --amend --reset-author --no-edit` **[REWRITES HISTORY]** |
| Committed on the wrong branch | see "Recipes" in `06-undo-and-recovery.md` |
| `error: option 'mainline' expects a number greater than zero` | you used `git revert -m "msg"`; `-m` is the parent number. Use `git revert --no-edit <sha>` |
| `fatal: you must specify path(s) to restore` | `git restore` needs a path; use `git restore .` |
| `error: the branch 'x' is not fully merged` | merge it first, or `git branch -D x` if you really mean it |

## `gh` specific

| Message | Fix |
|---|---|
| `could not add label: 'feature' not found` | create it first: `gh label create feature` |
| `unknown flag: --lable` | typo: `--label` |
| `no pull requests found for branch "x"` | push the branch and `gh pr create` |
| `pull request create failed: ... No commits between main and x` | nothing to PR: you have no commits ahead of the base |
| `gh pr merge`: `--merge, --rebase, or --squash required` | add a strategy flag in non-interactive use |
| `GraphQL: Resource not accessible by personal access token` | token lacks scope; `gh auth refresh -s ...` |

## Diagnostic commands

```bash
git status -sb
git log --oneline --graph --decorate --all -20
git remote -v
git config --show-origin --get-all user.email
git reflog -20
ssh -vT git@github.com
gh auth status
GIT_TRACE=1 git <command>           # see what git is doing
GIT_CURL_VERBOSE=1 git fetch        # https transport debugging
```
