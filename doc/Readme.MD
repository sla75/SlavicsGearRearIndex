# GIT Branching
https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging

## Create branch
```$ git checkout -b iss5```
## Edits
```$ vim index.html
$ git commit -a -m 'Create new footer [issue 53]'```

## Merge
```$ git checkout master```
Switched to branch 'master'
```$ git merge iss53```
Merge made by the 'recursive' strategy.
index.html |    1 +
1 file changed, 1 insertion(+)

## Deleting branch
```$ git branch -d iss53```
