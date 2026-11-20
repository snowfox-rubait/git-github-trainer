# 01 – The Mental Model

Almost every confusing git command (`reset` vs `restore` vs `checkout`, `fetch` vs `pull`) becomes obvious once you know **where your changes live**.

## The four places

```
 working tree  ──git add──▶  index (staging)  ──git commit──▶  local repo (HEAD)  ──git push──▶  remote (origin)
 (your files)  ◀─restore──   (next commit)    ◀──reset────    (commits, branches)  ◀─git fetch──   (GitHub)
```

| Place | What it is | Look at it with |
|---|---|---|
| **Working tree** | The actual files on disk you edit | `git status`, `git diff` |
| **Index / staging area** | A draft of your *next commit* | `git diff --staged` |
| **Local repository** | All commits, branches, tags (inside `.git/`) | `git log` |
| **Remote** | Another copy of the repo (GitHub) | `git fetch`, `git log origin/main` |

### Which command moves data where

| Command | From → To |
|---|---|
| `git add` | working tree → index |
| `git commit` | index → repository |
| `git push` | repository → remote |
| `git fetch` | remote → repository (updates `origin/*` only; never touches your files) |
| `git merge` / `git rebase` | integrates another branch into your current branch and working tree |
| `git pull` | `git fetch` + (`merge` or `rebase`) |
| `git restore <file>` | index (or a commit) → working tree **[DESTRUCTIVE]** |
| `git restore --staged <file>` | HEAD → index (unstage; working tree untouched) |
| `git reset --soft/--mixed/--hard` | moves the branch pointer, and optionally resets index / working tree |
| `git stash` | working tree + index → a hidden commit, then resets both |

## Commits are snapshots, not diffs

A commit stores a complete snapshot of the project plus a pointer to its parent(s). Diffs are computed on the fly. Each commit is named by a hash (`a1b2c3d`) that depends on its content **and its parent**, which is why changing history changes every hash after the change.

```
A ← B ← C ← D        (each arrow points to the parent)
```

## Branches are just sticky-note pointers

A branch is a tiny file containing one commit hash. Creating a branch is free.

```
A ← B ← C ← D   ← main
            ↖
              E ← F   ← feature
```

- **HEAD** says "which branch (or commit) am I on". `HEAD` → `main` → `D`.
- When you commit, the current branch pointer moves forward.
- **Detached HEAD**: HEAD points straight at a commit instead of a branch (e.g. `git checkout a1b2c3d`). Commits you make there belong to no branch and can be lost. Fix: `git switch -c rescue-branch`.

## Remote-tracking branches

`origin/main` is **your local record of where `main` was on the remote the last time you fetched**. It only moves when you `fetch`, `pull` or `push`. This is why "my branch is behind" can be stale until you `git fetch`.

```
git status -sb     # shows ahead/behind relative to origin/<branch>
```

## Merge base and why conflicts happen

When you merge `feature` into `main`, git finds their **merge base** (the last common commit) and does a **three-way merge**: base vs main vs feature. A conflict happens only when **both sides changed the same region** relative to the base (or one deleted a file the other edited). `main` merely having moved ahead is normal and merges cleanly. See `09-merge-conflicts.md`.

## Fast-forward

If `main` hasn't moved since you branched, merging `feature` just slides the `main` pointer forward. No merge commit is created.

## Hashes, refs, and shortcuts

| Ref | Meaning |
|---|---|
| `HEAD` | the commit you're on |
| `HEAD~1` or `HEAD~` | its parent |
| `HEAD~3` | three commits back |
| `HEAD^2` | second parent (of a merge commit) |
| `main`, `origin/main` | branch tips |
| `v1.0` | a tag |
| `HEAD@{2}` | where HEAD was 2 moves ago (reflog) |
| `ORIG_HEAD` | where HEAD was before the last merge/reset/rebase/pull |
| `A..B` | commits reachable from B but not A |

## The one safety net

`git reflog` records every place HEAD has pointed in the last ~90 days (local only). If you **committed** it, you can almost always get it back. If you only had it **uncommitted** and ran `restore`/`reset --hard`/`clean`, it's gone. That is the whole reason for rule 1: commit early.
