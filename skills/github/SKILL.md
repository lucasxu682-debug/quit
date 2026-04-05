---
name: github
description: >
  GitHub operations via `gh` CLI. Use when: (1) checking PR/CI status,
  (2) creating/commenting on issues, (3) listing/searching repos.
  NOT for: complex web UI interactions (use browser tool instead).
---

# GitHub Skill (gh CLI)

## 前提

- `gh` CLI 已配置好，使用 lucasxu682-debug 的 GitHub 账号
- 基本格式：`gh <command> <subcommand> <flags>`

## 常用命令速查

### 查看仓库信息
```
gh repo view <owner>/<repo> --json name,description,defaultBranchRef,createdAt,pushedAt,stargazerCount
gh repo list <owner> --limit 30
```

### 查看 PR
```
gh pr list --state all --limit 10
gh pr view <pr-number> --json title,state,body,reviews
gh pr diff <pr-number>
```

### 查看 CI 状态
```
gh run list --limit 10
gh run view <run-id> --json status,conclusion,steps
```

### 查看 Issues
```
gh issue list --state all --limit 10
gh issue view <issue-number>
```

### 创建 PR/Issue
```
gh pr create --title "..." --body "..."
gh issue create --title "..." --body "..."
```

## 输出格式

用 `--jq` 获取特定字段，用 `--json` 获取完整结构：
```
gh api repos/<owner>/<repo>/commits --jq '.[0:3] | .[] | {message: .commit.message, date: .commit.author.date}'
```

## 常见错误

- `gh: command not found` → gh CLI 未安装
- `GraphQL` errors → 可能是 rate limit，`gh auth status` 查看
- `REPO_NOT_FOUND` → 检查 owner/repo 名称是否正确

## 注意

- `deliveryStatus: unknown` 在 gh commands 中不会出现，此处特指 cron job 的 Discord delivery
- GitHub API 有 rate limit，未登录用户更严格；`gh` CLI 用你的账号，请求限额更高
