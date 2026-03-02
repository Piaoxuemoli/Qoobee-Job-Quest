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
- 官网必须为 http/https
- 同步必须显式确认（`-Sync ask`/`yes`/`no`）
- 提交信息模板：`docs(tracker): update application records [timestamp]`
