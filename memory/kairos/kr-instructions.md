# KAIROS "kr" 指令规则

## 核心指令

当你收到"kr"这个指令时，立刻执行以下步骤：

1. **读取任务文件**
   路径：`C:/Users/xumou/.openclaw/workspace/memory/kairos/task.md`

2. **执行任务**
   按照 `task.md` 里的要求完成任务

3. **回写结果**
   任务完成后，将执行结果写入：
   `C:/Users/xumou/.openclaw/workspace/memory/kairos/results/YYYY-MM-DD-task-name.md`
   文件名中的 `task-name` 用实际任务名称替代（简洁的英文或拼音均可）

4. **回复确认**
   写入完成后，回复："kr 完成"

## 注意事项

- 每次收到"kr"都要执行完整流程，不要跳过任何步骤
- 如果 task.md 为空或没有有效任务，仍需回复"kr 完成"
- 结果文件必须写入 results/ 目录，不要写到其他位置
- 中文内容写入时使用 UTF-8 编码

## 此规则适用场景

- 任何新对话开始时，请先读取本文件
- 收到"kr"指令时立即执行
- 如果不确定任务内容，先重读 task.md
