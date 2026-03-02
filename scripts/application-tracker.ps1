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
    [string]$Sync = "ask",
    [switch]$Initialize
)

$TrackTypes = @("秋招", "春招", "日常实习", "暑期实习")
$ProgressList = @("已投递", "测评", "HR联系", "笔试", "一面", "二面", "三面", "四面", "面委会", "HR面", "Offer", "拒绝", "主动中止")
$SummaryStart = "<!-- SUMMARY_START -->"
$SummaryEnd = "<!-- SUMMARY_END -->"
$RecordsStart = "<!-- RECORDS_START -->"
$RecordsEnd = "<!-- RECORDS_END -->"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ReadmePath = Join-Path $RepoRoot "README.md"

function Read-YesNo {
    param(
        [string]$Message,
        [bool]$DefaultNo = $true
    )

    $suffix = if ($DefaultNo) { "[y/N]" } else { "[Y/n]" }
    $inputValue = Read-Host "$Message $suffix"
    if ([string]::IsNullOrWhiteSpace($inputValue)) {
        return -not $DefaultNo
    }
    return $inputValue.Trim().ToLowerInvariant() -in @("y", "yes")
}

function Read-Required {
    param(
        [string]$Label,
        [string]$Current
    )

    if (-not [string]::IsNullOrWhiteSpace($Current)) {
        return $Current.Trim()
    }

    while ($true) {
        $value = Read-Host $Label
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value.Trim()
        }
        Write-Host "字段不能为空，请重新输入。" -ForegroundColor Yellow
    }
}

function Read-Choice {
    param(
        [string]$Label,
        [string[]]$Choices,
        [string]$Current,
        [bool]$AllowEmpty = $false
    )

    if (-not [string]::IsNullOrWhiteSpace($Current)) {
        if ($Choices -contains $Current.Trim()) {
            return $Current.Trim()
        }
        throw "字段 $Label 的取值不合法：$Current"
    }

    while ($true) {
        Write-Host "$Label 可选值：$($Choices -join '、')"
        $value = Read-Host $Label
        if ($AllowEmpty -and [string]::IsNullOrWhiteSpace($value)) {
            return ""
        }
        if ($Choices -contains $value.Trim()) {
            return $value.Trim()
        }
        Write-Host "取值不合法，请从枚举中选择。" -ForegroundColor Yellow
    }
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
    $hasMarkers = $text.Contains($SummaryStart) -and $text.Contains($SummaryEnd) -and $text.Contains($RecordsStart) -and $text.Contains($RecordsEnd)

    if ($hasMarkers) {
        return
    }

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

    $year = [datetime]::Parse($TimeValue).ToString("yyyy")
    $maxNum = 0
    foreach ($record in $Records) {
        if ($record.Id -match "^$year-(\d{3})$") {
            $current = [int]$Matches[1]
            if ($current -gt $maxNum) {
                $maxNum = $current
            }
        }
    }
    return "$year-{0:d3}" -f ($maxNum + 1)
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

    Write-Host "匹配到多条记录，请选择目标序号：" -ForegroundColor Yellow
    for ($j = 0; $j -lt $candidates.Count; $j++) {
        $record = $Records[$candidates[$j]]
        Write-Host "[$j] $($record.Id) | $($record.Time) | $($record.Company) | $($record.Role) | $($record.Progress)"
    }

    while ($true) {
        $raw = Read-Host "输入序号"
        $picked = -1
        if ([int]::TryParse($raw, [ref]$picked) -and $picked -ge 0 -and $picked -lt $candidates.Count) {
            return $candidates[$picked]
        }
        Write-Host "序号无效，请重试。" -ForegroundColor Yellow
    }
}

function Save-Readme {
    param([System.Collections.Generic.List[object]]$Records)

    $text = Get-Content -Raw -Path $ReadmePath
    $summaryBody = Build-Summary -Records $Records
    $recordsBody = Build-RecordsTable -Records $Records

    $updated = Set-Block -Text $text -StartMarker $SummaryStart -EndMarker $SummaryEnd -Body $summaryBody
    $updated = Set-Block -Text $updated -StartMarker $RecordsStart -EndMarker $RecordsEnd -Body $recordsBody
    Set-Content -Path $ReadmePath -Value $updated -Encoding UTF8
}

function Sync-Repo {
    param([string]$Mode)

    $shouldSync = $false
    switch ($Mode) {
        "yes" { $shouldSync = $true }
        "no" { $shouldSync = $false }
        default { $shouldSync = Read-YesNo -Message "是否同步到 GitHub？" -DefaultNo $true }
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
        $finalCompany = Read-Required -Label "公司名" -Current $Company
        $finalTrackType = Read-Choice -Label "投递类型" -Choices $TrackTypes -Current $TrackType
        $finalProgress = Read-Choice -Label "当前进度" -Choices $ProgressList -Current $Progress
        $finalRole = Read-Required -Label "投递岗位" -Current $Role
        $finalUrl = Validate-UrlValue -Value (Read-Required -Label "官网网址" -Current $Url)
        $finalTime = Normalize-DateTime -Value $Time
        $finalNotes = $Notes

        $finalId = if (-not [string]::IsNullOrWhiteSpace($Id)) { $Id.Trim() } else { Get-NextId -Records $records -TimeValue $finalTime }
        if (($records | Where-Object { $_.Id -eq $finalId }).Count -gt 0) {
            throw "ID 重复：$finalId"
        }

        $records.Add([pscustomobject]@{
            Id = $finalId
            Time = $finalTime
            Company = $finalCompany
            TrackType = $finalTrackType
            Role = $finalRole
            Progress = $finalProgress
            Url = $finalUrl
            Notes = $finalNotes
        })

        Save-Readme -Records $records
        Write-Host "已新增记录：$finalId" -ForegroundColor Green
    }

    if ($Action -eq "update") {
        $locatorCompany = $Company
        $locatorRole = $Role
        $locatorTime = $Time

        if ([string]::IsNullOrWhiteSpace($Id)) {
            if ([string]::IsNullOrWhiteSpace($locatorCompany)) { $locatorCompany = Read-Host "公司名（定位用）" }
            if ([string]::IsNullOrWhiteSpace($locatorRole)) { $locatorRole = Read-Host "岗位（定位用）" }
            if ([string]::IsNullOrWhiteSpace($locatorTime)) { $locatorTime = Read-Host "时间（定位用）" }
        }

        $index = Find-RecordIndex -Records $records -IdValue $Id -CompanyValue $locatorCompany -RoleValue $locatorRole -TimeValue $locatorTime
        $record = $records[$index]

        $newTrackType = $TrackType
        $newProgress = $Progress
        $newRole = $Role
        $newUrl = $Url
        $newTime = $Time
        $newNotes = ""

        if ([string]::IsNullOrWhiteSpace($newTrackType)) {
            $inputType = Read-Host "投递类型新值（留空不改）"
            if (-not [string]::IsNullOrWhiteSpace($inputType)) {
                if ($TrackTypes -notcontains $inputType.Trim()) { throw "投递类型不合法：$inputType" }
                $newTrackType = $inputType.Trim()
            }
        }

        if ([string]::IsNullOrWhiteSpace($newProgress)) {
            $inputProgress = Read-Host "当前进度新值（留空不改）"
            if (-not [string]::IsNullOrWhiteSpace($inputProgress)) {
                if ($ProgressList -notcontains $inputProgress.Trim()) { throw "进度不合法：$inputProgress" }
                $newProgress = $inputProgress.Trim()
            }
        }

        if ([string]::IsNullOrWhiteSpace($newRole)) {
            $inputRole = Read-Host "岗位新值（留空不改）"
            if (-not [string]::IsNullOrWhiteSpace($inputRole)) { $newRole = $inputRole.Trim() }
        }

        if ([string]::IsNullOrWhiteSpace($newUrl)) {
            $inputUrl = Read-Host "官网新值（留空不改）"
            if (-not [string]::IsNullOrWhiteSpace($inputUrl)) { $newUrl = $inputUrl.Trim() }
        }

        if ([string]::IsNullOrWhiteSpace($newTime)) {
            $inputTime = Read-Host "时间新值（留空不改）"
            if (-not [string]::IsNullOrWhiteSpace($inputTime)) { $newTime = $inputTime.Trim() }
        }

        $newNotes = Read-Host "备注新值（留空不改）"

        if (-not [string]::IsNullOrWhiteSpace($newTrackType)) { $record.TrackType = $newTrackType }
        if (-not [string]::IsNullOrWhiteSpace($newProgress)) { $record.Progress = $newProgress }
        if (-not [string]::IsNullOrWhiteSpace($newRole)) { $record.Role = $newRole }
        if (-not [string]::IsNullOrWhiteSpace($newUrl)) { $record.Url = Validate-UrlValue -Value $newUrl }
        if (-not [string]::IsNullOrWhiteSpace($newTime)) { $record.Time = Normalize-DateTime -Value $newTime }
        if (-not [string]::IsNullOrWhiteSpace($newNotes)) { $record.Notes = $newNotes.Trim() }

        $records[$index] = $record
        Save-Readme -Records $records
        Write-Host "已更新记录：$($record.Id)" -ForegroundColor Green
        Write-Host "修改后：$($record.Time) | $($record.Company) | $($record.Role) | $($record.Progress)"
    }

    Sync-Repo -Mode $Sync
}
catch {
    Write-Host "执行失败：$($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
