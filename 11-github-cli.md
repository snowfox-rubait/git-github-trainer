# 11 – GitHub CLI (`gh`)

`gh` talks to GitHub's **API** (issues, PRs, releases, Actions); `git` handles the **commits and transport**. They complement each other. Run `gh <cmd> --help` for any flag list; everything below was checked against `gh 2.89`.

Global habits:

- `-R owner/repo` / `--repo` runs a command against another repo without cloning.
- `--web` / `-w` opens the thing in your browser.
- Commands that take a PR accept a **number**, **URL**, or **branch name**; with no argument they use the PR of your current branch.
- `--json fields --jq '<expr>'` gives scriptable output (see API section).

## Auth

```bash
gh auth login -h github.com -p ssh -w -s admin:ssh_signing_key
gh auth status                       # who, where the token is stored, scopes
gh auth refresh -s delete_repo       # add a scope later (e.g. to allow `gh repo delete`)
gh auth token                       # print the token (treat it as a password)
gh auth logout
```

`GH_TOKEN` / `GITHUB_TOKEN` env vars override stored credentials (useful in CI).

## Repos

```bash
gh repo create <name> --private --source=. --remote=origin --push   # publish current dir
gh repo create <name> --public --clone                              # new empty repo, cloned
gh repo clone owner/repo
gh repo view [owner/repo] [--web]
gh repo list [owner] --limit 50
gh repo fork owner/repo --clone --remote
gh repo sync [dest] [--source owner/repo] [-b branch]
gh repo edit --description "..." --visibility private --accept-visibility-change-consequences
gh repo archive owner/repo
gh repo delete owner/repo            # [DESTRUCTIVE] needs the delete_repo scope; asks for confirmation
```

## Issues

```bash
gh issue create --title "Crash on empty input" --body "Steps: ..." --label bug --assignee @me
gh issue create -t "..." -F body.md --label bug --label "good first issue" --milestone v1
gh issue create --web                # compose in the browser
gh issue list                        # open issues
gh issue list --state all --label bug --assignee @me --author someone --search "crash"
gh issue view 42 [--web] [--comments]
gh issue comment 42 --body "Reproduced on main."
gh issue edit 42 --add-label bug --remove-label triage --add-assignee @me
gh issue close 42 --reason "not planned"        # or "completed"
gh issue reopen 42
gh issue develop 42 --checkout --name fix/42-crash    # create a branch linked to the issue and switch to it
gh issue develop 42 --list
gh label create bug --color D73A4A --description "Something is broken"
gh label list
```

> **Fixes vs. the old notes:** the subcommand is `issue` (not `isssue`), the flag is `--label` (not `--lable`), a label is **one name per flag** (not `feature/bug`; repeat `--label` for several), labels **must already exist** (`gh label create`), and `--assignee` takes a GitHub *login* with access to the repo (`@me` for yourself).

## Pull requests

### Create

```bash
gh pr create --fill                                     # title/body from commits
gh pr create --title "feat: X" --body "Closes #42" --base main --reviewer user1 --label enhancement
gh pr create --draft --fill                             # draft PR
gh pr create --fill-verbose                             # body from full commit messages
gh pr create --web                                      # open the compare page
gh pr create --dry-run                                  # preview (may still push the branch)
```

Put `Closes #42` / `Fixes #42` in the body so the issue closes on merge. `gh pr create` offers to push your branch if it isn't pushed yet.

### Review and inspect

```bash
gh pr list [--state open|closed|merged|all] [--author @me] [--label x] [--search "is:open review-requested:@me"]
gh pr status                                  # PRs relevant to you
gh pr view [N] [--comments] [--web]
gh pr diff [N] [--name-only]
gh pr checkout 123                            # fetch the PR's branch and switch to it (works for PRs from forks too)
gh pr checks [N] [--watch] [--required]       # CI status
gh pr review 123 --approve
gh pr review 123 --request-changes --body "Please add tests"
gh pr review 123 --comment --body "Looks fine overall"
gh pr comment 123 --body "..."
```

`gh pr checkout` ≈ `git fetch` + `git switch` combined, plus correct upstream setup for fork branches.

### Update, ready, merge

```bash
gh pr edit 123 --title "..." --add-reviewer user --add-label x --base main
gh pr ready 123                               # draft → ready for review
gh pr update-branch 123                       # merge base into the PR branch on GitHub (add --rebase to rebase instead)
gh pr merge 123 --squash --delete-branch      # strategy flag required unless prompted: --merge | --squash | --rebase
gh pr merge 123 --auto --squash               # merge automatically once required checks/reviews pass
gh pr close 123 / gh pr reopen 123
git switch main && git pull                   # sync local after merging remotely
```

**Merge flags:** `-m/--merge`, `-s/--squash`, `-r/--rebase` (note `-m` here is *merge strategy*, unrelated to git's `-m`). `-d/--delete-branch` removes the branch; `--admin` bypasses requirements (don't casually).

### Undo a merged PR

> **Correction:** `gh pr merge --revert` does not exist. Use:

```bash
gh pr revert 123 [--title "..." --body "..." --draft]    # opens a NEW PR that reverts the merged PR
```

or locally: `git revert -m 1 <merge-sha>` and push a branch/PR. Re-landing the original work later requires reverting the revert.

## Releases

```bash
gh release create v1.0.0 --generate-notes                # tag + release with auto notes
gh release create v1.0.0 ./dist/*.tar.gz -t "1.0.0" -n "notes"
gh release create v1.0.0 --draft --prerelease
gh release list | view v1.0.0 | download v1.0.0 | delete v1.0.0
```

Create the tag locally first if you want it signed (`git tag -a v1.0.0 -m ... && git push origin v1.0.0`), then `gh release create v1.0.0 --verify-tag`.

## Actions / CI

```bash
gh run list [--workflow ci.yml] [--branch x]
gh run view [<id>] [--log-failed]            # failed step logs only
gh run watch <id>
gh run rerun <id> [--failed]
gh workflow list | view ci.yml
gh workflow run ci.yml [-f key=value]        # trigger a workflow_dispatch
```

## Everything else

```bash
gh status                         # your cross-repo notifications, assigned issues, PRs
gh search repos "topic:tui language:rust" --limit 20
gh search prs --author @me --state open
gh browse [path] [--branch x]     # open repo / file in the browser
gh gist create file.txt [--public]
gh ssh-key list | add <pubkey> --type authentication|signing --title "..."
gh extension list | search | install owner/gh-ext
gh alias set co 'pr checkout'     # gh co 123
gh alias list
gh completion -s zsh
```

## `gh api`: the escape hatch

```bash
gh api repos/{owner}/{repo}/issues --jq '.[].title'             # {owner}/{repo} auto-filled from the current repo
gh api repos/{owner}/{repo}/pulls -f state=open --paginate
gh api -X POST repos/{owner}/{repo}/issues -f title="Bug" -f body="..."
gh api graphql -f query='{ viewer { login } }'
gh pr list --json number,title,author --jq '.[] | "\(.number)\t\(.title)\t\(.author.login)"'
```

`-f` sends a string field, `-F` sends typed fields (numbers, booleans, `@file`).

## End-to-end: issue → PR → merge

```bash
gh issue create -t "Crash on empty input" -b "..." -l bug           # → #42
gh issue develop 42 --checkout --name fix/42-empty-input            # branch linked to the issue
# ...edit, test...
git add -p && git commit -m "fix: handle empty input" -m "Closes #42"
gh pr create --fill                                                 # pushes the branch, opens PR
gh pr checks --watch                                                # wait for CI
gh pr merge --squash --delete-branch
git switch main && git pull
```
