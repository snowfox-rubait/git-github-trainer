# 15 – Cheatsheet

Details are in the numbered file shown after each section. **[D]** = destructive.

## Start
```bash
git init | git clone <url> | gh repo clone o/r | gh repo create n --private --source=. --push      # 03
git config --global user.name/user.email                                                          # 02
```

## Daily loop (04)
```bash
git switch main && git pull --ff-only
git switch -c feat/x
git status -sb ; git diff ; git add -p ; git diff --staged
git commit -m "feat: x"
git push -u origin feat/x          # first push
gh pr create --fill
```

## Staging / commit (04)
```bash
git add . | -A | -u | -p | <file>       # `add *` is a shell glob: skips dotfiles & deletions
git restore --staged <f>                # unstage
git commit -m "m" | -am "m" | --amend [--no-edit]
git rm <f> | --cached <f> | -r <d>      git mv a b
```

## Stash (04)
```bash
git stash push -m "msg" [-u]    git stash list    git stash show -p
git stash pop | apply [stash@{n}]    git stash drop [stash@{n}] [D]    git stash clear [D]
```

## Branches / merge / tags (05)
```bash
git branch [-vv|-a|-r|--merged]    git switch <b> | -c <b> | -
git branch -m old new    git branch -d <b> | -D <b> [D]    git push origin --delete <b>
git merge <b> | --no-ff | --ff-only | --squash | --abort
git tag -a v1 -m "m"    git push origin v1 | --follow-tags
git worktree add ../p <b>
```

## Undo (06)
```bash
git restore <f> [D]                    # discard edits to a file
git restore --staged <f>               # unstage
git restore --source=<c> <f>           # file from an older commit
git reset --soft|--mixed|--hard <c>   # keep staged | keep unstaged | discard [D for --hard]
git revert [--no-edit] <c>             # safe undo of pushed commits   (-m 1 for merge commits)
git reflog ; git reset --hard 'HEAD@{n}'     # recovery
git clean -n   then  git clean -fd [D]
git commit --amend                     # fix last commit (unpushed)
git merge --abort | rebase --abort | cherry-pick --abort
```

## Look (07)
```bash
git log --oneline --graph --decorate --all     git log -p | -S"str" | --author=x | -- path
git show <c>[:path]     git diff [--staged|HEAD|a b|a..b|a...b]
git blame -L 10,20 f    git grep -n x    git bisect start|good|bad|run|reset
git log main..feat      git diff main...feat
```

## Remotes (08)
```bash
git remote -v | add <n> <url> | set-url | remove
git fetch [--all --prune]    git pull [--ff-only|--rebase]
git push [-u origin b]    git push --force-with-lease --force-if-includes    # never plain --force [D]
gh repo fork --clone --remote    gh repo sync
```

## Conflicts (09)
```bash
git status ; git diff --name-only --diff-filter=U
# edit → remove markers → git add <f> → git commit | git merge --continue
git merge --abort | git rebase --continue/--abort/--skip
git checkout --ours|--theirs -- f     # merge: ours=current branch; rebase: ours=branch you rebase ONTO
git config --global merge.conflictStyle zdiff3 ; rerere.enabled true
```

## Rewrite (10)
```bash
git rebase [-i] main|HEAD~n       # [REWRITES HISTORY]
git commit --fixup=<sha> ; git rebase -i --autosquash main
git cherry-pick [-x] <sha>        git push --force-with-lease --force-if-includes
```

## `gh` (11)
```bash
gh auth login|status|refresh -s <scope>
gh issue create -t T -b B -l bug -a @me   gh issue list|view|comment|close|develop
gh pr create --fill|--draft   gh pr list|view|diff|checks --watch|checkout N
gh pr review N --approve|--request-changes -b "..."   gh pr merge N --squash --delete-branch
gh pr revert N   gh release create v1 --generate-notes   gh run list|view --log-failed|watch
gh api repos/{owner}/{repo}/issues --jq '.[].title'
```

## Old-notes corrections at a glance
- `git reset --hard` is **not** how you restore a deleted file → `git restore <f>`.
- `git revert <c> -m "msg"` is invalid → `-m` is the merge parent number.
- `gh pr merge --revert` doesn't exist → `gh pr revert N`.
- `git restore` alone errors → `git restore .`.
- Merge conflict ≠ "main changed"; it's *same lines changed on both sides*.
- `git add *` is the shell, not git; `git add .` **does** stage deletions.
- `rebase` replays your commits (new hashes); it doesn't "merge main in".
- `%t` in `environment.d` isn't expanded → `${XDG_RUNTIME_DIR}`.
- `insteadOf` → prefer `pushInsteadOf`.
