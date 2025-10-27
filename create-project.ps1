# create-project.ps1
# 便捷的 spec-kit 项目创建脚本
# 用法: .\create-project.ps1 <project-name> [project-path] [--ai copilot]

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ProjectName,

    [Parameter(Position = 1)]
    [string]$ProjectPath,

    [string]$AI = ""
)

# 颜色定义
$Colors = @{
    Green = "Green"
    Blue = "Blue"
    Yellow = "Yellow"
    Red = "Red"
}

function Write-Log {
    param([string]$Message)
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] [INFO] $Message" -ForegroundColor $Colors.Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] [OK] $Message" -ForegroundColor $Colors.Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] [WARN] $Message" -ForegroundColor $Colors.Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] [ERROR] $Message" -ForegroundColor $Colors.Red
    exit 1
}

# 检查参数
if ($AI -and $AI -notin @("copilot", "claude", "gpt")) {
    Write-Host "用法: .\create-project.ps1 <project-name> [project-path] [-AI <copilot|claude|gpt>]"
    Write-Host "示例: .\create-project.ps1 my-awesome-project C:\workspace -AI copilot"
    Write-Host "      .\create-project.ps1 my-project D:\projects"
    Write-Host "      .\create-project.ps1 my-project -AI gpt"
    Write-Host "如果不指定路径，默认创建到桌面"
    exit 1
}

# 如果没有指定路径，询问用户
if (!$ProjectPath) {
    $defaultPath = "$env:USERPROFILE\Desktop"
    $userInput = Read-Host "请输入项目创建路径 (默认: $defaultPath)"
    if (!$userInput) {
        $ProjectPath = $defaultPath
    } else {
        $ProjectPath = $userInput
    }
}

# 展开环境变量和相对路径为绝对路径
$ProjectPath = [Environment]::ExpandEnvironmentVariables($ProjectPath)
if (![System.IO.Path]::IsPathRooted($ProjectPath)) {
    $ProjectPath = Resolve-Path $ProjectPath -ErrorAction SilentlyContinue
    if (!$ProjectPath) {
        $ProjectPath = Join-Path (Get-Location) $ProjectPath
    }
}

# 检查 specify 命令是否可用
try {
    $null = Get-Command specify -ErrorAction Stop
} catch {
    Write-Error "错误: specify 命令未找到。请先运行 .\setup-spec-kit.ps1 安装环境。"
}

# 检查目标路径是否存在
if (!(Test-Path $ProjectPath)) {
    Write-Warn "目录 $ProjectPath 不存在"
    $createDir = Read-Host "是否创建该目录？(y/N)"
    if ($createDir -in @("y", "Y", "yes", "Yes")) {
        New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
        Write-Success "已创建目录: $ProjectPath"
    } else {
        Write-Host "操作已取消"
        exit 1
    }
}

# 计算完整的项目路径
$FullProjectPath = Join-Path $ProjectPath $ProjectName

# 检查项目是否已存在
if (Test-Path $FullProjectPath) {
    Write-Warn "项目 $FullProjectPath 已存在，请选择其他名称或路径。"
    exit 1
}

Write-Log "正在 $ProjectPath 中创建项目: $ProjectName"

# 进入目标目录
Push-Location $ProjectPath

try {
    # 创建 spec-kit 项目
    if ($AI) {
        Write-Log "使用 AI 助手创建项目: specify init $ProjectName --ai $AI"
        $result = & specify init $ProjectName --ai $AI 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "项目创建失败: $result"
        }
    } else {
        Write-Log "创建项目: specify init $ProjectName"
        $result = & specify init $ProjectName 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "项目创建失败: $result"
        }
    }

    # 进入项目目录
    Push-Location $ProjectName

    Write-Success "项目 $ProjectName 创建成功！"
    Write-Host ""
    Write-Host "项目位置: $FullProjectPath" -ForegroundColor $Colors.White
    Write-Host ""

    # 询问用户是否要用 VS Code 打开项目
    $openVSCode = Read-Host "是否要用 VS Code 打开项目？(y/N)"
    if ($openVSCode -in @("y", "Y", "yes", "Yes")) {
        try {
            $null = Get-Command code -ErrorAction Stop
            Write-Log "正在用 VS Code 打开项目..."
            & code $FullProjectPath
            Write-Success "项目已在 VS Code 中打开！"
            Write-Host ""
            Write-Host "在 VS Code 中，您可以："
            Write-Host "  • 使用 GitHub Copilot Chat 的 /speckit 命令进行规范驱动开发"
            Write-Host "  • 在终端中运行: specify check  # 检查工具安装状态"
        } catch {
            Write-Warn "VS Code 命令行工具 'code' 未找到"
            Write-Host "请手动打开 VS Code 并打开项目目录: $FullProjectPath"
        }
    } else {
        Write-Host "接下来您可以："
        Write-Host "  cd '$FullProjectPath'"
        Write-Host "  code .  # 用 VS Code 打开项目"
        Write-Host "  在 VS Code 中使用 GitHub Copilot Chat 的 /speckit 命令"
        Write-Host "  或者使用: specify check  # 检查工具状态"
    }

    Write-Host ""
    Write-Log "开始您的规范驱动开发之旅！"

} finally {
    # 恢复原始位置
    Pop-Location
    Pop-Location
}