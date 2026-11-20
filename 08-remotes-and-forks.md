# 08 – Remotes, Pushing, Forks

## Remotes

A remote is a named URL to another copy of the repo. `origin` is the default name for where you cloned from.

```bash
git remote -v                                   # list with URLs
git remote add upstream git@github.com:owner/repo.git
git remote rename origin old
git remote set-url origin git@github.com:me/repo.git
git remote remove upstream
git remote show origin                          # tracking info, stale branches
```

## `fetch` vs `pull` vs `push`

| Command | Does | Touches your files? |
|---|---|---|
| `git fetch` | downloads new commits, updates `origin/*` | no |
| `git pull` | `fetch` + `merge` (or `rebase`) into your current branch | yes |
| `git push` | uploads your branch commits to the remote | no |

```bash
git fetch                  # origin only
git fetch --all --prune    # all remotes; delete stale origin/* refs
git pull                   # = git fetch && git merge origin/<branch>
git pull --ff-only         # fail rather than create a merge commit
git pull --rebase          # fetch + rebase your local commits on top
```

Make divergent pulls explicit instead of surprising (otherwise git nags with a hint):

```bash
git config --global pull.ff only        # pull never creates merge commits; tells you when you need to decide
# or: git config --global pull.rebase true
```

## Push variants

```bash
git push                                   # to the upstream of the current branch
git push -u origin <branch>                # first push: set upstream (so plain push/pull work later)
git push origin <local>:<remote-name>      # push under a different remote name
git push origin --delete <branch>          # delete remote branch
git push --tags | --follow-tags            # see 05
git push --force-with-lease                # force push, but only if remote is what you last saw
git push --force                           # [DESTRUCTIVE] overwrite remote unconditionally. Avoid.
```

Skip `-u` forever: `git config --global push.autoSetupRemote true` (Git ≥ 2.37) makes the first plain `git push` set the upstream.

### "rejected: fetch first / non-fast-forward"

The remote has commits you don't. (Tested: `! [rejected] main -> main (fetch first)`.)

```bash
git pull --rebase        # or: git pull (merge), then resolve conflicts if any
git push
```

Force only if *you* intentionally rewrote the branch (rebase/amend) **and** it's your own branch.

### `--force-with-lease` has a loophole

Bare `--force-with-lease` compares the remote to your **remote-tracking ref** (`origin/<branch>`). If something (an IDE, a background `git fetch`, your own `git fetch`) updated that ref without you reviewing the new commits, the lease passes and you overwrite them. (Tested: after a fetch, the lease push was not refused.)

Safer forms:

```bash
git push --force-with-lease --force-if-includes       # also requires that your local branch includes the remote tip you fetched
git push --force-with-lease=<branch>:<expected-sha>   # explicit expected value
```

## Forks vs clones vs branches

| Term | What it is | Where |
|---|---|---|
| **Branch** | a line of development *inside one repo* | same repo |
| **Clone** | your local copy of a repo | your disk |
| **Fork** | a **server-side copy of an entire repo under your GitHub account**, linked to the original | GitHub |

When you can't push to the original (no write access), you **fork** it, push branches to *your fork*, and open a PR from your fork to the original ("upstream"). If you do have write access (a collaborator or teammate), you just push a branch to the repo itself.

### Contribute to someone else's project

```bash
gh repo fork owner/repo --clone --remote     # fork + clone + wires the remotes
cd repo
git remote -v                                # origin = your fork, upstream = original
git switch -c fix/typo
# ...edit, commit...
git push -u origin fix/typo
gh pr create --fill --repo owner/repo        # PR from your fork → upstream (gh asks which; --repo targets the upstream)
```

### Keep your fork up to date

```bash
gh repo sync                                  # sync your local clone's default branch from its remote (fast-forward)
gh repo sync me/repo --source owner/repo      # sync YOUR FORK on GitHub from the upstream repo
gh repo sync me/repo --source owner/repo --force   # [DESTRUCTIVE] hard reset fork's branch to match upstream
```

Plain-git equivalent:

```bash
git fetch upstream
git switch main
git merge --ff-only upstream/main     # or: git rebase upstream/main
git push origin main
```

### Collaborator flow (you have write access)

```
issue created → git switch -c fix/42-thing → commits → git push -u origin fix/42-thing
→ gh pr create → review → merge → git switch main && git pull && git branch -d fix/42-thing
```

Link the PR to the issue so it closes on merge: put `Closes #42` in the PR body.

### Tracking branches

```bash
git branch -vv                               # shows each local branch's upstream, ahead/behind
git branch --set-upstream-to=origin/main main
git push -u origin <branch>
git status -sb                               # ## main...origin/main [ahead 2, behind 1]
```

## Protected branches

If the repo owner protects `main`, a direct push fails with `GH006: Protected branch update failed`. That's by design: open a PR instead. See `13-best-practices.md`.
