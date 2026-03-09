---
name: job-application-tracker
description: 统计简历投递记录并自动更新 README，支持新增/修改记录和可选同步到 GitHub。
license: MIT
compatibility: PowerShell 7+
metadata:
  author: local
  version: "1.0"
---

## 目标

通过统一对话参数和脚本入口，完成以下能力：

- 新增投递记录并自动重算统计
- 修改已有记录并自动重算统计
- 仅更新 README 机器维护区块，不改动人工内容
- 自动维护 README 时间轴（公司名横向排列，超宽自动换行）
- 可选执行 git add/commit/push 同步到远端仓库

## 触发线

- 新增触发：用户表达“新增投递”“记录投递”
- 修改触发：用户表达“修改投递”“更新进度”

## 参数与枚举

- 投递类型：秋招、春招、日常实习、暑期实习
- 进度：已投递、测评、HR联系、笔试、一面、二面、三面、四面、面委会、HR面、Offer、拒绝、主动中止
- 进度流程非必经，可跳跃或提前结束

## 推荐执行

- 初始化：`pwsh ./scripts/application-tracker.ps1 -Initialize`
- 新增（交互）：`pwsh ./scripts/application-tracker.ps1 -Action add`
- 修改（交互）：`pwsh ./scripts/application-tracker.ps1 -Action update`
- 明确同步：`pwsh ./scripts/application-tracker.ps1 -Action add -Sync yes`

## 约束

- 修改定位优先级：ID > 公司+岗位+时间
- 编号规则为三位数字（001、002...），每次写回按投递时间降序全量重编号
- 官网必须为 http/https
- 同步必须显式确认（`-Sync ask`/`yes`/`no`）
- 提交信息模板：`docs(tracker): update application records [timestamp]`

## 缺失信息补全规则

- 使用本 skill 时，如果用户未提供完整字段，系统必须补问并等待补全后再执行写入
- 新增记录最少需要：公司、投递类型、进度、岗位、官网、时间
- 修改记录最少需要：`ID`，或 `公司+岗位+时间` 组合用于兜底定位
- 若同步策略不明确，必须显式询问是否执行完整 Git 同步流程（add/commit/push）

## README 时间轴维护流程

- 每次 `add`/`update` 后，脚本同时重写 `TIMELINE` 机器维护区块
- 时间轴仅展示公司名，按投递时间降序排列
- 渲染使用 HTML `div/span` 横向布局，`flex-wrap: wrap` 超宽自动换行

## Git 同步全流程

- 触发条件：用户明确要求“同步仓库 / 提交并推送 / 处理整个 git 流程”
- 执行顺序：`git add` → `git commit` → `git push`
- `git add`：默认添加本次修改文件；未指定时可添加全部变更
- `git commit`：使用模板 `docs(tracker): update application records [timestamp]`
- `git push`：提交后立即推送当前分支
- 失败处理：
  - `add` 或 `commit` 失败时停止后续步骤并返回错误
  - `push` 失败时保留本地提交，提示用户稍后重试推送
