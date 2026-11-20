# 16 – GitHub Actions, CI/CD, Wiki, Projects

Everything here is *GitHub features*, not git. `gh` commands were checked against `gh 2.89`; the YAML examples were parsed for syntax but **not run on GitHub**, so expect to tweak versions and paths on first use.

---

# Part 1: CI/CD and GitHub Actions

## The concepts

| Term | Meaning |
|---|---|
| **CI** (continuous integration) | Every push/PR is automatically built, tested and linted, so broken changes are caught *before* merge. |
| **Continuous delivery** | Every change that passes CI is automatically packaged and ready to release; a human presses the button. |
| **Continuous deployment** | Same, but it deploys to production automatically with no button. |
| **Pipeline** | The ordered set of automated stages (lint → test → build → deploy). |

**GitHub Actions** is GitHub's built-in automation system. You describe pipelines as YAML files in `.github/workflows/`, and GitHub runs them on its servers.

## Vocabulary

| Term | What it is |
|---|---|
| **Workflow** | One YAML file in `.github/workflows/` |
| **Event / trigger** | What starts it (`on:`): push, pull_request, schedule, manual, release... |
| **Job** | A group of steps that runs on **one runner**. Jobs run in **parallel** unless you chain them with `needs:`. |
| **Step** | One command (`run:`) or one reusable action (`uses:`), run in order inside a job. |
| **Runner** | The machine that executes a job: `ubuntu-latest` (GitHub-hosted VM, fresh each run) or your own (*self-hosted*). |
| **Action** | A reusable packaged step, e.g. `actions/checkout@v4`. |
| **Run** | One execution of a workflow. |
| **Check / status** | The pass/fail result shown on a PR. Branch protection can *require* it. |

Each job starts on a **clean machine**: nothing from your repo is there until you run `actions/checkout`, and nothing carries over between jobs except via artifacts/cache.

## A first workflow: CI on every push and PR

`.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read            # least privilege for the built-in token

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true  # a new push cancels the older run for the same branch/PR

jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: pip
      - run: pip install -r requirements.txt
      - run: python -m pytest -q
```

Commit it on a branch, push, open a PR: the check appears on the PR automatically. A **trivial** language-neutral version for experimenting (no dependencies):

```yaml
name: Smoke
on: [push, pull_request]
jobs:
  smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./test.sh      # exits 0 = pass, non-zero = fail
```

(`chmod +x test.sh` and commit it, or you'll get "Permission denied".)

## Triggers (`on:`)

```yaml
on:
  push:
    branches: [main, "release/**"]
    tags: ["v*"]                      # e.g. v1.2.3
    paths: ["src/**", "package.json"] # only when these paths change
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
  schedule:
    - cron: "0 3 * * 1"               # Mondays 03:00 UTC (always UTC; may start late)
  workflow_dispatch:                  # manual "Run workflow" button / gh workflow run
    inputs:
      environment:
        description: Where to deploy
        required: true
        default: staging
        type: choice
        options: [staging, production]
  release:
    types: [published]
  workflow_call:                      # makes this workflow reusable by others
```

Gotchas:

- `pull_request` runs on the **merge result** of the PR and base, and from **forks** gets a read-only token and **no secrets**. That's deliberate.
- **Never** use `pull_request_target` with code from the PR unless you really understand it. It runs with secrets and write access; checking out untrusted PR code there is a classic way repos get compromised.
- Events created **by the built-in `GITHUB_TOKEN`** (e.g. a workflow pushing a commit) do **not** trigger other workflows, to prevent loops.
- With `paths:` filters, a workflow that doesn't run leaves a **required check pending forever** (PR can't merge). Don't path-filter workflows you've made required, or add an always-run job.
- Scheduled workflows in **public** repos are auto-disabled after ~60 days without repo activity.
- Workflow files are read from the branch/commit the event is on, so you can test changes to a workflow in a PR branch.

## Jobs: dependencies, conditions, matrix

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/lint.sh

  test:
    needs: lint                       # wait for lint; skipped if lint fails
    strategy:
      fail-fast: false                # don't cancel siblings when one fails
      matrix:
        python: ["3.11", "3.12", "3.13"]
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python }}
      - run: python -m pytest -q

  deploy:
    needs: [lint, test]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: production           # can require manual approval, see below
    steps:
      - run: echo "deploying"
```

Useful expressions: `${{ github.sha }}`, `${{ github.ref_name }}`, `${{ github.event_name }}`, `${{ github.actor }}`, `${{ runner.os }}`; conditions `if: failure()`, `if: always()`, `if: success()`.

Pass data between steps:

```yaml
- id: ver
  run: echo "version=$(cat VERSION)" >> "$GITHUB_OUTPUT"
- run: echo "building ${{ steps.ver.outputs.version }}"
```

## Secrets and variables

```yaml
steps:
  - run: ./deploy.sh
    env:
      API_TOKEN: ${{ secrets.API_TOKEN }}   # masked in logs
      REGION: ${{ vars.REGION }}            # non-secret config
```

Manage from the terminal:

```bash
gh secret set API_TOKEN                 # prompts for the value (never put it on the command line / history)
gh secret set API_TOKEN < token.txt
gh secret set API_TOKEN --env production   # environment-scoped
gh secret list
gh variable set REGION --body "eu-west-1"
gh variable list
```

Rules:

- Secrets are **write-only**: you can't read them back, only overwrite.
- Pass secrets via `env:`, not interpolated into `run:` scripts (shell-injection risk), and never `echo` them. Masking is best-effort, so don't rely on it.
- Fork PRs don't receive secrets. Don't "fix" that by loosening triggers.
- **Environments** (repo Settings → Environments) add required reviewers, wait timers, and per-environment secrets: use them for `production` so a deploy waits for your approval.

## The built-in `GITHUB_TOKEN` and permissions

Every run gets a temporary token. Limit it explicitly:

```yaml
permissions:
  contents: read          # default to read-only at the top
jobs:
  release:
    permissions:
      contents: write     # only the job that needs it
```

Also settable repo-wide (Settings → Actions → General → Workflow permissions: choose read-only by default).

## Caching and artifacts

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: pip-${{ runner.os }}-${{ hashFiles('requirements.txt') }}
# (setup-python/node/go with `cache:` does this for you; prefer that)

- uses: actions/upload-artifact@v4        # keep files from a run (test reports, built binaries)
  with:
    name: dist
    path: dist/
    retention-days: 7
```

Download later: `gh run download <run-id> -n dist`, or `actions/download-artifact` in a later job. Artifacts pass files **between jobs**; the cache speeds up **repeated runs**.

## A CD example: publish a release when you push a tag

No third-party action needed; the runner has `gh` preinstalled.

`.github/workflows/release.yml`:

```yaml
name: Release
on:
  push:
    tags: ["v*"]

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/build.sh            # produces dist/*
      - name: Create GitHub release
        env:
          GH_TOKEN: ${{ github.token }}
        run: gh release create "$GITHUB_REF_NAME" dist/* --generate-notes --verify-tag
```

Trigger it from your machine:

```bash
git tag -a v1.0.0 -m "release 1.0.0"
git push origin v1.0.0
gh run watch                    # follow it
```

Commits or tags created *by* a workflow are authored by the `github-actions` bot, **not signed with your SSH key** (unlike the local setup in `02-setup-ssh-signing.md`).

## Supply-chain safety (read this)

Every `uses: owner/action@ref` runs someone else's code with access to your repo's token and secrets.

- Prefer first-party (`actions/*`) and well-known actions.
- **Tags are movable.** `@v4` can be repointed. For third-party actions, pin to a full **commit SHA** (`uses: owner/action@<40-char-sha>  # v1.2.3`).
- Keep them updated with Dependabot (`.github/dependabot.yml`, `package-ecosystem: "github-actions"`).
- Least-privilege `permissions:`, no `pull_request_target` footguns, no secrets in PR-triggered workflows.

## Make CI actually gate merges

CI that doesn't block merging is advisory. In repo **Settings → Branches / Rulesets** for `main`: require status checks to pass, select the checks by **job name** (a check only appears in the picker after it has run once), and require branches to be up to date. (See `13-best-practices.md`.)

## Driving Actions from the terminal

```bash
gh run list                                  # recent runs
gh run list -w ci.yml -b main -s failure -L 10    # filter by workflow, branch, status, limit
gh run view                                  # pick interactively
gh run view <run-id> --log-failed            # only the failing steps' logs (start here)
gh run view <run-id> --log | less            # everything
gh run watch <run-id>                        # live-follow; exits when done
gh run rerun <run-id> --failed               # rerun only failed jobs
gh run cancel <run-id>
gh run download <run-id> [-n artifact-name]
gh run delete <run-id>                       # [DESTRUCTIVE] remove a run and its logs

gh workflow list
gh workflow view ci.yml
gh workflow run ci.yml --ref main            # needs `on: workflow_dispatch`
gh workflow run deploy.yml -f environment=staging     # pass inputs with -f key=value
gh workflow disable ci.yml / enable ci.yml

gh pr checks [N] --watch                     # CI status of a PR
gh pr checks [N] --required                  # only the ones that gate merge
gh cache list                                # Actions caches
```

## Debugging a failing run

1. `gh run view --log-failed`. Read the **first** error, not the last.
2. "Permission denied" on a script → `chmod +x` and commit it (`git update-index --chmod=+x script.sh` if it was already tracked).
3. "command not found" → the runner is a **clean VM**; install it in a step or use a `setup-*` action.
4. Works locally, fails in CI → different OS/version/env vars/missing files. A shallow checkout has no history or tags: use `actions/checkout@v4` with `fetch-depth: 0` if you need `git log`/tags/`git describe`.
5. Workflow doesn't run at all → check the `on:` block and branch filters, that the file is in `.github/workflows/` on the right branch, and that it's valid YAML. The **Actions tab** shows parse errors.
6. YAML pitfalls: indentation is meaning; quote values like `"3.10"` (unquoted becomes the number 3.1); `on:` is fine as written; `${{ }}` expressions containing `:` or starting a value need quotes.
7. Verbose logs: set repo secret/variable `ACTIONS_STEP_DEBUG=true`, then rerun.
8. Lint before pushing: `actionlint` (Arch: `pacman -S actionlint`) catches bad expressions and typos.
9. Running locally: `act` (third-party, needs Docker) approximates runs but is **not identical** to GitHub's runners. Good for fast iteration, not for trust.

Cost: Actions is free for public repos; private repos get a monthly free-minutes quota that depends on your plan and changes, so check GitHub's current billing docs. `timeout-minutes` and `concurrency.cancel-in-progress` keep runaway jobs cheap.

---

# Part 2: Repo Wiki

- Each repo can enable a **Wiki** tab (Settings → Features) for long-form Markdown docs.
- **The wiki is its own git repository**: `git@github.com:<owner>/<repo>.wiki.git`. You can clone, edit locally, commit and push:

```bash
git clone git@github.com:<owner>/<repo>.wiki.git
cd <repo>.wiki
nvim Home.md              # Home.md is the landing page; _Sidebar.md / _Footer.md customize layout
git add . && git commit -m "docs: update install guide" && git push
```

(The wiki must have at least one page created in the web UI before the `.wiki.git` repo exists.)

- There is **no `gh wiki` command**.
- Caveats: wiki edits aren't part of your PRs, so there's no review, CI, or branch protection by default, and it's easy for it to rot. For most projects a **`docs/` folder** (plus README) in the main repo is better, since it's versioned and reviewed with the code. Use the wiki for informal, community-editable notes.
- Rendered docs sites: GitHub Pages (Settings → Pages), often built from `docs/` by an Actions workflow.

---

# Part 3: Projects

GitHub **Projects** (the current version is "Projects v2") is a planning layer on top of issues and PRs: a spreadsheet/board hybrid.

- **Items** are issues, PRs, or draft notes. Adding an issue to a project doesn't copy it; it's a linked view.
- **Views**: Table, Board (kanban: Todo / In progress / Done), Roadmap (timeline). Each view has its own filters, grouping and sorting.
- **Custom fields**: status, priority, iteration/sprint, dates, numbers, single-select.
- **Automation** (built-in workflows in the project's settings): auto-add items from a repo, set Status to *Done* when an issue closes or PR merges, etc.
- Projects live at the **user or org level** (not inside one repo) and can be linked to repos; they can span several.
- Create from the web UI (repo or profile → Projects → New project). Plain **issues + labels + milestones** are enough for most solo work; reach for Projects when you want a board or when multiple repos/people need one overview.

`gh` support (needs an extra token scope; I only verified that the commands exist, not their behavior):

```bash
gh auth refresh -s project                       # one-time: grant project scope (read:project for read-only)
gh project list                                  # your projects (use --owner <org> for an org)
gh project create --title "Roadmap"
gh project view 1 [--web]
gh project field-list 1
gh project item-list 1
gh project item-add 1 --url https://github.com/<owner>/<repo>/issues/42
gh project item-create 1 --title "Draft: investigate X"
gh project item-edit ...                         # set field values (needs item/field/project ids; see --help)
gh project link 1 --repo <owner>/<repo>          # link a project to a repo
```

Everyday terminal workflow without any of that: `gh issue create ... --project "Roadmap"` adds an issue to a project at creation time.

---

# Practice: a failing-CI loop (for the trainer project)

On a throwaway private repo:

1. Add `test.sh` that exits 0, plus the **Smoke** workflow above; commit to `main`, push.
2. `git switch -c break-it`, change `test.sh` to `exit 1`, commit, `git push -u origin break-it`, `gh pr create --fill`.
3. `gh pr checks --watch` → it fails. `gh run view --log-failed` → read why.
4. Fix `test.sh`, commit, push. Checks rerun automatically on the same PR.
5. Enable branch protection requiring the **smoke** check, then try to merge a failing PR (it's blocked). Fix and `gh pr merge --squash --delete-branch`.
6. Add `workflow_dispatch:` to the workflow and run `gh workflow run smoke.yml`; add the **Release** workflow and push a tag to watch a release get created.
7. Break something on purpose: a YAML indentation error, a missing `chmod +x`, a secret that doesn't exist. Practice reading each failure.
