here's how to create an issue : 

```
gh isssue create --title "issue title" --body "describe the issue" --lable "feature/bug" --assignee claude (or whoever your want to assigne this task) # you need to have preset lables for this and the person to assign. there can also be state, url, etc
```

list issues you have : 

```
gh issue list
```

you want to fetch branches created by others? 

```
git fetch
git branch -a # you won't get other branches without the "-a" parameter
```

 PR means pull request. you can also think it like a merge request.

wanna create a pr?




wanna view the pr ?

```
gh pr view 
gh pr checkout # it's bascially git fetch and git switch <branch> but ran together.
```

wanna merge the pr? 

```
gh pr merge <pr no> --merge
git pull
```

what if you wanna undo the merge?

```
gh pr merge <....> --revert
```



here' show things work  : 

people create issues, you create branch for fixing that issue. once that issue is fixed, you send a PR request (assuming you are a contributor not the head maintainer), then they see the PR request and merge it with main.

 now let's talk about merge conflicts. 

how does conflicts happen. let's say you have a project repo. someone find an issue and to fix it, he created a branch (btw, what's does forking mean? fork vs branch) to work on it. while he is working on it, someone updated the main branch. to merge the main branch from when another branch was created and the main branch at the time of merging should be the same. if it's different, then you have a merge conflict.
