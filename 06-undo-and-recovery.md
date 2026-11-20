# 06 – Undo and Recovery

**First:** `git status`. It almost always tells you the exact command for what it's showing.
**Second:** ask "have I **committed** it? have I **pushed** it?" That decides everything.

## Decision table

| I did / I want... | State | Command |
|---|---|---|
| Unstage a file I `add`ed | staged, not committed | `git restore --staged <file>` |
| Unstage everything | staged | `git restore --staged .` (or `git reset`) |
| Throw away edits to a file | uncommitted | `git restore <file>` **[DESTRUCTIVE]** |
| Throw away ALL uncommitted edits | uncommitted | `git restore .` **[DESTRUCTIVE]** |
| Bring back a file I deleted (not staged) | deleted on disk | `git restore <file>` |
| Bring back a file deleted with `git rm` (staged) | staged deletion | `git restore --staged --worktree <file>` |
| Bring back a file deleted in an old commit | committed | `git restore --source=<commit>~1 <file>` |
| Fix the last commit message / add a forgotten file | not pushed | `git commit --amend` **[REWRITES HISTORY]** |
| Undo last commit, keep changes **staged** | not pushed | `git reset --soft HEAD~1` |
| Undo last commit, keep changes **unstaged** | not pushed | `git reset HEAD~1` (= `--mixed`) |
| Undo last commit **and** discard changes | not pushed | `git reset --hard HEAD~1` **[DESTRUCTIVE]** |
| Undo a commit that is already pushed/shared | pushed | `git revert <commit>` |
| Undo a merge in progress (conflicts) | merging | `git merge --abort` |
| Undo a completed local merge/pull | not pushed | `git reset --merge ORIG_HEAD` (see below) |
| Undo a pushed merge commit | pushed | `git revert -m 1 <merge-sha>` |
| Undo a merged PR on GitHub | pushed | `gh pr revert <number>` |
| Recover "lost" commits / deleted branch | committed once | `git reflog` |
| Delete untracked files | untracked | `git clean -n` then `-f` **[DESTRUCTIVE]** |
| Committed to `main` by mistake (not pushed) | see recipe below | |
| Committed a secret | pushed or not | rotate the secret; see `13-best-practices.md` |

## `git restore`: files only

```bash
git restore <file>                       # working tree ← index        [DESTRUCTIVE: edits are gone]
git restore <dir>/                       # a directory
git restore .                            # everything under cwd        [DESTRUCTIVE]
git restore -p                           # interactively, hunk by hunk (safest way to discard part)
git restore --staged <file>              # index ← HEAD (unstage); working tree untouched
git restore --staged --worktree <file>   # both index and working tree ← HEAD
git restore --source=HEAD~3 <file>       # working tree ← that older commit's version
git restore --source=<branch> <file>     # take one file from another branch
```

> **Correction:** bare `git restore` with no path is an error (tested: `fatal: you must specify path(s) to restore`). It does **not** "restore everything to last commit"; use `git restore .`.
> Also: `restore` isn't limited to uncommitted work. With `--source` it pulls files from any commit.

Safe habit: `git diff <file>` (what you'd lose) or `git stash` first.

## `git reset`: moves the branch pointer

`git reset <commit>` moves the **current branch** to `<commit>`. The mode decides what happens to index and working tree:

| Mode | Branch pointer | Index | Working tree |
|---|---|---|---|
| `--soft` | moves | unchanged (changes stay **staged**) | unchanged |
| `--mixed` (default) | moves | reset (changes **unstaged**) | unchanged |
| `--hard` | moves | reset | **reset, uncommitted changes lost [DESTRUCTIVE]** |

```bash
git reset --soft HEAD~1      # "uncommit": commit disappears, changes are staged (tested)
git reset HEAD~1             # commit disappears, changes are unstaged (tested)
git reset --hard HEAD~1      # commit and its changes disappear
git reset --hard origin/main # make local branch exactly match remote   [DESTRUCTIVE]
git reset <file>             # (path form) just unstage a file; same as restore --staged
```

> **Dangerous error in the old notes:** *"accidentally deleted a file? `git reset --hard`"*. That wipes **every** uncommitted change in all tracked files just to recover one. The right command is `git restore <file>` (tested). Plain `git reset` (mixed) does **not** bring a deleted file back; it leaves it deleted (tested: status still shows ` D`).

Never `reset` commits you've pushed to a shared branch; use `revert`.

## `git revert`: undo by adding a new commit (safe for shared history)

```bash
git revert <commit>                  # opens editor; message defaults to Revert "<subject>"
git revert --no-edit <commit>        # use the default message
git revert -n <commit>               # --no-commit: apply the inverse but let you tweak/commit yourself
git revert HEAD~3..HEAD              # revert a range (creates one revert per commit)
git revert -m 1 <merge-sha>          # reverting a MERGE commit: -m 1 = keep the first parent (usually main)
```

> **Correction:** `-m` in `git revert` means `--mainline <parent-number>`, **not** a message (tested: `git revert -m "reason" HEAD` → `error: option 'mainline' expects a number greater than zero`). To give a reason, use the editor, or:
> ```bash
> git revert -n <commit>
> git commit -m "revert: <subject>" -m "Reverted because <reason>"
> ```

Reverting a merge commit without `-m` fails (tested: `commit ... is a merge but no -m option was given`). Note: after reverting a merge, **re-merging the same branch later brings nothing** until you revert the revert, because git thinks those changes were already integrated and then removed.

## `git reflog`: the safety net

Records every move of HEAD and branch tips, **locally**, for ~90 days (30 for unreachable commits).

```bash
git reflog                        # HEAD history: HEAD@{0} is now
git reflog show feature-x         # one branch's history
git reflog --date=relative
```

Recover after `reset --hard` (tested):

```bash
git reset --hard HEAD~2           # oops
git reflog                        # find: 03f0573 HEAD@{1}: commit: c3
git reset --hard 'HEAD@{1}'       # back where you were
```

Recover a deleted branch:

```bash
git reflog                                  # find the last commit sha of that branch
git branch feature-x <sha>
```

Recover a dropped stash: `git fsck --unreachable | grep commit`, inspect with `git show <sha>`, restore with `git stash apply <sha>`.

Limits: reflog is per-clone (not on GitHub), and it can't recover content that was **never committed**.

## Undo a pull / merge / rebase that just happened

`ORIG_HEAD` is set by `merge`, `pull`, `rebase`, and `reset` to where HEAD was before.

```bash
git reset --merge ORIG_HEAD     # back to before; keeps uncommitted changes the merge didn't touch (safer)
git reset --hard ORIG_HEAD      # back to before; [DESTRUCTIVE] discards all uncommitted changes
```

For a rebase, prefer `git rebase --abort` while it's running, or the reflog afterward.

## `git clean`: remove untracked files **[DESTRUCTIVE, no undo]**

Untracked files were never in git, so nothing can recover them.

```bash
git clean -n              # DRY RUN: list what would be removed (always do this first; tested)
git clean -f              # remove untracked files
git clean -fd             # + untracked directories
git clean -fdx            # + ignored files too (build outputs, .env!)
git clean -i              # interactive
```

## Practice

`practice/undo-lab.sh` sets up four recovery exercises (deleted file with unsaved work next to it, `reset --hard` too far, reverting a shared bad commit, committing on `main` by mistake). Try them before reading the answers it prints.

## Recipes

**Committed to `main` instead of a branch (not pushed):**

```bash
git branch feature-x            # new branch pointing at your commit(s)
git reset --hard origin/main    # [DESTRUCTIVE to local main only] main back to the remote state
git switch feature-x            # your work is safe here
```

**Wrong branch, uncommitted:** `git stash`, `git switch right-branch`, `git stash pop`.

**Pushed a bad commit to a feature branch only you use:** fix it, then `git push --force-with-lease`.

**Pushed a bad commit to `main`:** `git revert <sha>`, push. Never force-push `main`.

**Edit a file back to how it was two commits ago:** `git restore --source=HEAD~2 <file>`, then commit.

**Throw everything away and match the remote:**

```bash
git fetch origin
git reset --hard origin/main    # [DESTRUCTIVE] tracked changes gone
git clean -fd                   # [DESTRUCTIVE] untracked files gone (run -n first)
```
