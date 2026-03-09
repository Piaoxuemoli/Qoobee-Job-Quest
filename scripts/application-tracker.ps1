param(
    [ValidateSet("add", "update")]
    [string]$Action,
    [string]$Id,
    [string]$Company,
    [ValidateSet("秋招", "春招", "日常实习", "暑期实习")]
    [string]$TrackType,
    [ValidateSet("已投递", "测评", "HR联系", "笔试", "一面", "二面", "三面", "四面", "面委会", "HR面", "Offer", "拒绝", "主动中止")]
    [string]$Progress,
    [string]$Role,
    [string]$Url,
    [string]$Time,
    [string]$Notes = "",
    [ValidateSet("ask", "yes", "no")]
    [string]$Sync = "no",
    [switch]$Initialize
)

$TrackTypes = @("秋招", "春招", "日常实习", "暑期实习")
$ProgressList = @("已投递", "测评", "HR联系", "笔试", "一面", "二面", "三面", "四面", "面委会", "HR面", "Offer", "拒绝", "主动中止")
$SummaryStart = "<!-- SUMMARY_START -->"
$SummaryEnd = "<!-- SUMMARY_END -->"
$RecordsStart = "<!-- RECORDS_START -->"
$RecordsEnd = "<!-- RECORDS_END -->"
$TimelineStart = "<!-- TIMELINE_START -->"
$TimelineEnd = "<!-- TIMELINE_END -->"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ReadmePath = Join-Path $RepoRoot "README.md"

function Require-Value {
    param(
        [string]$Label,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "缺少必填参数：$Label"
    }
    return $Value.Trim()
}

function Validate-ChoiceValue {
    param(
        [string]$Label,
        [string[]]$Choices,
        [string]$Value
    )

    $trimmed = Require-Value -Label $Label -Value $Value
    if ($Choices -notcontains $trimmed) {
        throw "$Label 取值不合法：$trimmed。可选值：$($Choices -join '、')"
    }
    return $trimmed
}

function Normalize-DateTime {
    param(
        [string]$Value,
        [bool]$AllowEmpty = $false
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($AllowEmpty) {
            return ""
        }
        return (Get-Date).ToString("yyyy-MM-dd HH:mm")
    }

    $formats = @("yyyy-MM-dd HH:mm", "yyyy/MM/dd HH:mm", "yyyy-MM-dd", "yyyy/MM/dd")
    foreach ($format in $formats) {
        $parsed = [datetime]::MinValue
        if ([datetime]::TryParseExact($Value.Trim(), $format, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$parsed)) {
            return $parsed.ToString("yyyy-MM-dd HH:mm")
        }
    }

    $fallback = [datetime]::MinValue
    if ([datetime]::TryParse($Value.Trim(), [ref]$fallback)) {
        return $fallback.ToString("yyyy-MM-dd HH:mm")
    }

    throw "时间格式不合法：$Value。示例：2026-03-02 21:30"
}

function Validate-UrlValue {
    param(
        [string]$Value,
        [bool]$AllowEmpty = $false
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($AllowEmpty) {
            return ""
        }
        throw "官网链接不能为空。"
    }

    $uri = $null
    if (-not [System.Uri]::TryCreate($Value.Trim(), [System.UriKind]::Absolute, [ref]$uri)) {
        throw "官网链接格式不合法：$Value"
    }
    if ($uri.Scheme -notin @("http", "https")) {
        throw "官网链接必须以 http 或 https 开头：$Value"
    }
    return $uri.AbsoluteUri
}

function New-ReadmeTemplate {
    @"
# 简历投递记录

本仓库用于维护个人投递记录，打开仓库即可查看最新进展。

## 投递概览

$SummaryStart
- 总投递数：0
- 按类型统计：秋招 0｜春招 0｜日常实习 0｜暑期实习 0
- 按进度统计：已投递 0｜测评 0｜HR联系 0｜笔试 0｜一面 0｜二面 0｜三面 0｜四面 0｜面委会 0｜HR面 0｜Offer 0｜拒绝 0｜主动中止 0
- 最近更新时间：未更新
$SummaryEnd

## 投递明细

$RecordsStart
| ID | 时间 | 公司 | 类型 | 岗位 | 进度 | 官网 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- |
$RecordsEnd

## 投递时间轴

$TimelineStart
<div style="display:flex;flex-wrap:wrap;gap:8px;align-items:center;">
</div>
$TimelineEnd

## 使用说明

- 初始化 README 机器维护区块：`pwsh ./scripts/application-tracker.ps1 -Initialize`
- 新增投递记录（参数化）：`pwsh ./scripts/application-tracker.ps1 -Action add -Company "示例公司" -TrackType "春招" -Progress "已投递" -Role "后端开发" -Url "https://example.com/jobs/1" -Time "2026-03-02 21:30"`
- 修改投递记录（参数化）：`pwsh ./scripts/application-tracker.ps1 -Action update -Id "001" -Progress "一面"`
- 新增记录并直接指定字段：
    - `pwsh ./scripts/application-tracker.ps1 -Action add -Company "示例公司" -TrackType "春招" -Progress "已投递" -Role "后端开发" -Url "https://example.com/jobs/1" -Time "2026-03-02 21:30"`
- 修改记录并指定 ID：
    - `pwsh ./scripts/application-tracker.ps1 -Action update -Id "001" -Progress "一面"`

## 记录规则

- 投递类型枚举：秋招、春招、日常实习、暑期实习
- 进度枚举：已投递、测评、HR联系、笔试、一面、二面、三面、四面、面委会、HR面、Offer、拒绝、主动中止
- 进度非必经：允许跳过部分阶段，允许在任意阶段更新为拒绝或主动中止
- 修改定位优先级：ID > 公司+岗位+时间
- 编号规则：三位数字 ID（001、002...），每次写回会按投递时间降序全量重编号

## 验证清单（MVP）

- [ ] 新增记录成功并重算统计
- [ ] 修改记录成功并重算统计
- [ ] 非法输入（时间/URL/进度）被拒绝
- [ ] 多候选记录触发二次确认
- [ ] 拒绝同步时仅保留本地 README 变更
- [ ] 同步失败时保留本地提交并输出错误原因
"@
}

function Ensure-ReadmeReady {
    param(
        [bool]$AllowRepair
    )

    if (-not (Test-Path $ReadmePath)) {
        Set-Content -Path $ReadmePath -Value (New-ReadmeTemplate) -Encoding UTF8
        return
    }

    $text = Get-Content -Raw -Path $ReadmePath
    $hasCoreMarkers = $text.Contains($SummaryStart) -and $text.Contains($SummaryEnd) -and $text.Contains($RecordsStart) -and $text.Contains($RecordsEnd)

    if (-not $hasCoreMarkers) {
        if (-not $AllowRepair) {
            throw "README 缺少机器维护标记区块。请先执行: pwsh ./scripts/application-tracker.ps1 -Initialize"
        }

        $appendix = @"

## 投递概览（机器维护）

$SummaryStart
- 总投递数：0
- 按类型统计：秋招 0｜春招 0｜日常实习 0｜暑期实习 0
- 按进度统计：已投递 0｜测评 0｜HR联系 0｜笔试 0｜一面 0｜二面 0｜三面 0｜四面 0｜面委会 0｜HR面 0｜Offer 0｜拒绝 0｜主动中止 0
- 最近更新时间：未更新
$SummaryEnd

## 投递明细（机器维护）

$RecordsStart
| ID | 时间 | 公司 | 类型 | 岗位 | 进度 | 官网 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- |
$RecordsEnd
"@

        $text = $text + $appendix
        Set-Content -Path $ReadmePath -Value $text -Encoding UTF8
        $text = Get-Content -Raw -Path $ReadmePath
    }

    $hasTimelineMarkers = $text.Contains($TimelineStart) -and $text.Contains($TimelineEnd)
    if ($hasTimelineMarkers) {
        return
    }

    $appendix = @"

## 投递时间轴（机器维护）

$TimelineStart
<div style="display:flex;flex-wrap:wrap;gap:8px;align-items:center;">
</div>
$TimelineEnd
"@

    Set-Content -Path $ReadmePath -Value ($text + $appendix) -Encoding UTF8
}

function Get-Block {
    param(
        [string]$Text,
        [string]$StartMarker,
        [string]$EndMarker
    )

    $pattern = "(?s)" + [regex]::Escape($StartMarker) + "(.*?)" + [regex]::Escape($EndMarker)
    $match = [regex]::Match($Text, $pattern)
    if (-not $match.Success) {
        throw "未找到标记区块：$StartMarker"
    }
    return $match.Groups[1].Value.Trim("`r", "`n")
}

function Set-Block {
    param(
        [string]$Text,
        [string]$StartMarker,
        [string]$EndMarker,
        [string]$Body
    )

    $replacement = "$StartMarker`r`n$Body`r`n$EndMarker"
    $pattern = "(?s)" + [regex]::Escape($StartMarker) + ".*?" + [regex]::Escape($EndMarker)
    $regex = [regex]::new($pattern)
    return $regex.Replace($Text, $replacement, 1)
}

function Parse-Records {
    param([string]$RecordsBlock)

    $items = New-Object System.Collections.Generic.List[object]
    $lines = $RecordsBlock -split "`r?`n"
        foreach ($line in $lines) {
        $trim = $line.Trim()
        if (-not $trim.StartsWith("|")) {
            continue
        }
        if ($trim -match "\|\s*---") {
            continue
        }

        $cells = $trim.Trim('|').Split('|') | ForEach-Object { $_.Trim() }
        if ($cells.Count -lt 8) {
            continue
        }
        if ($cells[0] -eq "ID") {
            continue
        }

        $items.Add([pscustomobject]@{
            Id = $cells[0]
            Time = $cells[1]
            Company = $cells[2]
            TrackType = $cells[3]
            Role = $cells[4]
            Progress = $cells[5]
            Url = $cells[6]
            Notes = $cells[7]
        })
    }
        return ,$items
}

function Build-RecordsTable {
    param([System.Collections.Generic.List[object]]$Records)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("| ID | 时间 | 公司 | 类型 | 岗位 | 进度 | 官网 | 备注 |")
    $lines.Add("| --- | --- | --- | --- | --- | --- | --- | --- |")

    $sorted = $Records | Sort-Object @{Expression = { [datetime]::Parse($_.Time) }; Descending = $true }
    foreach ($record in $sorted) {
        $notes = if ([string]::IsNullOrWhiteSpace($record.Notes)) { "" } else { $record.Notes }
        $lines.Add("| $($record.Id) | $($record.Time) | $($record.Company) | $($record.TrackType) | $($record.Role) | $($record.Progress) | $($record.Url) | $notes |")
    }

    return ($lines -join "`r`n")
}

function Build-Timeline {
    param([System.Collections.Generic.List[object]]$Records)

    $sorted = $Records | Sort-Object @{Expression = { [datetime]::Parse($_.Time) }; Descending = $true }, @{Expression = { $_.Company }}, @{Expression = { $_.Role }}
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('<div style="display:flex;flex-wrap:wrap;gap:8px;align-items:center;">')

    foreach ($record in $sorted) {
        $companySafe = [System.Security.SecurityElement]::Escape($record.Company)
        $timeSafe = [System.Security.SecurityElement]::Escape($record.Time)
        $lines.Add(('  <span style="display:inline-flex;white-space:nowrap;border:1px solid;border-radius:999px;padding:2px 10px;" title="{0}">{1}</span>' -f $timeSafe, $companySafe))
    }

    $lines.Add('</div>')
    return ($lines -join "`r`n")
}

function Convert-IdToNumber {
    param([string]$IdValue)

    if ([string]::IsNullOrWhiteSpace($IdValue)) {
        return $null
    }

    $trimmed = $IdValue.Trim()
    if ($trimmed -match '^(\d{3})$') {
        return [int]$Matches[1]
    }
    if ($trimmed -match '^\d{4}-(\d{3})$') {
        return [int]$Matches[1]
    }
    return $null
}

function Normalize-RecordIds {
    param([System.Collections.Generic.List[object]]$Records)

    $sorted = $Records | Sort-Object @{Expression = { [datetime]::Parse($_.Time) }; Descending = $true }, @{Expression = { $_.Company }}, @{Expression = { $_.Role }}, @{Expression = { $_.Id }}
    $normalized = New-Object System.Collections.Generic.List[object]

    $index = 1
    foreach ($record in $sorted) {
        $record.Id = "{0:d3}" -f $index
        $normalized.Add($record)
        $index++
    }

    return $normalized
}

function Build-Summary {
    param([System.Collections.Generic.List[object]]$Records)

    $typeCount = @{}
    foreach ($type in $TrackTypes) {
        $typeCount[$type] = 0
    }
    $progressCount = @{}
    foreach ($p in $ProgressList) {
        $progressCount[$p] = 0
    }

    foreach ($record in $Records) {
        if ($typeCount.ContainsKey($record.TrackType)) {
            $typeCount[$record.TrackType]++
        }
        if ($progressCount.ContainsKey($record.Progress)) {
            $progressCount[$record.Progress]++
        }
    }

    $typeSummary = ($TrackTypes | ForEach-Object { "$_ $($typeCount[$_])" }) -join "｜"
    $progressSummary = ($ProgressList | ForEach-Object { "$_ $($progressCount[$_])" }) -join "｜"
    $updatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm")

    return @(
        "- 总投递数：$($Records.Count)",
        "- 按类型统计：$typeSummary",
        "- 按进度统计：$progressSummary",
        "- 最近更新时间：$updatedAt"
    ) -join "`r`n"
}

function Get-NextId {
    param(
        [System.Collections.Generic.List[object]]$Records,
        [string]$TimeValue
    )

    $maxNum = 0
    foreach ($record in $Records) {
        $current = Convert-IdToNumber -IdValue $record.Id
        if ($null -ne $current -and $current -gt $maxNum) {
            $maxNum = $current
        }
    }
    return "{0:d3}" -f ($maxNum + 1)
}

function Find-RecordIndex {
    param(
        [System.Collections.Generic.List[object]]$Records,
        [string]$IdValue,
        [string]$CompanyValue,
        [string]$RoleValue,
        [string]$TimeValue
    )

    if (-not [string]::IsNullOrWhiteSpace($IdValue)) {
        $idx = 0
        foreach ($record in $Records) {
            if ($record.Id -eq $IdValue.Trim()) {
                return $idx
            }
            $idx++
        }
        throw "未找到 ID 为 $IdValue 的记录。"
    }

    if ([string]::IsNullOrWhiteSpace($CompanyValue) -or [string]::IsNullOrWhiteSpace($RoleValue) -or [string]::IsNullOrWhiteSpace($TimeValue)) {
        throw "修改记录时若未提供 ID，必须提供公司、岗位、时间用于定位。"
    }

    $normalizedTime = Normalize-DateTime -Value $TimeValue
    $candidates = New-Object System.Collections.Generic.List[int]
    for ($i = 0; $i -lt $Records.Count; $i++) {
        $record = $Records[$i]
        if ($record.Company -eq $CompanyValue.Trim() -and $record.Role -eq $RoleValue.Trim() -and $record.Time -eq $normalizedTime) {
            $candidates.Add($i)
        }
    }

    if ($candidates.Count -eq 1) {
        return $candidates[0]
    }

    if ($candidates.Count -eq 0) {
        throw "未找到匹配记录（公司+岗位+时间）。"
    }

    $candidateSummary = ($candidates | ForEach-Object {
        $record = $Records[$_]
        "$($record.Id) | $($record.Time) | $($record.Company) | $($record.Role) | $($record.Progress)"
    }) -join "；"
    throw "匹配到多条记录，请使用 -Id 精确指定。候选：$candidateSummary"
}

function Save-Readme {
    param([System.Collections.Generic.List[object]]$Records)

    $text = Get-Content -Raw -Path $ReadmePath
    $normalizedRecords = Normalize-RecordIds -Records $Records
    $summaryBody = Build-Summary -Records $normalizedRecords
    $recordsBody = Build-RecordsTable -Records $normalizedRecords
    $timelineBody = Build-Timeline -Records $normalizedRecords

    $updated = Set-Block -Text $text -StartMarker $SummaryStart -EndMarker $SummaryEnd -Body $summaryBody
    $updated = Set-Block -Text $updated -StartMarker $RecordsStart -EndMarker $RecordsEnd -Body $recordsBody
    $updated = Set-Block -Text $updated -StartMarker $TimelineStart -EndMarker $TimelineEnd -Body $timelineBody
    Set-Content -Path $ReadmePath -Value $updated -Encoding UTF8

    return $normalizedRecords
}

function Sync-Repo {
    param([string]$Mode)

    $shouldSync = $false
    switch ($Mode) {
        "yes" { $shouldSync = $true }
        "no" { $shouldSync = $false }
        default {
            Write-Host "Sync=ask 在非交互模式下已自动视为不同步；如需同步请显式传入 -Sync yes。" -ForegroundColor Yellow
            $shouldSync = $false
        }
    }

    if (-not $shouldSync) {
        Write-Host "已跳过同步。" -ForegroundColor Cyan
        return
    }

    Push-Location $RepoRoot
    try {
        & git add README.md
        if ($LASTEXITCODE -ne 0) {
            throw "git add 执行失败。"
        }

        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm")
        $message = "docs(tracker): update application records [$timestamp]"
        & git commit -m $message
        if ($LASTEXITCODE -ne 0) {
            Write-Host "git commit 未创建新提交（可能没有变更）。" -ForegroundColor Yellow
            return
        }

        & git push
        if ($LASTEXITCODE -ne 0) {
            throw "git push 失败，请稍后重试。"
        }

        Write-Host "已完成同步。" -ForegroundColor Green
    }
    catch {
        Write-Host "同步失败：$($_.Exception.Message)" -ForegroundColor Red
        Write-Host "本地 README 及本地提交已保留，可稍后重试 push。" -ForegroundColor Yellow
    }
    finally {
        Pop-Location
    }
}

try {
    Ensure-ReadmeReady -AllowRepair:$Initialize.IsPresent

    if ($Initialize.IsPresent -and [string]::IsNullOrWhiteSpace($Action)) {
        Write-Host "README 初始化/修复完成。" -ForegroundColor Green
        exit 0
    }

    if ([string]::IsNullOrWhiteSpace($Action)) {
        throw "请提供 -Action add 或 -Action update，或仅执行 -Initialize。"
    }

    $text = Get-Content -Raw -Path $ReadmePath
    $recordsBlock = Get-Block -Text $text -StartMarker $RecordsStart -EndMarker $RecordsEnd
    $records = Parse-Records -RecordsBlock $recordsBlock
    if ($null -eq $records) {
        $records = New-Object System.Collections.Generic.List[object]
    }

    if ($Action -eq "add") {
        $finalCompany = Require-Value -Label "Company" -Value $Company
        $finalTrackType = Validate-ChoiceValue -Label "TrackType" -Choices $TrackTypes -Value $TrackType
        $finalProgress = Validate-ChoiceValue -Label "Progress" -Choices $ProgressList -Value $Progress
        $finalRole = Require-Value -Label "Role" -Value $Role
        $finalUrl = Validate-UrlValue -Value (Require-Value -Label "Url" -Value $Url)
        $finalTime = Normalize-DateTime -Value $Time
        $finalNotes = $Notes

        $finalId = if (-not [string]::IsNullOrWhiteSpace($Id)) { $Id.Trim() } else { Get-NextId -Records $records -TimeValue $finalTime }
        if (($records | Where-Object { $_.Id -eq $finalId }).Count -gt 0) {
            throw "ID 重复：$finalId"
        }

        $records.Add([pscustomobject]@{
            InternalKey = [guid]::NewGuid().ToString("N")
            Id = $finalId
            Time = $finalTime
            Company = $finalCompany
            TrackType = $finalTrackType
            Role = $finalRole
            Progress = $finalProgress
            Url = $finalUrl
            Notes = $finalNotes
        })

        $savedRecords = Save-Readme -Records $records
        $savedItem = $savedRecords | Where-Object { $_.InternalKey -eq $records[-1].InternalKey } | Select-Object -First 1
        if ($null -ne $savedItem) {
            Write-Host "已新增记录：$($savedItem.Id)" -ForegroundColor Green
        }
        else {
            Write-Host "已新增记录：$finalId" -ForegroundColor Green
        }
    }

    if ($Action -eq "update") {
        $locatorCompany = $Company
        $locatorRole = $Role
        $locatorTime = $Time

        $index = Find-RecordIndex -Records $records -IdValue $Id -CompanyValue $locatorCompany -RoleValue $locatorRole -TimeValue $locatorTime
        $record = $records[$index]
        $original = [pscustomobject]@{
            TrackType = $record.TrackType
            Progress = $record.Progress
            Role = $record.Role
            Url = $record.Url
            Time = $record.Time
            Notes = $record.Notes
        }

        $newTrackType = $TrackType
        $newProgress = $Progress
        $newRole = $Role
        $newUrl = $Url
        $newTime = $Time
        $newNotes = $Notes

        if (-not [string]::IsNullOrWhiteSpace($newTrackType) -and $TrackTypes -notcontains $newTrackType.Trim()) {
            throw "投递类型不合法：$newTrackType"
        }
        if (-not [string]::IsNullOrWhiteSpace($newProgress) -and $ProgressList -notcontains $newProgress.Trim()) {
            throw "进度不合法：$newProgress"
        }

        $hasAnyUpdate = @($newTrackType, $newProgress, $newRole, $newUrl, $newTime, $newNotes) |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        if ($hasAnyUpdate.Count -eq 0) {
            throw "未提供任何可更新字段。请至少传入 TrackType/Progress/Role/Url/Time/Notes 之一。"
        }

        if (-not [string]::IsNullOrWhiteSpace($newTrackType)) { $record.TrackType = $newTrackType.Trim() }
        if (-not [string]::IsNullOrWhiteSpace($newProgress)) { $record.Progress = $newProgress.Trim() }
        if (-not [string]::IsNullOrWhiteSpace($newRole)) { $record.Role = $newRole.Trim() }
        if (-not [string]::IsNullOrWhiteSpace($newUrl)) { $record.Url = Validate-UrlValue -Value $newUrl }
        if (-not [string]::IsNullOrWhiteSpace($newTime)) { $record.Time = Normalize-DateTime -Value $newTime }
        if (-not [string]::IsNullOrWhiteSpace($newNotes)) { $record.Notes = $newNotes.Trim() }

        $changed = (
            $record.TrackType -ne $original.TrackType -or
            $record.Progress -ne $original.Progress -or
            $record.Role -ne $original.Role -or
            $record.Url -ne $original.Url -or
            $record.Time -ne $original.Time -or
            $record.Notes -ne $original.Notes
        )

        if (-not $changed) {
            Write-Host "未检测到字段变化，已跳过写入。" -ForegroundColor Cyan
            Sync-Repo -Mode $Sync
            exit 0
        }

        $records[$index] = $record
        $savedRecords = Save-Readme -Records $records
        $savedItem = $savedRecords | Where-Object { $_.Company -eq $record.Company -and $_.Role -eq $record.Role -and $_.Time -eq $record.Time -and $_.Url -eq $record.Url } | Select-Object -First 1
        Write-Host "已更新记录：$($record.Id)" -ForegroundColor Green
        if ($null -ne $savedItem) {
            Write-Host "修改后：$($savedItem.Id) | $($savedItem.Time) | $($savedItem.Company) | $($savedItem.Role) | $($savedItem.Progress)"
        }
        else {
            Write-Host "修改后：$($record.Time) | $($record.Company) | $($record.Role) | $($record.Progress)"
        }
    }

    Sync-Repo -Mode $Sync
}
catch {
    Write-Host "执行失败：$($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
