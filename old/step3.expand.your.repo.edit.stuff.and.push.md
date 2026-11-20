always do `git fetch` and `git pull` before doing anything to avoid merge conflicts
pull means fetch and merge. so basically : `git pull` is `git fetch` and `git merge` combined. 
```
git status
git diff
git add . # or git add -A # the difference is that, "." only stage changes for your current directory, an "-A" does it for the entire project
git stash # only when you are middle of something, can't commit, but have to change branch for something. so it's basically for temporarily saving half done work. you can stash multiple time btw.
git stash list # self explanatory
git stash pop # only use if after using the stash command, change branch, do your branch, switch back again, and then to get back the unfinished work, you pop it out of stash. if you stashed multiple time, you get them back in reverse order.
git stash apply # basically same as pop command but, this way the stash are still saved and not deleted right after you pop them out.
git diff --staged
git commit -m "your commit message"
git push
git log 
git log --oneline
```

this is going to be your daily stuff.

in case you did `git add .` or `git add -A` but for some reason you regret it (say, you added wrong files or bloat), you can undo it by `git reset`
also another funfact `git add *` means only stage new or modified files but exclude anything related "deleted or deleting files". `git add .` or `git add -A` stages new, modified AND deleted files. so be careful with it.

the best practice is to not touch the main branch. always create branch to work on new things or edit stuff, then merge it.
PR means Pull Request btw. 

here's some more cool commands : 

more about the git stash command : 

wanna pop or apply a specific stash?
```
git stash list
git stash pop stash@{0} # or git stash apply stash@{0}
```
wanna drop a specific stash from stash list?

```
git stash drop
git stash drop stash@{0} # dropping specific stash
```
you accidentally broke something?

```
git restore filename.something 
git restore directoryName # for directory restore
```

or maybe you messed up multiple files?

```
git restore # this restore to last commit
git restore . # this restores the entire project
```

or maybe you have staged your changes by `git add .`?
you can still restore by : 
```
git restore --staged .
git restore --staged filename
git restore --staged directory
```
note : git restore is for local uncommited changes only, once you commited them and pushed them. that's seperate case.
place holder text 

```
git checkout <commit number or branch name> # switches to the branch you named. almost same as git switch, but there are subtle difference. we'll talk about it later.
git switch main
```

wanna create branch?

```
git branch <branch name>
git branch # this lists branches
git switch branch_name
git merge main -m "this merges your branch with main (while keeping the main AND branch-name as seperate branch. it only just mergest / copies the contends"
#do your stuff
git switch main
git merge branch_name -m "your merging message"# this merges this branch to your main
git branch -d branch_name # this delets the branch after you've already merged it.
```

wanna upload the branchs you made to github?

```
git push origin <branch name>
```

wanna undo the last commit you made?

```
git reset HEAD~
```


wanna delete a file?

```
git rm filename.extension
git rm file.txt --force # it deletes file even when changes inside it is not commited yet. yes you have to commit first and then delete it normally.
git rm file.txt --cached # it deletes the file from git, but the file is physically present in your machine.
git rm -r <folder name> # it delete the folder and everything inside it.
git rm -rf <folder name> # you can already guess what it does by now.
```

this is the equivalent of : removing the file manually, then do `git add .`

accidentally deleted some file and want to bring back? `git reset` alone won't cut it. you have to do : 

`git reset --hard`

wanna know how to compare between commits?

```
git diff <commitid-a> <commitid-b> # the order of how you put the commit id matter btw. keep that in mind
```


wanna revert a commit? like you already made and pushed a commit but want to undo it. you can do that my making another commit of reverting previous commit. basically publicly accepting you made a mistake and fixing it instead of changing history. this is useful in case you have multiple contributors and want to publicly state why you want to revert something.

```
git revert <commit id> -m "this commit is reverted for x reason"
```


if you are working in a branch, then the main branch updates, then you also want to have those updates. you have several ways of doing that.

one is merging the branches. if that creates merge conflicts, you can resolve them yourself.
another way of doing this is git rebase. 

```
git rebase main # this means this merges main branch's updates to your branch.
```
note : rebase is not safe, it's not recommend to use in public repos. git merge is safer.
