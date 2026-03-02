## Purpose

定义 README 作为投递看板时的机器维护区块与统计输出格式，确保自动更新安全可控。

## Requirements

### Requirement: README 机器维护区块
系统 MUST 在 README 中维护固定标记区块，用于自动更新统计摘要与投递明细，同时不破坏区块外的人工内容。

#### Scenario: 更新统计区块
- **WHEN** 新增或修改投递记录后触发文档更新
- **THEN** 系统 SHALL 仅重写 SUMMARY 标记区块内容并保留其他文本不变

#### Scenario: 更新明细区块
- **WHEN** 新增或修改投递记录后触发文档更新
- **THEN** 系统 SHALL 仅重写 RECORDS 标记区块内的 Markdown 表格并保留区块外内容

### Requirement: 统计字段一致性
系统 SHALL 基于“当前进度”计算统计结果，至少包含总投递数、按类型统计、按进度统计和最近更新时间。

#### Scenario: 新增记录后重算统计
- **WHEN** 新增一条合法投递记录
- **THEN** 系统 MUST 重新计算并更新总数、类型计数、进度计数和最近更新时间

#### Scenario: 修改记录进度后重算统计
- **WHEN** 用户将某记录进度从已投递更新为面委会
- **THEN** 系统 SHALL 减少已投递计数并增加面委会计数
