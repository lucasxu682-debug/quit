# GitHub 每周热门项目收集任务

## 任务说明
每周第一次对话时，收集GitHub当前周热度最高的10个项目并介绍给用户。

## 执行流程
1. 使用 GitHub API 获取 Trending 项目
2. 筛选前10个最热门的项目
3. 获取每个项目的详细信息（描述、语言、Star数等）
4. 生成介绍报告
5. 保存到本地文件和GitHub仓库

## 命令
```bash
# 获取Trending项目（本周）
gh api search/repositories --method=GET -f q="created:>$(date -d '7 days ago' +%Y-%m-%d)" -f sort="stars" -f order="desc" -f per_page="10"
```

## 输出格式
- 本地保存：`memory/github_trending_YYYY-MM-DD.md`
- 包含：项目名称、描述、语言、Star数、Fork数、本周新增Star

## 触发条件
- 每周第一次对话
- 用户主动要求
