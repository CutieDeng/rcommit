---
name: commit
description: Update .commit file based on current git status and diff
disable-model-invocation: true
allowed-tools: Bash (read-only git queries only), Read, Write
---

Update the `.commit` file with a commit message for the current changes.

## Steps

1. Run `git status --short` to see which files are staged, unstaged, or untracked
2. Run `git diff --cached --stat` to see a summary of staged changes
3. Run `git diff --cached` to understand staged changes when needed
4. Run `git log --oneline -3` to see recent commit message style
5. Read `.commit` to see the current format

## Safety (Git)

- **Read-only Git operations only**
- `Bash` in this skill is limited to read-only git queries; do not use it for any state-changing git action
- **Do not run any mutate Git command** (for example: `git add`, `git commit`, `git reset`, `git checkout`, `git restore`, `git rebase`, `git merge`, `git cherry-pick`, `git push`, `git pull`, `git fetch`, `git branch -d`)
- If you need information, use status/log/diff/show-style read-only commands only
- This skill's job is to update `.commit` content, not to change repository state

## Rules

- **When any staged changes exist, only describe and analyze staged changes** — ignore unstaged hunks in partially staged files
- Use `git diff --cached` / `git diff --cached --stat` as the source of truth for the commit content when staged changes exist
- In `git status --short`, staged changes are shown in the first status column; unstaged-only changes are shown only in the second column and must not be used for the commit message when staged changes exist
- If there are no staged changes, describe the current modified/untracked files from `git status --short` and `git diff --stat`
- **Only describe files that appear in the relevant status/diff source** — never mention files that are not modified or staged as applicable
- S-expression 格式如下（注意 `"` 独占第三行）：
  ```
  (TYPE "short title"

  "
  detailed description...

  Modified:
  - file1
  ")
  ```
- TYPE is one of: FEAT, FIX, REFACTOR, TEST, DOCS
- **标题必须简短**（≤50 字符），只写做了什么，不写细节。细节放 description
- When staged changes exist, the "Modified:" section must list exactly the files from `git diff --cached --name-only`
- When no staged changes exist, the "Modified:" section must list exactly the modified/untracked files from `git status --short`
- Compiled binaries and build artifacts should NOT be mentioned
- Keep it concise — no padding, no speculation about intent
