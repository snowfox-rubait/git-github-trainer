always do `git pull` before doing anything to avoid merge conflicts

```
git status
git diff
git add . # or git add -A # the difference is that, "." only stage changes for your current directory, an "-A" does it for the entire project
git diff --staged
git commit -m "your commit message"
git push
git log 
git log --oneline
```

this is going to be your daily stuff.

the best practice is to not touch the main branch. always create branch to work on new things or edit stuff, then merge it.
PR means Pull Request btw. 

here's some more cool commands : 

you accidentally broke something?

```
git restore filename.something 
```

place holder text 

```
git checkout <commit number> 
git switch main
```

wanna create branch?

```
git branch <branch name>
git branch # this lists branches
git switch branch_name
#do your stuff
git switch main
git merge branch_name # this merges this branch to your main
git branch -d branch_name # this delets the branch after you've already merged it.
```


