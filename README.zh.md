# commit Skill

`commit` 是一个用于 Codex/agent 的小型 skill，用来根据当前 Git 变更生成仓库里的
`.commit` 文件。

英文文档见 [README.md](README.md)。

它不会创建提交。它的职责是用只读 Git 命令查看工作区，把结构化的提交信息 datum
写入 `.commit`，并在有 Racket 可用时用随附脚本校验这个 datum。

## 它会做什么

- 读取 `git status --short`，识别 staged、unstaged 和 untracked 文件。
- 只要存在 staged 变更，就只以 staged 变更作为提交内容来源。
- 如果没有 staged 变更，则退回到当前 modified 和 untracked 文件。
- 把 `.commit` 写成且只写成一个可读的 Racket datum。
- 生成简洁说明，并包含必需的 `Modified:` 文件列表。
- 在 Racket 可用时运行 `scripts/check-commit-message.rkt` 校验。

## 它不会做什么

- 不会运行 `git add`。
- 不会运行 `git commit`。
- 不会 reset、restore、rebase、merge、fetch、pull、push，也不会做其他会改变 Git
  状态的操作。
- 不会描述不在相关 status 或 diff 来源里的文件。
- 不会把现有 `.commit` 草稿当成格式权威；真正的规则以 `SKILL.md` 和校验脚本为准。

## 项目结构

```text
.
|- SKILL.md
|- scripts/
|  `- check-commit-message.rkt
|- README.md
`- README.zh.md
```

`SKILL.md` 是实际的 skill 定义，也是行为规则来源。
`scripts/check-commit-message.rkt` 用来校验生成的 `.commit` datum。

## 提交信息 Datum 格式

`.commit` 必须只包含一个 Racket datum，形状如下：

```racket
(TYPE "short title"

()
"detail info"
)
```

`TYPE` 只能是：

```text
FEAT FIX REFACTOR TEST DOCS BUILD
```

第三个字段是元数据列表，默认使用 `()`。不要在这里写字面量 `(feature ...)`，那是旧的
元语法，不是当前 datum 形状。

detail 字符串必须包含 `Modified:` 小节。当存在 staged 变更时，这个列表必须精确匹配
`git diff --cached --name-only`。当没有 staged 变更时，它必须精确匹配
`git status --short` 中的 modified 和 untracked 文件。

示例：

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

## 校验

在本仓库中，可以这样校验候选 `.commit` 文件：

```sh
racket scripts/check-commit-message.rkt --message-file .commit
```

如果在其他仓库中使用这个 skill，请把脚本路径换成实际安装位置：

```sh
racket /path/to/commit/scripts/check-commit-message.rkt --message-file .commit
```

校验脚本会检查：

- 文件里只有一个可读的 Racket datum；
- datum 形状是 `(TYPE string list string)`；
- `TYPE` 属于允许集合；
- 标题非空，且不超过 50 个字符；
- 元数据字段是列表，并且不是 `(feature ...)`；
- detail 字符串包含 `Modified:`。

## 使用说明

当你想为当前仓库状态生成 `.commit` 草稿时调用这个 skill。如果当前有 staged 文件，
请把生成结果当成 staged 变更的提交信息来审阅；如果没有 staged 文件，请把它当成
整个工作区的提交草稿来审阅。

`.commit` 故意使用结构化 datum，而不是自由文本提交信息。这样后续工具可以稳定解析，
不用从普通文本里猜测字段。
