# Owen @Mentions Daily Report v0.2

执行以下任务生成今日报告：

## 任务 1: 收集昨日 @mentions

1. 搜索**昨天**在以下 channels 中直接 @U0A5D44PQJE (Owen Liu) 的消息：
   - 所有 `#ext-straitsx-*` channels（客户 channels）
   - `#cop-integration-engineers`
   - `#cop-client-support-ticket`
   - `#cop-engineers`
   - `#cop-eng-adhoc-request`
   
2. 过滤条件：
   - 排除 bot 消息
   - 只包含直接 @Owen 的消息（搜索 `<@U0A5D44PQJE>`）

3. 回复状态检查（仅限客户 channels `ext-straitsx-*`）：
   - 读取每条 @mention 所在的 thread
   - 检查 thread 中是否有 StraitsX 内部员工的回复（非客户、非 bot）
   - 回复状态格式：
     - 已回复：`✅ @回复者` （如 `✅ @Owen`）
     - 多人回复：`✅ @回复者1, @回复者2`
     - 未回复：`⏳ 待回复`
   - 内部 channels 不需要显示回复状态，该列留空或显示 `-`

## 任务 2: 收集遗留任务 (Backlog)

1. 在 Slack 中搜索之前的 Canvas 文件（标题包含 "Owen @Mentions Report"）
2. 读取这些 Canvas，提取所有未勾选的 checklist 项（`- [ ]` 开头的行）
3. 按原始报告日期分组整理遗留任务

## 任务 3: 创建合并报告

创建**单个** Slack Canvas，标题格式："Owen @Mentions Report (YYYY-MM-DD)"

Canvas 内容结构：
```
# 📬 Owen @Mentions Report
**Date:** YYYY-MM-DD | **New:** X items | **Backlog:** Y items

---

## 🔵 Customer Channels (ext-straitsx-*) — Yesterday
- [ ] **HH:MM** | #channel | From | 内容概要 | 回复状态 | [→ thread](URL)
...

---

## 🟢 Internal Channels (cop-* / DM) — Yesterday
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

发送消息到 #owen-task-monitor (Channel ID: C0BU1DF35SN)：
- 包含 Canvas 的链接
- 简要统计：昨日新增 X 条，遗留 Y 条
