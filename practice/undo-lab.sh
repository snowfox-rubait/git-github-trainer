#!/usr/bin/env bash
# undo-lab.sh: four recovery exercises in a throwaway repo. Solutions are in the printed list.
# Usage: ./undo-lab.sh [target-dir]
set -euo pipefail
LAB="${1:-$(mktemp -d -t undo-lab.XXXXXX)}"; mkdir -p "$LAB"
export GIT_CONFIG_GLOBAL="$LAB/.gitconfig-lab" GIT_CONFIG_NOSYSTEM=1
git config --global user.name "Lab User"; git config --global user.email lab@example.com
git config --global init.defaultBranch main; git config --global commit.gpgsign false; git config --global core.editor true
new_repo() { rm -rf "$LAB/$1"; git init -q "$LAB/$1"; cd "$LAB/$1"; }

# Ex 1: deleted file + unrelated uncommitted work. Recover the file WITHOUT losing notes.txt edits.
new_repo ex1-deleted-file
echo a > important.txt; echo n > notes.txt; git add .; git commit -qm base
rm important.txt; echo "precious unsaved notes" >> notes.txt

# Ex 2: reset --hard too far. Get the last two commits back.
new_repo ex2-reset-too-far
for i in 1 2 3 4; do echo $i >> f.txt; git add f.txt; git commit -qm "commit $i"; done
git reset -q --hard HEAD~2

# Ex 3: bad commit already "pushed". Undo it safely without rewriting history.
new_repo ex3-bad-commit
echo ok > app.txt; git add .; git commit -qm "good"
echo "BUG" >> app.txt; git commit -qam "introduce bug"
echo more > other.txt; git add other.txt; git commit -qm "unrelated later work"

# Ex 4: committed on main by mistake. Move the commit to a branch; main returns to the first commit.
new_repo ex4-wrong-branch
echo base > a.txt; git add .; git commit -qm "base"
echo feature >> a.txt; git commit -qam "feature work (oops, on main)"

cat <<MSG

Undo lab ready in: $LAB
Try each BEFORE reading the answers (cd into the dir, use git status / git log / git reflog).

 ex1-deleted-file     restore important.txt, keep notes.txt edits
 ex2-reset-too-far    get commits 3 and 4 back
 ex3-bad-commit       undo "introduce bug" but keep "unrelated later work" (history shared)
 ex4-wrong-branch     put the feature commit on branch 'feature', make main = "base"

Answers:
 ex1: git restore important.txt
 ex2: git reflog ; git reset --hard 'HEAD@{1}'
 ex3: git revert --no-edit <sha of "introduce bug">
 ex4: git branch feature ; git reset --hard HEAD~1   (main only; feature keeps the commit)

Cleanup: rm -rf "$LAB"
MSG
