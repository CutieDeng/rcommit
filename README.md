# commit Skill

`commit` is a small Codex/agent skill for drafting a repository's `.commit`
file from the current Git changes.

Chinese documentation is available in [README.zh.md](README.zh.md).

It does not create commits. Its job is to inspect the working tree with
read-only Git commands, write a structured commit-message datum into `.commit`,
and optionally validate that datum with the bundled Racket checker.

## What It Does

- Reads `git status --short` to identify staged, unstaged, and untracked files.
- Uses staged changes as the source of truth whenever staged changes exist.
- Falls back to the current modified and untracked files when nothing is staged.
- Writes `.commit` as exactly one readable Racket datum.
- Keeps the generated message concise and includes a required `Modified:` file
  list.
- Runs `scripts/check-commit-message.rkt` when Racket is available.

## What It Does Not Do

- It does not run `git add`.
- It does not run `git commit`.
- It does not reset, restore, rebase, merge, fetch, pull, push, or otherwise
  mutate Git state.
- It does not describe files outside the relevant status or diff source.
- It does not treat an existing `.commit` draft as the format authority.

## Repository Layout

```text
.
|- SKILL.md
|- scripts/
|  `- check-commit-message.rkt
|- README.md
`- README.zh.md
```

`SKILL.md` is the actual skill definition and source of behavioral rules.
`scripts/check-commit-message.rkt` validates the generated `.commit` datum.

## Commit Datum Format

The `.commit` file must contain one Racket datum with this shape:

```racket
(TYPE "short title"

()
"detail info"
)
```

`TYPE` must be one of:

```text
FEAT FIX REFACTOR TEST DOCS BUILD
```

The third field is a metadata list. Use `()` by default. Do not write a literal
`(feature ...)` form there.

The detail string must contain a `Modified:` section. When staged changes exist,
that list must exactly match `git diff --cached --name-only`. When no staged
changes exist, it must exactly match the modified and untracked files reported
by `git status --short`.

Example:

```racket
(DOCS "Document commit skill"

()
"Add README files that explain the commit-message datum, read-only Git boundary,
and validation flow.

Modified:
- README.md
- README.zh.md
"
)
```

## Validation

From this repository, validate a candidate `.commit` file with:

```sh
racket scripts/check-commit-message.rkt --message-file .commit
```

When using the skill from another repository, point Racket at the installed
script path:

```sh
racket /path/to/commit/scripts/check-commit-message.rkt --message-file .commit
```

The checker verifies that:

- the file contains exactly one readable Racket datum;
- the datum shape is `(TYPE string list string)`;
- `TYPE` is allowed;
- the title is non-empty and at most 50 characters;
- the metadata field is a list and is not `(feature ...)`;
- the detail string contains `Modified:`.

## Usage Notes

Invoke the skill when you want a `.commit` draft for the current repository
state. If any files are staged, review the generated message as a staged-change
commit message. If no files are staged, review it as a working-tree draft.

The generated `.commit` is intentionally structured so downstream tooling can
parse it reliably instead of scraping a free-form commit message.
