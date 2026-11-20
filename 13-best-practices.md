# 13 – Best Practices

## Commits

- **Atomic**: one logical change per commit. If you need "and" in the subject, split it (`git add -p` makes this easy).
- **Builds and tests pass at every commit** (so `git bisect` works).
- **Message**: imperative subject ≤ 50 chars ("fix", not "fixed"), blank line, body explaining *why*. Reference issues (`Closes #42`).
- **Don't commit**: secrets, `.env`, build output, dependencies (`node_modules/`), editor files, large binaries (use LFS), personal config.
- **Review before committing**: `git diff --staged`, every time.
- **Sign commits** (already configured in `02-setup-ssh-signing.md`) so authorship is verifiable.
- **WIP commits are fine locally**; clean up with an interactive rebase before the PR.

## Branching

- `main` is always deployable. **Never commit directly to it**; protect it (below).
- One short-lived branch per change: `type/short-desc` (`fix/42-login-redirect`).
- Prefer **small branches** merged within days; long-lived branches = painful conflicts.
- Update from `main` often (`git merge main` or `git rebase main` for personal branches).
- Delete branches after merging (`gh pr merge --delete-branch`; periodically `git fetch --prune`; `git branch --merged`).
- Common models: **GitHub Flow** (branch → PR → merge to main → deploy) is plenty for most projects; **trunk-based** for fast-moving teams with feature flags; Git Flow (develop/release branches) only if you genuinely ship versioned releases.

## Pull requests

- **Small and focused**: under ~400 changed lines is reviewable; split otherwise.
- Description answers: **what** changed, **why**, **how to test**; link the issue; add screenshots for UI.
- Open as **draft** early for feedback; mark ready when CI is green.
- **Self-review the diff** (`gh pr diff` or the Files tab) before requesting review.
- Respond to review with **new commits** (so reviewers see what changed) unless the team rebases; squash on merge.
- Never force-push a PR branch after review has started unless you tell the reviewer (or use `--force-with-lease` and say so).
- CI must pass before merge. Don't merge your own PR to a shared repo without review unless that's the agreed rule.

## Protecting `main` (repo settings → Branches/Rulesets)

Recommended: require a PR before merging; require ≥1 approval; require status checks to pass; require branches be up to date; block force pushes and deletions; (optionally) require signed commits and linear history. Even for solo repos, "block force pushes + deletion" is worth it.

## Secrets (the one thing you can't undo)

1. **Prevention**: `.gitignore` first (`.env`, keys); keep secrets in env vars / a secret manager; enable GitHub **Secret scanning** and **Push protection** in repo/account settings; consider a pre-commit scanner (`gitleaks`, `trufflehog`).
2. **If a secret was committed, even once, even if "deleted" in the next commit**: it's in history, and in every clone and fork.
   - **Rotate/revoke the secret immediately.** This is the only real fix.
   - Then optionally scrub history with `git filter-repo` (see `10-history-rewriting.md`), force-push, and ask collaborators to re-clone. Cached copies/forks may still hold it.
3. Never paste secrets into issues/PRs/commit messages.

## Safety habits

- `git status` → `git diff` → `git diff --staged` before commit. `git status -sb` before push.
- Dry-run first: `git clean -n`, `git rm -n`, `gh pr create --dry-run`.
- Before anything `[DESTRUCTIVE]`: commit or `git stash push -u` first. A stash/commit makes it recoverable.
- Prefer `--force-with-lease --force-if-includes` over `--force`; never on `main`.
- Prefer `git revert` over `git reset` for anything already pushed.
- `git pull --ff-only` by default so integration is a conscious decision.
- Know `git reflog` exists. Most "I lost everything" moments end there.
- Test restores: do risky history surgery on a **backup branch** (`git branch backup/pre-rebase`) first.

## Merge strategy choice

| Team habit | Setting |
|---|---|
| Want each PR = one revertable commit, tidy main | **Squash and merge** (default for most small teams) |
| Want full branch history, `--first-parent` readability | **Merge commit** |
| Carefully curated commits, linear history | **Rebase and merge** |

Pick one per repo and enforce it in repo settings.

## Repo hygiene

- `README` (what/why/how to run), `LICENSE`, `.gitignore`, `CONTRIBUTING.md`, issue/PR templates (`.github/`).
- Add a `.git-blame-ignore-revs` for bulk-format commits.
- Tag releases (`v1.2.3`, semantic versioning) and publish with `gh release create --generate-notes`.
- Keep large generated/binary files out; if already committed and huge, use `git filter-repo` / LFS.
- Back up: a GitHub remote **is** a backup only if you actually push. Push branches regularly.

## Collaboration etiquette

- Pull/fetch before starting; communicate before large refactors that touch shared files.
- Resolve conflicts **locally** and test.
- Write issues as reproducible reports: expected, actual, steps, environment.
- Don't rewrite shared history; don't `--force` on shared branches.
