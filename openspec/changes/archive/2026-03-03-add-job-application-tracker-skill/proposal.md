## Why

当前仓库用于管理简历投递记录，但缺少统一的数据结构、可重复的更新流程和稳定的统计口径，导致新增/修改记录时容易漏字段、状态命名不一致、统计结果不可靠。现在需要一个最小可用的记录方案，让用户通过对话即可维护 README，并可选择同步到同仓库 GitHub。

## What Changes

- 定义投递记录的标准字段与校验规则，覆盖新增与修改两条对话触发线。
- 定义 README 的完整初始模板（机器维护区+人工可读区），确保统计与明细可自动更新。
- 定义进度枚举与统计口径，支持非线性流程（可跳跃、可提前结束）。
- 定义 skill 的技术方案：对话收集、记录定位、更新策略、异常处理与确认机制。
- 定义仓库 Git 管理方案：提交规范、推送确认、失败处理与最小审计信息。

## Capabilities

### New Capabilities
- `application-record-schema`: 规范投递记录的数据模型、必填字段、ID 规则与输入校验。
- `application-progress-lifecycle`: 定义进度枚举与状态更新规则，包含“已投递、测评、HR联系、笔试、一面、二面、三面、四面、面委会、HR面、Offer、拒绝、主动中止”，并明确流程非必经。
- `readme-tracker-template`: 定义 README 初始模板与机器维护标记区，支持自动重算统计和明细表更新。
- `conversation-upsert-flow`: 定义新增/修改两条对话流程、记录定位策略（优先 ID）及冲突处理。
- `git-sync-policy`: 定义可选同步到 GitHub 的提交流程、commit message 规范与失败回退策略。

### Modified Capabilities
- None.

## Impact

- 主要影响文档与流程规范：README 结构、记录字段规范、统计口径与操作流程。
- 后续实现将影响本仓库自动化脚本/skill 提示词与相关操作命令（git add/commit/push）。
- 不涉及现有运行时服务 API 兼容性破坏；若未来引入脚本，仅需遵循本提案的字段与状态定义。