# 04 – The Daily Workflow

## The loop

```bash
git switch main && git pull --ff-only     # start from fresh main
git switch -c fix/login-redirect          # new branch for this change
# ...edit...
git status                                # what changed?
git diff                                  # unstaged changes
git add -p                                # stage deliberately, hunk by hunk
git diff --staged                         # EXACTLY what the commit will contain
git commit -m "fix: redirect to /home after login"
git push -u origin fix/login-redirect     # first push of this branch (-u sets upstream)
gh pr create --fill                       # open the PR (see 11-github-cli.md)
```

> **On "always `git fetch` then `git pull`":** `pull` already fetches, so running both is redundant. Fetch first only when you want to *look* before integrating: `git fetch && git log HEAD..origin/main --oneline`. Pulling doesn't prevent conflicts; it surfaces them sooner, which is cheaper. Pull before you start, and again before you push/open a PR.

## Looking: `status` and `diff`

```bash
git status                 # full
git status -sb             # short + branch/ahead-behind
git diff                   # working tree vs index        (unstaged)
git diff --staged          # index vs HEAD                (staged)  [= --cached]
git diff HEAD              # working tree vs HEAD         (everything uncommitted)
git diff --stat            # summary of files/lines
git diff --name-only       # just filenames
git diff -w                # ignore whitespace
```

`git diff` showing nothing after `git add` is normal: it's all in `--staged` now.

## Staging: `git add` variants (tested)

| Command | New files | Modified | Deleted | Scope |
|---|---|---|---|---|
| `git add .` | yes | yes | yes | current directory and below |
| `git add -A` (`--all`) | yes | yes | yes | whole repo, from anywhere |
| `git add -u` (`--update`) | **no** | yes | yes | tracked files only |
| `git add <file>` / `<dir>` | yes | yes | yes | just those paths |
| `git add *` | yes | yes | **no** | **shell glob**, not a git feature |
| `git add -p` | n/a | yes | n/a | interactive hunks |

> **Correction:** `*` is expanded by *your shell* before git sees it. It skips dotfiles (`.gitignore`, `.env.example`, ...) and can't name deleted files because they no longer exist to match. That's why deletions and hidden files are silently left out. Avoid `git add *`.

Since Git 2.0, `git add .` **does** stage deletions (the old "only new/modified" folklore is out of date). The only difference from `-A` is directory scope:

```bash
cd src/ && git add .      # stages changes under src/ only
cd src/ && git add -A     # stages the whole repo
```

Other staging tools:

```bash
git add -p                 # y/n/s(plit)/e(dit) per hunk, the best way to build clean commits
git add -N <file>          # "intent to add": makes a new file show up in `git diff`
git reset                  # unstage everything (keeps your edits)
git restore --staged <f>   # unstage one file (modern form)
```

## Committing

```bash
git commit -m "subject"                       # one-line message
git commit -m "subject" -m "body paragraph"   # subject + body (each -m is a paragraph)
git commit                                    # opens $EDITOR for a full message
git commit -v                                 # editor + shows the diff while you write
git commit -am "msg"                          # stage all TRACKED changes + commit (no new files)
git commit --allow-empty -m "trigger CI"
```

### Amend the last commit **[REWRITES HISTORY]**

```bash
git commit --amend                  # edit message and/or add staged changes
git commit --amend --no-edit        # add staged changes, keep message
git commit --amend --reset-author   # fix the author/email
```

Only before pushing (or on a branch only you use; then `git push --force-with-lease`).

### Good commit messages

```
type(scope): imperative subject, ≤ 50 chars

Why this change was needed, not what (the diff shows what).
Wrap at ~72 columns. Reference issues: Closes #42
```

Common `type`s (Conventional Commits): `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`.

## Pushing and pulling

```bash
git push                          # to the configured upstream
git push -u origin <branch>       # first push; remembers upstream
git pull                          # fetch + merge (or rebase, per config)
git pull --ff-only                # refuse if it would create a merge commit
git pull --rebase                 # fetch + replay your local commits on top [REWRITES local commits]
git fetch                         # download only; update origin/* refs
```

More in `08-remotes-and-forks.md`.

## Removing and moving files

```bash
git rm <file>                  # delete from disk AND stage the deletion
git rm --cached <file>         # untrack, keep on disk (e.g. after adding to .gitignore)
git rm -r <dir>                # directory, recursively
git rm -f <file>              # [DESTRUCTIVE] force even with uncommitted modifications (changes are lost)
git mv old.txt new.txt         # rename + stage (git detects renames by content anyway)
```

`git rm` refuses if the file has local modifications or staged changes that differ from HEAD (tested: "the following file has local modifications"). That's the safety `-f` overrides. Equivalent to deleting by hand and running `git add -A`.

Dry run: `git rm -n <file>`.

## Stash: shelve unfinished work

Use it when you must switch context but aren't ready to commit. A stash is a hidden commit stack (LIFO), not tied to a branch.

```bash
git stash                              # tracked changes only (tested: untracked files alone → "No local changes to save")
git stash push -m "wip: search box"    # with a label (recommended)
git stash push -u                      # also stash UNTRACKED files
git stash push -a                      # also ignored files
git stash push -- path/to/file         # only specific paths
git stash list                         # stash@{0} is the newest
git stash show                         # summary of newest
git stash show -p stash@{1}            # full diff of a specific stash
git stash pop                          # apply newest AND drop it
git stash apply                        # apply newest, keep it in the list
git stash pop stash@{2}                # specific one (zsh: quote it)
git stash drop stash@{0}               # [DESTRUCTIVE] delete one
git stash clear                        # [DESTRUCTIVE] delete all
git stash branch <new-branch> stash@{0}  # new branch from the commit you stashed on, then pop
```

Notes:

- Stashes apply to **any** branch; you're not required to return to the original one.
- If `pop` hits a conflict, the stash is **kept** (not dropped); resolve, then `git stash drop` yourself.
- Dropped a stash by mistake? `git fsck --unreachable | grep commit` can find it for a while; see `06-undo-and-recovery.md`.
