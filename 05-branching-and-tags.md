# 05 – Branching, Merging, Tags

## Branch basics

```bash
git branch                       # list local branches (* = current)
git branch -vv                   # + last commit and upstream/ahead-behind
git branch -a                    # local + remote-tracking
git branch -r                    # remote-tracking only
git branch --merged              # already merged into current (safe to delete)
git branch --no-merged           # not yet merged
```

### Create and switch

```bash
git branch feature-x             # create only (you stay where you are)
git switch feature-x             # move to it
git switch -c feature-x          # create AND switch (what you'll use 95% of the time)
git switch -c hotfix v1.2.0      # create from a specific start point (tag/commit/branch)
git switch -                     # jump back to the previous branch
```

### Rename / delete

```bash
git branch -m old-name new-name        # rename (omit old-name to rename current)
git branch -d feature-x                # delete if fully merged; refuses otherwise (tested)
git branch -D feature-x                # [DESTRUCTIVE] force-delete unmerged (recoverable via reflog)
git push origin --delete feature-x     # delete on the remote
git fetch --prune                      # drop local origin/* refs for branches deleted remotely
```

### Fetching other people's branches

```bash
git fetch                       # updates origin/* (does not change your files)
git branch -r                   # see them
git switch some-branch          # git auto-creates a local tracking branch from origin/some-branch
gh pr checkout 123              # same idea, but by PR number (works for fork PRs too)
```

## Merging

```bash
git switch main
git pull --ff-only
git merge feature-x             # bring feature-x INTO the branch you're on
```

Three outcomes:

| Situation | Result |
|---|---|
| `main` hasn't moved since you branched | **fast-forward**: pointer slides, no merge commit |
| Both moved, no overlapping edits | **merge commit** created automatically |
| Both edited the same lines | **conflict**, see `09-merge-conflicts.md` |

Variants:

```bash
git merge --no-ff feature-x       # always create a merge commit (keeps the branch visible in history)
git merge --ff-only feature-x     # fail instead of creating a merge commit
git merge --squash feature-x      # stage the combined changes WITHOUT committing; you then `git commit` (one commit, no link to the branch)
git merge --abort                 # cancel an in-progress conflicted merge
```

> **Correction to the old notes:** `git merge <branch> -m "..."` only sets the message when a merge commit is actually created. On a fast-forward it's ignored (tested: *"Fast-forward (no commit created; -m option ignored)"*). Also, a `#` comment inside the quotes becomes part of the message. Keep comments outside the quoted string.

### Getting main's updates into your feature branch

Two options:

```bash
git switch feature-x
git merge main                    # SAFE: adds a merge commit, history is preserved
# or
git rebase main                   # [REWRITES HISTORY] replays your commits on top of main (see 10-history-rewriting.md)
```

Rule of thumb: **merge** if the branch is shared or already pushed and others use it; **rebase** for a local/personal branch to keep history linear.

### Which merge strategy for a PR?

| Strategy | History result | Use when |
|---|---|---|
| Merge commit | all commits + a merge commit | you want full history/context |
| Squash and merge | one commit on main | messy WIP commits; one logical change per PR |
| Rebase and merge | commits replayed linearly, no merge commit | clean small commits you want preserved |

## `checkout` vs `switch` vs `restore`

`git checkout` is the old Swiss-army knife that did three unrelated jobs. Modern git split it:

| Job | Old | New |
|---|---|---|
| Change branch | `git checkout main` | `git switch main` |
| Create + change branch | `git checkout -b x` | `git switch -c x` |
| Restore a file | `git checkout -- file` | `git restore file` |
| Look at an old commit (detached) | `git checkout <sha>` | `git switch --detach <sha>` |

`checkout` still works; the new commands just refuse to do the dangerous-by-accident thing. (`git switch` won't overwrite a file; `git checkout <name>` is ambiguous if a branch and a file share a name.)

## Detached HEAD

Happens when you check out a commit/tag directly. Browsing is safe. If you make commits there, they belong to no branch:

```bash
git switch -c keep-this        # make a branch at the current commit → saves your work
git switch main                # or just leave; commits become unreachable (still in reflog ~30 days)
```

## Tags

A tag is a permanent name for one commit (releases, versions).

```bash
git tag                          # list
git tag -a v1.0.0 -m "release 1.0.0"   # annotated (recommended): has author, date, message
git tag v1.0.0-rc1               # lightweight: just a name
git tag -a v0.9.0 <commit> -m "..."    # tag an older commit
git show v1.0.0                  # details
git push origin v1.0.0           # tags are NOT pushed by default
git push --follow-tags           # push commits + annotated tags reachable from them
git push origin --tags           # push ALL tags (careful)
git tag -d v1.0.0                # delete locally
git push origin --delete v1.0.0  # [DESTRUCTIVE-ish] delete on remote
```

With `tag.gpgsign true` (from `02-setup-ssh-signing.md`), tags you create are signed annotated tags and git will want a message. Verify with `git tag -v v1.0.0`.

Releases on GitHub: `gh release create v1.0.0 --generate-notes` (see `11-github-cli.md`).

## Worktrees: two branches checked out at once

Instead of stashing to look at another branch:

```bash
git worktree add ../myproject-hotfix hotfix-branch      # new folder with that branch checked out
git worktree add -b new-branch ../path main             # create branch + folder
git worktree list
git worktree remove ../myproject-hotfix
```

They share one `.git` database, so it's cheap. A branch can be checked out in only one worktree at a time.

## Branch naming

`type/short-description`: `feat/oauth-login`, `fix/null-deref-parser`, `docs/readme-install`, `chore/bump-deps`. Lowercase, hyphens, optionally with the issue number: `fix/42-login-redirect`.
