# 10 – Rewriting History: Rebase, Squash, Cherry-pick

Every command here creates **new commits with new hashes**. They're **[REWRITES HISTORY]**.

> **Golden rule:** only rewrite commits that **nobody else has pulled**. Your own unpushed work, or a personal feature branch: fine. `main` or a shared branch: don't. Otherwise you force others to untangle diverged histories.
> (The old note "rebase is not safe in public repos" was too blunt. Many projects *require* rebased/squashed PRs. The real rule is: don't rewrite published history that others are building on.)

## What rebase does

`git rebase main` (while on `feature`) does **not** "merge main's updates in". It:

1. finds commits on `feature` that aren't on `main`,
2. sets them aside,
3. moves `feature` to the tip of `main`,
4. **replays** your commits one by one on top (new hashes).

```
before:   A ← B ← C        main              after:   A ← B ← C ← D' ← E'    feature
                \                                                  ↑
                 D ← E  feature                                  main
```

Result: a linear history. Cost: hashes change; you must force-push if the branch was already pushed.

```bash
git switch feature
git fetch origin
git rebase origin/main            # replay my commits onto the latest main
# conflict? fix → git add <f> → git rebase --continue   (or --abort / --skip)
git push --force-with-lease --force-if-includes   # needed only if branch was already pushed
```

Related:

```bash
git rebase --autostash main               # stash/unstash uncommitted work around the rebase
git config --global rebase.autoStash true
git pull --rebase                         # fetch + rebase local commits (instead of merge)
git rebase --onto <newbase> <oldbase> <branch>   # transplant a range: e.g. move a branch that was based on the wrong branch
```

Undo a bad rebase: `git rebase --abort` while it's running; afterwards use `git reflog` and `git reset --hard 'HEAD@{n}'` (see `06-undo-and-recovery.md`).

### Merge vs rebase

| | Merge | Rebase |
|---|---|---|
| History | true shape, with merge commits | linear |
| Hashes | preserved | rewritten |
| Safe on shared branches | yes | no |
| Conflicts | resolved once | may recur per commit |
| Undo | `git revert -m 1` | reflog |

## Interactive rebase: clean up before you open a PR

```bash
git rebase -i HEAD~4              # edit the last 4 commits
git rebase -i main                # everything on this branch since main
```

Git opens a todo list (oldest first). Change the word at the start of each line:

| Command | Effect |
|---|---|
| `pick` | keep as is |
| `reword` | keep, edit the message |
| `edit` | stop here so you can amend / split the commit |
| `squash` | meld into previous commit, combine messages |
| `fixup` | meld into previous commit, discard this message |
| `drop` | delete the commit |
| (reorder lines) | reorders commits |

Delete everything / write an empty list to abort. If a rebase goes wrong: `git rebase --abort`.

### Fixup + autosquash (fast tidy-ups)

```bash
git commit --fixup=<sha-of-earlier-commit>      # creates "fixup! <subject>"
git rebase -i --autosquash main                 # automatically places and marks it as fixup
git config --global rebase.autoSquash true      # make --autosquash the default for -i
```

### Squash your whole branch into one commit without a rebase

```bash
git switch main && git merge --squash feature && git commit
# or, on GitHub: "Squash and merge" / gh pr merge --squash
```

## Cherry-pick: copy specific commits

```bash
git switch release-1.2
git cherry-pick <sha>                    # apply that commit here as a new commit
git cherry-pick <sha1> <sha2>            # several
git cherry-pick A..B                     # a range (excludes A, includes B)
git cherry-pick -x <sha>                 # append "(cherry picked from commit ...)" to the message (good for backports)
git cherry-pick -n <sha>                 # apply to working tree without committing
git cherry-pick -m 1 <merge-sha>         # picking a merge commit needs a mainline
git cherry-pick --continue | --abort
```

Use for hotfix backports. Overuse creates duplicate commits that later conflict with themselves when the branches merge.

## Changing history of already-pushed commits

If you must (your own branch):

```bash
git push --force-with-lease --force-if-includes
```

Never plain `--force`. Tell collaborators to re-sync: `git fetch && git switch <branch> && git reset --hard origin/<branch>` (**[DESTRUCTIVE]** for their local commits, so coordinate).

## Rewriting *content* across all history (removing a leaked secret/huge file)

Use the dedicated tool, not rebase: **`git filter-repo`** (Arch: `pacman -S git-filter-repo`).

```bash
git filter-repo --path secrets.env --invert-paths      # remove a file from all commits
```

It rewrites every commit, requires force-pushing all branches/tags, and **does not un-leak anything already cloned or cached**, so **rotate the secret first**. Details in `13-best-practices.md`.

## Signing note

With `commit.gpgsign true`, rebase/cherry-pick/amend **re-sign** replayed commits with your key and set you as committer. Original signatures are dropped.
