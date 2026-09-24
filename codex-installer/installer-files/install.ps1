# ============================================================
#  Codex 中文一键安装器 · Windows 版（1.0.0 · 2026-09-24）
#  由「双击安装.bat」调用。不需要管理员权限，全部装在当前用户目录。
#  装好后桌面出现图标「打开 Codex」（打开工作文件夹并运行 codex）
#  不内置任何代理 / 翻墙，不预填任何 key。第一次打开用 ChatGPT 账号登录。
#
#  测试参数（普通用户用不到）：
#    -DryRun        只演练：打印每一步，不下载、不安装、不改任何文件，也不运行 codex
#    -PretendFresh  假装电脑上什么都没装（测试全流程用）
#    -NoPause       结束时不等回车（自动化测试用）
#  兼容 Windows PowerShell 5.1（Win10/11 自带）。本文件必须存成 UTF-8 带 BOM。
# ============================================================
param(
  [switch]$DryRun,
  [switch]$PretendFresh,
  [switch]$NoPause
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'   # 关掉 PowerShell 自带进度条，下载快很多
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

$Here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$CfgPath = Join-Path $Here 'config.json'
$Total   = 4
$Tmp     = Join-Path $env:TEMP ("lingji-codex-installer-" + [guid]::NewGuid().ToString('N').Substring(0,8))
$Problems = New-Object System.Collections.ArrayList
$LogPath = Join-Path $env:LOCALAPPDATA 'Codex中文安装器.log'

function Say($t)  { Write-Host $t }
function Ok($t)   { Write-Host "   [好了] $t" -ForegroundColor Green }
function Info($t) { Write-Host "   · $t" }
function Warn($t) { Write-Host "   [注意] $t" -ForegroundColor Yellow }
function Fail($what, $next) {
  Write-Host ""
  Write-Host "   [没成功] $what" -ForegroundColor Red
  Write-Host "   下一步：$next" -ForegroundColor Red
  Write-Host "   安装日志在：$LogPath"
  Finish 1
}
function Step($n, $title) {
  $left = $Total - $n
  Write-Host ""
  Write-Host "【第 $n 步 / 共 $Total 步】$title   （这步做完还剩 $left 步）" -ForegroundColor Cyan
}
function Plan($t) { Write-Host "   [演练·不执行] $t" -ForegroundColor DarkGray }
function Finish($code) {
  try { if (-not $DryRun) { Stop-Transcript | Out-Null } } catch {}
  if (Test-Path $Tmp) { Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue }
  if (-not $NoPause) { Write-Host ""; Read-Host "按回车键关闭这个窗口" | Out-Null }
  exit $code
}

# 演练时只探测地址（HEAD），真装时下载
function Probe-Url($url) {
  try {
    $r = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -TimeoutSec 20 -MaximumRedirection 5
    $len = 0; try { $len = [int64]$r.Headers['Content-Length'] } catch {}
    Info ("下载地址可用（HTTP {0}，约 {1} MB）：{2}" -f $r.StatusCode, [math]::Round($len/1MB), $url)
    return $true
  } catch { Warn "下载地址不通：$url"; return $false }
}
function Download($url, $dest) {
  if ($DryRun) { if (Probe-Url $url) { Plan "下载到 $dest"; return $true } else { return $false } }
  try {
    Info "正在下载：$url"
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -TimeoutSec 900
    return (Test-Path $dest)
  } catch { Warn "这个地址没下下来：$url"; return $false }
}

function Add-UserPath($dir) {
  $cur = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ($null -eq $cur) { $cur = '' }
  $parts = $cur -split ';' | Where-Object { $_ -ne '' }
  if ($parts -notcontains $dir) {
    if ($DryRun) { Plan "把 $dir 加进当前用户的 PATH（不改系统 PATH）" }
    else { [Environment]::SetEnvironmentVariable('Path', (($parts + $dir) -join ';'), 'User') }
  }
  if (($env:Path -split ';') -notcontains $dir) { $env:Path = "$dir;$env:Path" }
}

# 把「用户 PATH」补进当前窗口（上次装的东西，这个窗口也能找到）
function Sync-UserPath {
  $u = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ($u) { foreach ($d in ($u -split ';' | Where-Object { $_ -ne '' })) { if (($env:Path -split ';') -notcontains $d) { $env:Path = "$env:Path;$d" } } }
}

function Find-Codex {
  # 1) 官方安装脚本的位置  2) 我们装的 Node 目录（npm 全局命令就放在 Node 目录里）  3) MSI 版 Node 的 npm 全局目录  4) PATH
  $cands = @((Join-Path $env:LOCALAPPDATA 'Programs\OpenAI\Codex\bin\codex.exe'))
  $nodeRoot = Join-Path $env:LOCALAPPDATA 'Programs\lingji-node'
  if (Test-Path $nodeRoot) { Get-ChildItem -LiteralPath $nodeRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | ForEach-Object { $cands += (Join-Path $_.FullName 'codex.cmd') } }
  if ($env:APPDATA) { $cands += (Join-Path $env:APPDATA 'npm\codex.cmd') }
  foreach ($c in $cands) { if (Test-Path -LiteralPath $c) { return $c } }
  $c = Get-Command codex.cmd -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($c) { return $c.Source }
  $c = Get-Command codex.exe -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($c) { return $c.Source }
  return $null
}

# ---------- 开场 ----------
if (-not $DryRun) { try { Start-Transcript -Path $LogPath -Append | Out-Null } catch {} }
Clear-Host
Say "=============================================="
Say "   Codex 中文一键安装器（Windows）"
Say "   全程自动，大概 3～10 分钟，中途不用你做任何事"
Say "   不要管理员权限，不改系统，只装在你自己的用户目录"
if ($DryRun)       { Say "   >>> 当前是【演练模式】：只打印步骤，不会真的装任何东西 <<<" }
if ($PretendFresh) { Say "   >>> 测试开关：假装电脑上什么都没装 <<<" }
Say "=============================================="

if (-not (Test-Path $CfgPath)) {
  Fail "找不到配置文件 installer-files\config.json。" "把整个压缩包重新「全部解压」，再在解压出来的文件夹里双击「双击安装」。不要直接在压缩包里双击。"
}
try { $Cfg = Get-Content -Raw -Encoding UTF8 $CfgPath | ConvertFrom-Json }
catch { Fail "配置文件读不出来（可能被改坏了）。" "重新解压一份原始压缩包再试。" }
if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $Tmp | Out-Null }
$WantCcs = [bool]$Cfg.cc_switch.enabled
if ($WantCcs) { $Total = 5 }
Sync-UserPath

# ============ 第 1 步：检查电脑 ============
Step 1 "检查你的电脑"
$Arch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
switch ($Arch) {
  'AMD64' { $NodeArch = 'x64';   $CcsSuffix = 'Windows-Portable.zip';       Ok "处理器：64 位（x64）" }
  'ARM64' { $NodeArch = 'arm64'; $CcsSuffix = 'Windows-arm64-Portable.zip'; Ok "处理器：ARM64" }
  default { Fail "这台电脑是 32 位或不认识的处理器（$Arch），Codex 只有 64 位版本。" "换一台 64 位的 Windows 10/11 电脑。" }
}
$osv = [Environment]::OSVersion.Version
if ($osv.Major -lt 10) {
  Fail "系统版本太老（$osv），这个安装器只支持 Windows 10 / 11。" "先用 Windows 更新把系统升到最新，再双击安装。"
}
Ok "系统：Windows $($osv.Major).$($osv.Minor) build $($osv.Build)"
try { Invoke-WebRequest -Uri $Cfg.codex.npm_registry -Method Head -UseBasicParsing -TimeoutSec 10 | Out-Null; Ok "网络：能连上国内下载镜像" }
catch { Fail "连不上网（国内镜像 npmmirror 打不开）。" "检查网络，确认浏览器能打开网页后，再双击一次安装器。" }

# ============ 第 2 步：Node.js ============
Step 2 "准备 Node.js（Codex 的安装底座）"
$NodeMin = [int]$Cfg.node.min_major
$HaveNode = $false
if (-not $PretendFresh) {
  $n = Get-Command node -ErrorAction SilentlyContinue
  if ($n) {
    $nv = (& node -v 2>$null)
    $maj = 0; [int]::TryParse(($nv -replace '^v','').Split('.')[0], [ref]$maj) | Out-Null
    if ($maj -ge $NodeMin) { $HaveNode = $true; Ok "已经装过 Node.js $nv，跳过" }
    else { Info "电脑上的 Node.js 是 $nv，太旧了（要 $NodeMin 以上），给你单独装一个新的，不影响旧的" }
  }
}
if (-not $HaveNode) {
  $Mirror = $Cfg.node.mirror_base; $Official = $Cfg.node.official_base
  $NVer = $null
  foreach ($b in @($Mirror, $Official)) {
    try { $idx = Invoke-RestMethod -Uri "$b/index.json" -TimeoutSec 20; $NVer = ($idx | Where-Object { $_.lts } | Select-Object -First 1).version; if ($NVer) { break } } catch {}
  }
  if (-not $NVer) { $NVer = $Cfg.node.fallback_version; Info "查不到最新版本号，用内置版本 $NVer" }
  $Pkg = "node-$NVer-win-$NodeArch"
  $NodeRoot = Join-Path $env:LOCALAPPDATA 'Programs\lingji-node'
  $NodeHome = Join-Path $NodeRoot $Pkg
  Info "要装的版本：Node.js $NVer（长期支持版）"
  Info "装到：$NodeHome（你自己的目录，不要管理员）"
  $zip = Join-Path $Tmp 'node.zip'
  if ((Download "$Mirror/$NVer/$Pkg.zip" $zip) -or (Download "$Official/$NVer/$Pkg.zip" $zip)) {
    if ($DryRun) { Plan "解压到 $NodeRoot" }
    else {
      try { New-Item -ItemType Directory -Force -Path $NodeRoot | Out-Null; Expand-Archive -Path $zip -DestinationPath $NodeRoot -Force }
      catch { Fail "Node.js 解压失败（$($_.Exception.Message)）。" "可能是杀毒软件拦了。暂时关掉杀毒软件后再双击一次安装器。" }
    }
    Add-UserPath $NodeHome
    Ok "Node.js 准备好了"
  } else {
    Fail "Node.js 下载失败（国内镜像和官方地址都没下下来）。" "等 5 分钟再双击一次；还不行就打开 https://nodejs.org 下载「LTS」安装包手动装，装完再双击本安装器。"
  }
}

# ============ 第 3 步：Codex ============
Step 3 "安装 Codex 本体（OpenAI 官方）"
$CodexPath = $null
if (-not $PretendFresh) { $CodexPath = Find-Codex }
if ($CodexPath) {
  if ($DryRun) { Ok "已经装过 Codex（$CodexPath），跳过" }
  else { $ver = (& $CodexPath --version 2>$null | Select-Object -First 1); Ok "已经装过 Codex（$ver），跳过" }
} else {
  $NpmPkg = $Cfg.codex.npm_package; $NpmReg = $Cfg.codex.npm_registry
  Info "方式一：从国内 npm 镜像装官方包 $NpmPkg（文件比较大，约 100 MB，耐心等）"
  if ($DryRun) {
    if (Probe-Url "$NpmReg/$NpmPkg/latest") { Info "镜像上能查到 $NpmPkg" }
    Plan "npm.cmd install -g $NpmPkg --registry=$NpmReg --allow-scripts=@openai/codex --no-fund --no-audit"
    Info "（真装时如果方式一失败，会自动换方式二：官方脚本 irm $($Cfg.codex.official_install_ps1) | iex）"
    $CodexPath = '(演练)codex.cmd'
  } else {
    # 新版 npm 默认拦包的安装后脚本；@openai/codex 目前没有安装脚本，放行只为以后版本加了也不出事（旧版 npm 忽略此参数）
    & npm.cmd install -g $NpmPkg "--registry=$NpmReg" "--allow-scripts=@openai/codex" --no-fund --no-audit
    # npm 全局目录（MSI 装的 Node 是 %APPDATA%\npm；我们装的 Node 就是 Node 目录本身）
    try { $prefix = (& npm.cmd prefix -g 2>$null | Select-Object -First 1).Trim(); if ($prefix) { Add-UserPath $prefix } } catch {}
    $CodexPath = Find-Codex
    if ($CodexPath) { & $CodexPath --version 2>$null | Out-Null; if ($LASTEXITCODE -ne 0) { $CodexPath = $null } }
    if (-not $CodexPath) {
      Warn "国内镜像没装成功，换方式二：OpenAI 官方安装脚本（要能打开 GitHub）"
      try {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm $($Cfg.codex.official_install_ps1) | iex"
      } catch {}
      Add-UserPath (Join-Path $env:LOCALAPPDATA 'Programs\OpenAI\Codex\bin')
      $CodexPath = Find-Codex
    }
    if (-not $CodexPath) {
      Fail "Codex 没装上（国内镜像和官方脚本都失败了）。" "等 5 分钟再双击一次安装器；还不行，把安装日志发给我们。"
    }
    $ver = (& $CodexPath --version 2>$null | Select-Object -First 1)
    Ok "Codex 装好了（$ver）"
  }
}

# ============ 第 4 步（可选）：CC Switch ============
$CcsExe = $null
if ($WantCcs) {
  Step 4 "安装 CC Switch（可选：用中转 key 时一键切换）"
  $CcsDir = Join-Path $env:LOCALAPPDATA 'Programs\CC-Switch'
  if (-not $PretendFresh) {
    $cands = @(
      (Join-Path $CcsDir 'cc-switch.exe'),
      (Join-Path $env:LOCALAPPDATA 'Programs\CC Switch\cc-switch.exe'),
      (Join-Path $env:ProgramFiles 'CC Switch\cc-switch.exe')
    )
    foreach ($c in $cands) { if (Test-Path $c) { $CcsExe = $c; break } }
  }
  if ($CcsExe) {
    Ok "已经装过 CC Switch（$CcsExe），跳过"
  } else {
    $Repo = $Cfg.cc_switch.github_repo
    $Tag = $null
    try { $Tag = (Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -TimeoutSec 15).tag_name } catch {}
    if (-not $Tag) { $Tag = $Cfg.cc_switch.fallback_version; Info "查不到最新版本号，用内置版本 $Tag" }
    $Asset = "CC-Switch-$Tag-$CcsSuffix"
    Info "要装的版本：CC Switch $Tag（原作者官方免安装版）"
    $zip = Join-Path $Tmp 'ccs.zip'
    $got = $false
    $extra = $Cfg.cc_switch.extra_download_base
    if ($extra) { $got = Download ("{0}/{1}" -f $extra.TrimEnd('/'), $Asset) $zip }
    if (-not $got) { $got = Download "https://github.com/$Repo/releases/download/$Tag/$Asset" $zip }
    if ($got) {
      if ($DryRun) { Plan "解压到 $CcsDir" }
      else { try { New-Item -ItemType Directory -Force -Path $CcsDir | Out-Null; Expand-Archive -Path $zip -DestinationPath $CcsDir -Force } catch {} }
      $CcsExe = Join-Path $CcsDir 'cc-switch.exe'
      if ($DryRun -or (Test-Path $CcsExe)) { Ok "CC Switch 装好了" }
      else { $CcsExe = $null; Warn "CC Switch 解压失败，可能被杀毒软件拦了。"; [void]$Problems.Add("CC Switch 没装上（解压失败），关掉杀毒软件后重新双击安装器即可") }
    } else {
      Warn "CC Switch 下载失败（它放在 GitHub 上，国内有时候打不开）。不影响 Codex 使用。"
      [void]$Problems.Add("CC Switch 没装上（GitHub 下载失败），稍后重新双击安装器即可")
    }
  }
}

# 建快捷方式：老式 WScript.Shell 在非中文系统上存不了中文文件名 → 先用英文临时名保存，再改成中文名；真的存在才算成功
function Save-Lnk([string]$Path, [scriptblock]$Fill) {
  $tmpLnk = Join-Path (Split-Path $Path) ("happyai-tmp-" + [guid]::NewGuid().ToString('N') + ".lnk")
  try {
    $sh = New-Object -ComObject WScript.Shell
    $s = $sh.CreateShortcut($tmpLnk)
    & $Fill $s
    $s.Save()
    Move-Item -LiteralPath $tmpLnk -Destination $Path -Force
  } catch {
    if (Test-Path -LiteralPath $tmpLnk) { Remove-Item -LiteralPath $tmpLnk -Force -ErrorAction SilentlyContinue }
  }
  return (Test-Path -LiteralPath $Path)
}

# ============ 最后一步：桌面图标 ============
Step $Total "在桌面放图标"
$Desk = [Environment]::GetFolderPath('Desktop')     # 桌面被 OneDrive 接管也能找对
if (-not $Desk) { $Desk = Join-Path $env:USERPROFILE 'Desktop' }
# 保存快捷方式前确保桌面文件夹存在（不存在时 .Save() 会报「找不到文件」）
if ($DryRun) { if (-not (Test-Path $Desk)) { Plan "新建桌面文件夹 $Desk" } } else { New-Item -ItemType Directory -Force -Path $Desk | Out-Null }
$Ws = Join-Path $env:USERPROFILE $Cfg.shortcuts.workspace_dir_name
if ($DryRun) { Plan "新建工作文件夹 $Ws" } else { New-Item -ItemType Directory -Force -Path $Ws | Out-Null }
Info "工作文件夹：$Ws（Codex 默认在这里干活）"

$Lnk1 = Join-Path $Desk ($Cfg.shortcuts.codex_name + '.lnk')
$Lnk2 = Join-Path $Desk ($Cfg.shortcuts.ccswitch_name + '.lnk')
$psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

if ((Test-Path $Lnk1) -and -not $PretendFresh) { Ok "桌面已经有「$($Cfg.shortcuts.codex_name)」，跳过" }
else {
  $inner = "`$host.UI.RawUI.WindowTitle='Codex'; Write-Host '正在启动 Codex……（第一次会让你选「Sign in with ChatGPT」，会自动打开浏览器登录 ChatGPT 账号）'; Write-Host '想退出：直接关掉这个窗口。'; & '$CodexPath'"
  if ($DryRun) { Plan "桌面快捷方式 $Lnk1 → powershell 打开工作文件夹并运行 $CodexPath" }
  else {
    $ok1 = Save-Lnk $Lnk1 {
      param($s)
      $s.TargetPath = $psExe
      $s.Arguments = "-NoExit -NoLogo -ExecutionPolicy Bypass -Command `"$inner`""
      $s.WorkingDirectory = $Ws
      if ($CodexPath -like '*.exe') { $s.IconLocation = "$CodexPath,0" }
      $s.Description = 'Codex'
    }
  }
  if ($DryRun -or $ok1) { Ok "桌面图标「$($Cfg.shortcuts.codex_name)」已放好" }
  else { Warn "桌面图标「$($Cfg.shortcuts.codex_name)」没放上。"; [void]$Problems.Add("桌面图标「$($Cfg.shortcuts.codex_name)」没放上：可以在开始菜单搜 PowerShell，输入 codex 回车来用") }
}

if ($WantCcs) {
  if (-not $CcsExe) { Warn "CC Switch 没装上，先不放它的图标（重新双击安装器会补上）" }
  elseif ((Test-Path $Lnk2) -and -not $PretendFresh) { Ok "桌面已经有「$($Cfg.shortcuts.ccswitch_name)」，跳过" }
  else {
    if ($DryRun) { Plan "桌面快捷方式 $Lnk2 → $CcsExe" }
    else {
      $ok2 = Save-Lnk $Lnk2 {
        param($s)
        $s.TargetPath = $CcsExe
        $s.WorkingDirectory = Split-Path $CcsExe
        $s.IconLocation = "$CcsExe,0"
        $s.Description = 'CC Switch'
      }
    }
    if ($DryRun -or $ok2) { Ok "桌面图标「$($Cfg.shortcuts.ccswitch_name)」已放好" }
    else { Warn "桌面图标「$($Cfg.shortcuts.ccswitch_name)」没放上。"; [void]$Problems.Add("CC Switch 在 $CcsExe，双击它也能打开") }
  }
}

Info "不预填任何 key、不改你的 Codex 配置（~/.codex）。第一次打开按提示用 ChatGPT 账号登录。"

# ---------- 收尾 ----------
Say ""
Say "=============================================="
if ($DryRun) { Say "   演练结束：以上是真装时会做的全部动作，本次没有改动你的电脑。" }
else {
  Say "   装好了！"
  Say "   回到桌面，双击「$($Cfg.shortcuts.codex_name)」就能开始用。"
  Say "   第一次会让你登录 ChatGPT 账号（免费账号额度很少，常用建议 Plus / Pro）。"
  if ($CcsExe) { Say "   要换中转 key：双击「$($Cfg.shortcuts.ccswitch_name)」。" }
}
if ($Problems.Count -gt 0) { Say "   还有这些没弄完（不影响主功能）："; foreach ($p in $Problems) { Say "   - $p" } }
Say "=============================================="
Finish 0
