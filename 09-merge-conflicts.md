# 09 – Merge Conflicts

## How conflicts actually happen

> **Correction to the old notes:** *"the main branch at branch time and at merge time must be the same, otherwise conflict"* is wrong. Main moving ahead is the normal case and merges fine (tested).

Git does a **three-way merge** using the **merge base** (last common commit):

```
          base (A)
         /        \
   main: B        feature: C
```

For each region of each file, git compares `base → main` and `base → feature`:

| What happened | Result |
|---|---|
| only one side changed that region | auto-merged |
| both made the *identical* change | auto-merged |
| both changed the **same lines differently** | **conflict** |
| one side edited a file, the other deleted/renamed it | **conflict** (modify/delete, rename) |
| both added a file at the same path with different content | **conflict** (add/add) |

Changes in *different* parts of the same file merge cleanly. A clean merge can still be **logically** wrong (two branches each made valid but incompatible changes in different places), so run your tests after merging.

## Anatomy of a conflict

`git merge feature` → 

```
Auto-merging f.txt
CONFLICT (content): Merge conflict in f.txt
Automatic merge failed; fix conflicts and then commit the result.
```

`git status` shows `UU f.txt` (both modified; under "Unmerged paths"). The file contains markers (tested):

```
line1
<<<<<<< HEAD
line2-from-main          ← YOUR side (the branch you're on)
=======
LINE2-from-c1            ← THEIR side (the branch being merged in)
>>>>>>> c1
line3
```

Status codes: `UU` both modified, `AA` both added, `DU`/`UD` deleted by us/them, `AU`/`UA` added by one side.

## Resolving: the procedure

```bash
git status                           # lists "Unmerged paths"
git diff --name-only --diff-filter=U # just the conflicted filenames
# 1. open each file, decide the final content, DELETE all <<<<<<< ======= >>>>>>> lines
# 2. build/test
git add <file>                       # marks it resolved
git status                           # all resolved?
git commit                           # completes the merge (message pre-filled)   [or: git merge --continue]
```

Rules:

- Don't just pick a side blindly; read both. Often the answer is **both changes combined**.
- Search for leftover markers before committing: `git diff --check` or `grep -rn '^<<<<<<<\|^>>>>>>>' .`
- Bail out any time: `git merge --abort` returns to the pre-merge state (tested; the tree is clean after).

### Take one side wholesale

```bash
git checkout --ours   -- <file>      # keep the version from the branch you're ON
git checkout --theirs -- <file>      # keep the version from the branch being merged IN
git add <file>
```

(`git restore --ours/--theirs <file>` works too.) For a whole merge: `git merge -X ours feature` / `-X theirs` auto-prefers a side **only for conflicting hunks**, and `git merge -s ours feature` records a merge but takes none of feature's changes. Use these sparingly.

### ⚠ `ours` / `theirs` swap during a rebase

During a **merge**: ours = your branch, theirs = the branch you merge in.
During a **rebase**: git replays *your* commits onto the target, so **ours = the branch you're rebasing onto** (e.g. main) and **theirs = your own commit being replayed**. (Tested: during `git rebase main`, `--ours` gave main's line and `--theirs` gave my commit's line.)

### Re-create the markers if you resolved wrongly

```bash
git checkout -m -- <file>            # rebuild the conflict markers (before you've committed)
```

## Better conflict markers

```bash
git config --global merge.conflictStyle zdiff3
```

Adds the **base** version between the sides, so you can see what each side changed:

```
<<<<<<< HEAD
line2-from-main
||||||| base
line2
=======
LINE2-from-c1
>>>>>>> c1
```

## Tools

```bash
git mergetool                        # runs your configured 3-way tool
git config --global merge.tool nvimdiff        # example; or vimdiff, meld, kdiff3
git config --global mergetool.keepBackup false # don't leave *.orig files
```

In Neovim: **vim-fugitive** (`:Gvdiffsplit!` on a conflicted file → 3-way view; `:diffget //2` takes "ours", `:diffget //3` takes "theirs") or **diffview.nvim** (`:DiffviewOpen`). On GitHub, small conflicts can be resolved in the PR web editor, but for anything non-trivial do it locally so you can run tests.

## Conflicts during other operations

| Operation | Continue | Abort | Other |
|---|---|---|---|
| `merge` | `git merge --continue` / `git commit` | `git merge --abort` | |
| `rebase` | `git add <f> && git rebase --continue` | `git rebase --abort` | `git rebase --skip` (drop the current commit) |
| `cherry-pick` | `git cherry-pick --continue` | `git cherry-pick --abort` | |
| `revert` | `git revert --continue` | `git revert --abort` | |
| `stash pop/apply` | resolve, `git add`; then `git stash drop` | `git restore`/`git reset --merge` | stash is kept if pop conflicts |
| `pull` | whichever it did: merge or rebase | same | |

A rebase can stop **once per replayed commit**, so a 10-commit branch may conflict repeatedly in the same place. That's one reason to squash first, or prefer merge for long-lived branches.

## Delete/modify and binary conflicts

```bash
# one side deleted, other modified (status: DU / UD)
git rm <file>        # accept the deletion
git add <file>       # keep the file (the modified version)

# binary file conflicts: pick a side, can't merge by hand
git checkout --theirs -- image.png && git add image.png
```

## Reuse resolutions: `rerere`

"Reuse recorded resolution": git remembers how you resolved a conflict and re-applies it next time the same conflict appears (common when rebasing a long branch repeatedly).

```bash
git config --global rerere.enabled true
```

## Preventing conflicts

- Short-lived branches; merge to `main` often.
- Sync with `main` regularly (`git merge main` or `git rebase main`) so conflicts arrive in small pieces.
- One logical change per PR/branch; avoid mass reformatting mixed with real changes.
- Agree on a formatter (so whitespace churn isn't a conflict).
- Don't have two people edit generated files or lockfiles by hand; regenerate after merging.
- Communicate before touching the same file.

## Practice it

`practice/conflict-lab.sh` builds three throwaway repos (content conflict, modify/delete conflict, rebase conflict), each **left mid-conflict**, with goals printed for each. It uses a private git config inside its temp directory, so your own `~/.gitconfig` (signing, etc.) is never touched. Run `./conflict-lab.sh`, `cd` into each repo, and resolve it using this file.
