# 07 – Inspecting History

## `git log`

```bash
git log                                  # full
git log --oneline                        # one line per commit
git log --oneline --graph --decorate --all     # the "what does my repo look like" view
git log -n 10                            # last 10
git log -p                               # + the patch of each commit
git log --stat                           # + files changed
git log --name-status                    # + A/M/D per file
git log --show-signature -1              # verify the signature of the latest commit
```

Filtering:

```bash
git log --author="Haw"
git log --since="2 weeks ago" --until="yesterday"
git log --grep="login"                   # in commit messages
git log -S"parse_config"                 # "pickaxe": commits that added/removed this exact string
git log -G"parse_\w+"                    # commits whose diff matches this regex
git log --follow -- path/to/file         # history of one file across renames
git log -- path/to/dir                   # commits touching a path (note the `--`)
git log --merges / --no-merges
git log --first-parent                   # only the mainline (what landed on main, ignoring branch commits)
```

Custom format:

```bash
git log --pretty=format:'%h %an %ar %s'  # hash, author, relative date, subject
```

### Ranges: `..` vs `...`

| Syntax | `git log` shows | `git diff` shows |
|---|---|---|
| `A..B` | commits in B but not in A | changes from A to B (same as `diff A B`) |
| `A...B` | commits in either but not both | changes on B **since the merge base** of A and B |

```bash
git log main..feature        # what will this branch add to main?
git log feature..main        # what has main got that my branch lacks?
git diff main...feature      # the net change a PR from feature would show
```

## `git show`: one object

```bash
git show                      # latest commit with patch
git show <commit>
git show <commit> --stat
git show <commit>:path/to/file     # a file as it was in that commit
git show v1.0.0                    # tag + commit
```

## `git diff` forms

```bash
git diff                              # unstaged
git diff --staged                     # staged
git diff HEAD                         # all uncommitted
git diff <commit-a> <commit-b>        # order matters: shows what changes to get from a TO b
git diff main feature                 # two branches' tips
git diff main...feature               # since merge base (PR view)
git diff HEAD~3 -- path/file          # one file against 3 commits ago
git diff --stat | --name-only | --name-status
```

If you swap `a` and `b`, additions and deletions flip.

## `git blame`: who last touched each line

```bash
git blame path/file
git blame -L 40,60 path/file         # only lines 40-60
git blame -w path/file               # ignore whitespace-only changes
git blame -C path/file               # follow code moved between files
git blame --ignore-rev <sha> file    # skip a bulk-reformat commit
```

Then `git show <sha>` to see why. A commit that only reformatted code can be listed in a `.git-blame-ignore-revs` file and enabled with `git config blame.ignoreRevsFile .git-blame-ignore-revs`.

## Search

```bash
git grep -n "TODO"                   # in the working tree (tracked files, fast)
git grep "pattern" v1.0.0            # in a given revision
git ls-files                         # tracked files
git ls-files -u                      # unmerged (conflicted) entries
git shortlog -sn                     # commits per author
git describe --tags                  # nearest tag + distance, e.g. v1.2.0-5-gabc1234
```

## `git bisect`: find the commit that broke things

Binary search through history, ~log₂(n) steps.

```bash
git bisect start
git bisect bad                       # current commit is broken
git bisect good v1.0.0               # this one worked
# git checks out a middle commit → test it → then:
git bisect good      # or: git bisect bad
# ...repeat until it names the first bad commit...
git bisect reset                     # return to where you started
```

Automate: `git bisect run ./test.sh` (script exits 0 = good, 1–127 except 125 = bad, 125 = skip).

## Plumbing you'll occasionally need

```bash
git rev-parse HEAD                   # full hash of HEAD
git rev-parse --short HEAD
git rev-parse --abbrev-ref HEAD      # current branch name
git rev-parse --show-toplevel        # repo root path
git cat-file -p <sha>                # print any object
git merge-base main feature          # the common ancestor
git status --ignored                 # show ignored files
```
