# User Prompts - 2026-01-27

Extracted from `2026-01-27-public-release-prep-and-cli-passthrough.txt`

## Session Prompts

1. Let's switch to the `main` branch

2. /git-sync

3. Let's prune the stale branches

4. Review the project documentation and let me know if you have any questions. I'd like to add an item to @TASKS.md, to enable the ability to pass command line parameters, like this: `claude-yo -p "Review the project documents and update the README to match the current state of the codebase"'

5. I'm curious why we need a separator. Since we're just running a bash script, can't we parse the command line, look for flags we recognize, like `--rebuild` and then pass the rest to claude? Forgive my ignorance

6. let's implement this, updating the docs to indicate that the wrapper flags are specifically chosen to avoid collisions with existing claude flags for this reason

7. y

8. Is `main` protected?

9. Good. I'd like to publicize the repo, but I want to protect main, so that's what I wanted to hear. Any other protections we should consider?

10. yes, both

11. y

12. Let's append your recommendations for protecting the repo on GitHub at the end of @TASKS.md as a checklist

13. y

14. check for secrets in git history

15. mark that as complete

16. Are there any items in the new repo config checklist that we can address using `gh`?

17. yes, do all of them

18. y

19. show the remaining tasks

20. Please remind me how we add Claude Code to the container

21. Is that important aspect of `--rebuild` documented in @README.md ?

22. OK, you noted that the auto-update feature is deferred based on what's in @APPROACH.md -- what specifically indicates that?

23. I'm just wondering if we should remove that task and the promises to consider auto-update in the future, especially considering how easy it is to use the --rebuild option

24. y

25. y

26. /chat-export

27. 1

28. /chat-export

29. 2
