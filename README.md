# 简历投递记录

本仓库用于维护个人投递记录，打开仓库即可查看最新进展。

## 投递概览

<!-- SUMMARY_START -->
- 总投递数：6
- 按类型统计：秋招 0｜春招 0｜日常实习 1｜暑期实习 5
- 按进度统计：已投递 4｜测评 1｜HR联系 0｜笔试 0｜一面 0｜二面 0｜三面 0｜四面 0｜面委会 0｜HR面 0｜Offer 0｜拒绝 0｜主动中止 1
- 最近更新时间：2026-03-03 00:32
<!-- SUMMARY_END -->

## 投递明细

<!-- RECORDS_START -->
| ID | 时间 | 公司 | 类型 | 岗位 | 进度 | 官网 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2026-005 | 2026-03-03 00:00 | 网易雷火 | 暑期实习 | web前端开发实习生（游戏宣发官网方向）（精英实习） | 已投递 | https://campus.163.com/app/personal/apply |  |
| 2026-006 | 2026-03-03 00:00 | 携程 | 暑期实习 | 前端开发工程师 | 已投递 | https://job.ctrip.com/#/personal-homepage |  |
| 2026-004 | 2026-02-28 00:00 | 米哈游 | 暑期实习 | 前端开发实习生 | 主动中止 | https://jobs.mihoyo.com/#/campus/applyRecord | 曾HR联系 |
| 2026-002 | 2026-02-27 00:00 | vivo | 暑期实习 | 软件工程师（前端方向） | 测评 | https://hr-campus.vivo.com/personal/deliveryRecord |  |
| 2026-003 | 2026-02-27 00:00 | 腾讯音乐 | 暑期实习 | 软件开发-前端开发方向 | 已投递 | https://join.tencentmusic.com/deliver |  |
| 2026-001 | 2026-02-11 00:00 | 微软 | 日常实习 | Software Engineer | 已投递 | https://apply.careers.microsoft.com/careers/dashboard?domain=microsoft.com |  |
<!-- RECORDS_END -->

## 使用说明

- 初始化 README 机器维护区块：`pwsh ./scripts/application-tracker.ps1 -Initialize`
- 新增投递记录（交互）：`pwsh ./scripts/application-tracker.ps1 -Action add`
- 修改投递记录（交互）：`pwsh ./scripts/application-tracker.ps1 -Action update`
- 新增记录并直接指定字段：
  - `pwsh ./scripts/application-tracker.ps1 -Action add -Company "示例公司" -TrackType "春招" -Progress "已投递" -Role "后端开发" -Url "https://example.com/jobs/1" -Time "2026-03-02 21:30"`
- 修改记录并指定 ID：
  - `pwsh ./scripts/application-tracker.ps1 -Action update -Id "2026-001" -Progress "一面"`

## 记录规则

- 投递类型枚举：秋招、春招、日常实习、暑期实习
- 进度枚举：已投递、测评、HR联系、笔试、一面、二面、三面、四面、面委会、HR面、Offer、拒绝、主动中止
- 进度非必经：允许跳过部分阶段，允许在任意阶段更新为拒绝或主动中止
- 修改定位优先级：ID > 公司+岗位+时间

## 验证清单（MVP）

- [ ] 新增记录成功并重算统计
- [ ] 修改记录成功并重算统计
- [ ] 非法输入（时间/URL/进度）被拒绝
- [ ] 多候选记录触发二次确认
- [ ] 拒绝同步时仅保留本地 README 变更
- [ ] 同步失败时保留本地提交并输出错误原因






