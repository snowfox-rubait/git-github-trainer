first make a project directory and initialize git : 
```
mkdir -p dummyDirectory
cd dummyDirectory
git init
```

create your first file and commit it.
```
nvim README.md # nano also does the job
nvim .gitignore
git status
git add .
git commit -m "init" # but don't push it yet cause the remote hasn't been setup yet.
```

then create your repo in github and push it using this command : 

```
gh repo create dummyRepo --public --remote=origin --source=. --push 
```

and that's how you push your repo to github with first commit. 

for this to work, you must make first commit, otherwise it won't work.

