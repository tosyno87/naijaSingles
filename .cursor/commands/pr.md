# pr

When the user says /pr or "create a PR" or "open a pull request", run the pr-command workflow: (1) inspect staged and unstaged changes with git status and git diff, (2) stage all changes, (3) write a conventional commit message (type(scope): description — feat, fix, refactor, docs, chore, style, security), (4) commit and push to the current branch, (5) open a PR with gh pr create --title "..." --body "...", (6) return the PR URL to the user.


This command will be available in chat with /pr
