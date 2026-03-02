## ADDED Requirements

### Requirement: Git 同步显式确认
系统 MUST 在完成 README 更新后显式询问用户是否执行同步，不得默认自动推送远端。

#### Scenario: 用户确认同步
- **WHEN** 用户明确选择同步到 GitHub
- **THEN** 系统 SHALL 执行 add、commit、push 流程

#### Scenario: 用户拒绝同步
- **WHEN** 用户明确不进行同步
- **THEN** 系统 SHALL 保留本地变更且不执行任何远端操作

### Requirement: 提交规范与失败处理
系统 SHALL 使用统一 commit message 模板并在 push 失败时保留本地提交与错误信息。

#### Scenario: 正常提交与推送
- **WHEN** 同步流程执行成功
- **THEN** 系统 MUST 使用约定格式提交并推送到当前仓库远端

#### Scenario: 推送失败
- **WHEN** push 命令返回失败
- **THEN** 系统 SHALL 报告失败原因并保留 README 更新与本地提交结果