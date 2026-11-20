#!/usr/bin/env bash
# conflict-lab.sh: builds three throwaway repos, each LEFT IN THE MIDDLE of a conflict.
# Usage: ./conflict-lab.sh [target-dir]      (default: a fresh temp dir; nothing outside it is touched)
# Read 09-merge-conflicts.md, then resolve each one. Run `git status` in each repo to start.
set -euo pipefail

LAB="${1:-$(mktemp -d -t conflict-lab.XXXXXX)}"
mkdir -p "$LAB"
# Isolated git config: no signing, fixed identity, no editor prompts; does not touch your ~/.gitconfig.
export GIT_CONFIG_GLOBAL="$LAB/.gitconfig-lab"
export GIT_CONFIG_NOSYSTEM=1
git config --global user.name  "Lab User"
git config --global user.email "lab@example.com"
git config --global init.defaultBranch main
git config --global commit.gpgsign false
git config --global core.editor true            # `git commit` accepts the default message
git config --global merge.conflictStyle zdiff3

new_repo() { rm -rf "$LAB/$1"; git init -q "$LAB/$1"; cd "$LAB/$1"; }

# --- Lab 1: same-line content conflict (merge) -------------------------------
new_repo lab1-content
printf 'name: demo\nport: 8080\nmode: dev\n' > config.yml
git add . && git commit -qm "base config"
git switch -qc feature
sed -i 's/port: 8080/port: 9090/' config.yml && git commit -qam "feature: port 9090"
git switch -q main
sed -i 's/port: 8080/port: 3000/' config.yml
sed -i 's/mode: dev/mode: prod/' config.yml && git commit -qam "main: port 3000, mode prod"
git merge feature >/dev/null 2>&1 || true

# --- Lab 2: modify/delete conflict (merge) -----------------------------------
new_repo lab2-modify-delete
echo "legacy helper" > old.txt; echo "keep" > keep.txt
git add . && git commit -qm "base"
git switch -qc cleanup
git rm -q old.txt && git commit -qm "cleanup: delete old.txt"
git switch -q main
echo "legacy helper (fixed a bug)" > old.txt && git commit -qam "main: fix bug in old.txt"
git merge cleanup >/dev/null 2>&1 || true

# --- Lab 3: rebase conflict (note the ours/theirs swap!) ---------------------
new_repo lab3-rebase
printf 'title: Hello\nfooter: v1\n' > page.txt
git add . && git commit -qm "base page"
git switch -qc my-change
sed -i 's/footer: v1/footer: v1 (my edit)/' page.txt && git commit -qam "my footer edit"
git switch -q main
sed -i 's/footer: v1/footer: v2/' page.txt && git commit -qam "main: footer v2"
git switch -q my-change
git rebase main >/dev/null 2>&1 || true

cat <<MSG

Lab ready in: $LAB

1) $LAB/lab1-content          (merge in progress)
   Goal: keep port 9090 from feature AND mode prod from main, then finish the merge.
   Steps: git status ; edit config.yml ; git add config.yml ; git merge --continue
   Try also: git merge --abort, then re-run the merge.

2) $LAB/lab2-modify-delete    (merge in progress; status shows "UD"/"DU")
   Goal A: keep the file (with the bug fix).  Goal B (re-run lab): accept the deletion.
   Hints: git add old.txt   |   git rm old.txt  ; then git merge --continue

3) $LAB/lab3-rebase           (rebase in progress)
   Goal: final footer should read "v2 (my edit)".
   Careful: during a rebase 'ours' = main, 'theirs' = YOUR commit.
   Steps: edit page.txt ; git add page.txt ; git rebase --continue ; git log --oneline --graph

Each repo uses a private git config at $LAB/.gitconfig-lab. Delete the whole directory when done:
   rm -rf "$LAB"
MSG
