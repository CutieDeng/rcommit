---
name: commit
description: Update .commit file based on current git status and diff
disable-model-invocation: true
allowed-tools: Bash (read-only git queries and optional Racket validator only), Read, Write
---

Update the `.commit` file with a commit message for the current changes.

## Steps

1. Run `git status --short` to see which files are staged, unstaged, or untracked
2. Run `git diff --cached --stat` to see a summary of staged changes
3. Run `git diff --cached` to understand staged changes when needed
4. Run `git log --oneline -3` to see recent commit message style
5. Read `.commit` to see the current format
6. Write `.commit` using the required Racket datum format
7. If `racket` is available in the current environment, run:
   ```sh
   racket /Users/cutiedeng/.claude/skills/commit/scripts/check-commit-message.rkt --message-file .commit
   ```
   If validation fails, fix `.commit` and run the validator again. If `racket`
   is unavailable, state that machine validation was skipped.

## Safety (Git)

- **Read-only Git operations only**
- `Bash` in this skill is limited to read-only git queries and the optional Racket validator; do not use it for any state-changing git action
- **Do not run any mutate Git command** (for example: `git add`, `git commit`, `git reset`, `git checkout`, `git restore`, `git rebase`, `git merge`, `git cherry-pick`, `git push`, `git pull`, `git fetch`, `git branch -d`)
- If you need information, use status/log/diff/show-style read-only commands only
- This skill's job is to update `.commit` content, not to change repository state

## Rules

- **When any staged changes exist, only describe and analyze staged changes** — ignore unstaged hunks in partially staged files
- Use `git diff --cached` / `git diff --cached --stat` as the source of truth for the commit content when staged changes exist
- In `git status --short`, staged changes are shown in the first status column; unstaged-only changes are shown only in the second column and must not be used for the commit message when staged changes exist
- If there are no staged changes, describe the current modified/untracked files from `git status --short` and `git diff --stat`
- **Only describe files that appear in the relevant status/diff source** — never mention files that are not modified or staged as applicable
- `.commit` must contain exactly one readable Racket datum; do not write a free-form commit message
- Datum format is:
  ```
  (TYPE "short title"

  (feature ...)
  "detail info"
  )
  ```
- Example:
  ```racket
  (FEAT "Update Racket packaging"

  (feature "move brew source generation into package-racket"
           "include sandbox-lib in the brew minimal profile")
  "Regenerate the source archive from package-racket and update the tap formula.

  Modified:
  - package-racket.rkt
  - README.md
  "
  )
  ```
- TYPE is one of: FEAT, FIX, REFACTOR, TEST, DOCS, BUILD
- **标题必须简短**（≤50 字符），只写做了什么，不写细节。细节放 description
- The `(feature ...)` form is required. Its head symbol must be exactly `feature`; use concise strings for entries unless a symbol is clearer.
- `"detail info"` is a required string. It should explain the change, include any important safety/verification notes, and include the required `Modified:` list.
- The final closing parenthesis belongs on its own line after the detail string.
- When staged changes exist, the "Modified:" section must list exactly the files from `git diff --cached --name-only`
- When no staged changes exist, the "Modified:" section must list exactly the modified/untracked files from `git status --short`
- Compiled binaries and build artifacts should NOT be mentioned
- Keep it concise — no padding, no speculation about intent
- Before writing `.commit`, mentally validate the datum shape as `(TYPE string (feature ...) string)` and make sure the file can be parsed as a single Racket datum
