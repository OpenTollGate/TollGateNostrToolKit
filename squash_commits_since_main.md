You can use the following bash command to automatically squash all commits since the branch diverged from main:

```bash
git reset $(git merge-base main HEAD)
git add .
git commit -m "Squashed all commits from branch fix_connect_to_gateway_error_squashed"
```

Here's what this does:

1. `git merge-base main HEAD` finds the common ancestor of your current branch and main.

2. `git reset $(git merge-base main HEAD)` resets your branch to that common ancestor, keeping all the changes in your working directory.

3. `git add .` stages all the changes.

4. `git commit -m "..."` creates a new commit with all the changes.

After running these commands, your branch will have a single commit containing all the changes since it diverged from main.

If you want to keep the commit messages from the original commits, you can use this alternative approach:

```bash
git reset $(git merge-base main HEAD)
git add .
git commit --no-edit -F <(git log --reverse --format=%B $(git merge-base main HEAD)..HEAD)
```

This will create a commit message that includes all the previous commit messages.

After squashing, you can proceed with rebasing onto main as described in the previous answer:

```bash
git checkout main
git pull origin main
git checkout fix_connect_to_gateway_error_squashed
git rebase main
```

Remember, these operations rewrite history, so use them cautiously, especially if you've already pushed this branch or shared it with others.