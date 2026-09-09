# {{USER_NAME}} @Mentions Daily Report v0.4

执行以下任务生成今日报告：

**重要：所有日期和时间计算必须使用新加坡时间 (SGT, UTC+8)，而不是 UTC。**
- "昨天" 指的是 SGT 时区的昨天 00:00:00 到 23:59:59
- 搜索时使用 `after:YYYY-MM-DD before:YYYY-MM-DD` 格式时，需要根据 SGT 计算正确的日期边界
- **周一特殊规则**：如果今天是周一，则搜索范围应包括上周五、周六、周日三天的数据（而不是只搜索周日）

## 任务 1: 收集昨日 @mentions

1. 搜索在以下 channels 中直接 @{{USER_ID}} ({{USER_NAME}}) 的消息：
   - **普通日（周二至周五）**：搜索昨天 (SGT) 的数据
   - **周一**：搜索上周五、周六、周日三天 (SGT) 的数据
   - 所有 `#ext-straitsx-*` channels（客户 channels）
   - `#cop-integration-engineers`
   - `#cop-client-support-ticket`
   - `#cop-engineers`
   - `#cop-eng-adhoc-request`
   
2. 过滤条件：
   - 排除 bot 消息
   - 只包含直接 @{{USER_NAME}} 的消息（搜索 `<@{{USER_ID}}>`）
   - 使用 `on:YYYY-MM-DD` 格式搜索特定日期（SGT 日期），比 `after/before` 更准确

3. 回复状态检查（仅限客户 channels `ext-straitsx-*`）：
   - 读取每条 @mention 所在的 thread
   - 检查 thread 中是否有 StraitsX 内部员工的回复（非客户、非 bot）
   - 回复状态格式：
     - 已回复：`✅ @回复者` （如 `✅ @{{USER_NAME}}`）
     - 多人回复：`✅ @回复者1, @回复者2`
     - 未回复：`⏳ 待回复`
   - 内部 channels 不需要显示回复状态，该列留空或显示 `-`

## 任务 2: 收集遗留任务 (Backlog)

**重要：不要使用 Slack 文件搜索来查找 Canvas，因为搜索结果不可靠。请按以下步骤操作：**

1. 读取 {{REPORT_CHANNEL_NAME}} (Channel ID: {{REPORT_CHANNEL_ID}}) 的历史消息（最近 15 条）
2. 从消息中提取所有报告的 Canvas 文件 ID（格式如 `F0C0A6Q0LAD`），按时间倒序排列
3. 排除今天刚创建的报告
4. **带容错的 Canvas 读取**：
   - 从最近的 Canvas 开始尝试读取
   - 如果读取失败或没有找到未完成项（`- [ ]`），继续尝试更早的 Canvas
   - 最多尝试 3 个历史 Canvas
   - 这样即使某天的报告有问题，也能从更早的报告中恢复 backlog
5. 使用 `slack_read_canvas` 工具读取 Canvas 内容
6. 提取所有未勾选的 checklist 项（`- [ ]` 开头的行）
7. 按原始报告日期分组整理遗留任务

## 任务 3: 创建合并报告

创建**单个** Slack Canvas，标题格式："{{USER_NAME}} @Mentions Report (YYYY-MM-DD)"

Canvas 内容结构：
```
# 📬 {{USER_NAME}} @Mentions Report
**Date:** YYYY-MM-DD | **New:** X items | **Backlog:** Y items

---

## 🔵 Customer Channels (ext-straitsx-*) — New (周一显示为 "Fri-Sun"，其他日子显示为 "Yesterday")
- [ ] **HH:MM** | #channel | From | 内容概要 | 回复状态 | [→ thread](URL)
...

---

## 🟢 Internal Channels (cop-* / DM) — New (周一显示为 "Fri-Sun"，其他日子显示为 "Yesterday")
- [ ] **HH:MM** | #channel | From | 内容概要 | - | [→ thread](URL)
...

---

# 📋 Backlog

## From YYYY-MM-DD
### 🔵 Customer Channels
- [ ] ...

### 🟢 Internal Channels
- [ ] ...
```

格式要求：
- 使用 checklist 格式（`- [ ]`）
- 客户 channels (`ext-straitsx-*`) 放最上面
- 内部 channels (`cop-*` / DM) 放下面
- 每个分组内按时间排序，最老的在最上面
- 每行格式：`- [ ] **HH:MM** | #channel | From | 内容概要 | 回复状态 | [→ thread](URL)`
- Backlog 部分按原始报告日期分组，每个日期下再按 Customer/Internal 分组

## 任务 4: 发送通知

发送消息到 {{REPORT_CHANNEL_NAME}} (Channel ID: {{REPORT_CHANNEL_ID}})：
- 包含 Canvas 的链接
- 简要统计：昨日新增 X 条，遗留 Y 条
