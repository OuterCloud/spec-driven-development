# setup-spec-kit.ps1
# 自动检测并安装 spec-kit (Specify CLI) 所需的 Windows 环境
# 作者: Qwen
# 用法: .\setup-spec-kit.ps1

param(
    [switch]$Force,
    [switch]$SkipOptional
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 颜色定义
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    White = "White"
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

# 检查是否在 Windows
if ($env:OS -ne "Windows_NT") {
    Write-Error "此脚本仅支持 Windows。当前系统: $($env:OS)"
}

Write-Log "开始检查 spec-kit 环境依赖..."

# 1. 检查 Git
function Test-Git {
    try {
        $gitVersion = git --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Git 已安装: $gitVersion"
            return $true
        }
    } catch {
        # Git 未找到
    }

    Write-Warn "Git 未安装"
    $installGit = Read-Host "是否安装 Git？(Y/n)"
    if ($installGit -notin @("", "y", "Y", "yes", "Yes")) {
        Write-Error "请手动安装 Git 后重试。推荐从 https://git-scm.com 下载"
    }

    # 尝试通过 winget 安装 Git
    Write-Log "正在通过 winget 安装 Git..."
    try {
        winget install --id Git.Git --source winget --accept-package-agreements --accept-source-agreements
        Write-Success "Git 安装成功"
        return $true
    } catch {
        Write-Error "Git 安装失败。请手动从 https://git-scm.com 下载安装"
    }
}

Test-Git

# 2. 检查 Python ≥ 3.11
function Install-PythonViaPyenv {
    param([string]$PythonVersion = "3.12.7")

    # 检查并安装 pyenv-win
    $pyenvPath = "$env:USERPROFILE\.pyenv\pyenv-win\bin\pyenv.bat"
    if (!(Test-Path $pyenvPath)) {
        Write-Log "pyenv-win 未安装，正在安装..."

        # 下载并安装 pyenv-win
        $pyenvInstallPath = "$env:USERPROFILE\.pyenv"
        if (!(Test-Path $pyenvInstallPath)) {
            New-Item -ItemType Directory -Path $pyenvInstallPath -Force | Out-Null
        }

        try {
            # 使用 PowerShell 下载 pyenv-win
            $pyenvUrl = "https://github.com/pyenv-win/pyenv-win/archive/master.zip"
            $tempZip = "$env:TEMP\pyenv-win.zip"
            Invoke-WebRequest -Uri $pyenvUrl -OutFile $tempZip

            # 解压到临时目录
            $tempExtract = "$env:TEMP\pyenv-win-extract"
            if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
            New-Item -ItemType Directory -Path $tempExtract -Force | Out-Null

            Expand-Archive -Path $tempZip -DestinationPath $tempExtract

            # 移动文件到正确位置
            $extractedDir = Get-ChildItem $tempExtract | Where-Object { $_.PSIsContainer } | Select-Object -First 1
            Copy-Item "$($extractedDir.FullName)\*" $pyenvInstallPath -Recurse -Force

            # 清理临时文件
            Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
            Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue

            Write-Success "pyenv-win 已下载"
        } catch {
            Write-Error "pyenv-win 下载失败: $($_.Exception.Message)"
        }
    } else {
        Write-Success "pyenv-win 已安装"
    }

    # 配置环境变量
    $pyenvBinPath = "$env:USERPROFILE\.pyenv\pyenv-win\bin"
    $pyenvShimsPath = "$env:USERPROFILE\.pyenv\pyenv-win\shims"

    # 添加到 PATH（当前会话）
    $env:PATH = "$pyenvBinPath;$pyenvShimsPath;$env:PATH"

    # 检查是否已安装所需的 Python 版本
    try {
        $installedVersions = & $pyenvPath versions 2>$null
        if ($installedVersions -match $PythonVersion) {
            Write-Log "Python $PythonVersion 已通过 pyenv-win 安装"
            & $pyenvPath global $PythonVersion
            Write-Success "已切换到 Python $PythonVersion"
        } else {
            Write-Log "正在通过 pyenv-win 安装 Python $PythonVersion..."
            Write-Log "这可能需要几分钟时间..."

            # 安装 Python
            $installResult = & $pyenvPath install $PythonVersion 2>&1
            if ($LASTEXITCODE -eq 0) {
                & $pyenvPath global $PythonVersion
                Write-Success "Python $PythonVersion 已通过 pyenv-win 安装并设为全局版本"

                # 刷新 PATH
                $env:PATH = "$pyenvShimsPath;$env:PATH"
            } else {
                Write-Error "Python $PythonVersion 通过 pyenv-win 安装失败: $installResult"
            }
        }
    } catch {
        Write-Error "pyenv-win 操作失败: $($_.Exception.Message)"
    }

    # 验证安装
    try {
        $pythonVersion = & python --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "当前 Python 版本: $pythonVersion"
            Write-Log "Python 路径: $(Get-Command python).Source"
        }
    } catch {
        Write-Warn "Python 验证失败，可能需要重启终端"
    }
}

function Install-PythonViaWinget {
    Write-Log "通过 winget 安装 Python 3.12..."
    try {
        winget install --id Python.Python.3.12 --source winget --accept-package-agreements --accept-source-agreements
        Write-Success "Python 3.12 已通过 winget 安装"

        # 刷新 PATH
        $pythonPath = "$env:LOCALAPPDATA\Programs\Python\Python312"
        $env:PATH = "$pythonPath;$pythonPath\Scripts;$env:PATH"

        # 验证安装
        $pythonVersion = & python --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "当前 Python 版本: $pythonVersion"
            Write-Log "Python 路径: $(Get-Command python).Source"
        }
    } catch {
        Write-Error "Python 安装失败: $($_.Exception.Message)"
    }
}

# 检查 Python 版本
$pythonVersion = $null
try {
    $pythonOutput = & python --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $pythonVersion = [version]($pythonOutput -replace "Python ", "")
    }
} catch {
    # Python 未找到
}

$minVersion = [version]"3.11.0"

if ($null -eq $pythonVersion -or $pythonVersion -lt $minVersion) {
    if ($null -eq $pythonVersion) {
        Write-Warn "Python 未安装，需要 ≥ 3.11"
    } else {
        Write-Warn "Python 版本过低（当前: $pythonVersion），需要 ≥ 3.11"
    }

    Write-Host ""
    Write-Host "请选择 Python 安装方式："
    Write-Host "1) pyenv-win（推荐）- 可管理多个 Python 版本"
    Write-Host "2) winget - 简单快速安装"
    Write-Host "3) 跳过安装"
    Write-Host ""

    $pythonChoice = Read-Host "请输入选择 (1/2/3)"
    if (!$pythonChoice) { $pythonChoice = "1" }

    switch ($pythonChoice) {
        "1" {
            Write-Log "选择通过 pyenv-win 安装 Python..."
            Install-PythonViaPyenv
        }
        "2" {
            Write-Log "选择通过 winget 安装 Python..."
            Install-PythonViaWinget
        }
        "3" {
            Write-Warn "跳过 Python 安装"
            Write-Error "请手动安装 Python ≥ 3.11 后重试"
        }
        default {
            Write-Warn "无效选择，默认使用 pyenv-win 安装..."
            Install-PythonViaPyenv
        }
    }

    # 重新检查 Python 版本
    try {
        $pythonOutput = & python --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            $pythonVersion = [version]($pythonOutput -replace "Python ", "")
        }
    } catch {
        $pythonVersion = $null
    }

    if ($null -eq $pythonVersion -or $pythonVersion -lt $minVersion) {
        Write-Error "Python 安装后版本仍不满足要求（当前: $pythonVersion）"
    } else {
        Write-Success "Python 版本现在满足要求: $pythonVersion"
    }
} else {
    Write-Success "Python 版本满足要求: $pythonVersion"
}

# 3. 检查并安装 uv
function Test-Uv {
    try {
        $uvVersion = & uv --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "uv 已安装: $uvVersion"
            return $true
        }
    } catch {
        # uv 未找到
    }

    Write-Log "uv 未安装，正在安装..."
    try {
        # 下载并运行 uv 安装脚本
        $installScript = Invoke-WebRequest -Uri "https://astral.sh/uv/install.ps1" -UseBasicParsing
        $installScript.Content | Invoke-Expression

        # 刷新 PATH
        $cargoBinPath = "$env:USERPROFILE\.cargo\bin"
        $env:PATH = "$cargoBinPath;$env:PATH"

        Write-Success "uv 已安装"
        return $true
    } catch {
        Write-Error "uv 安装失败: $($_.Exception.Message)"
    }
}

Test-Uv

# 4. （可选）检查 GitHub CLI
if (!$SkipOptional) {
    $installGh = Read-Host "是否安装 GitHub CLI (gh)？推荐用于简化身份验证 (y/N)"
    if ($installGh -in @("y", "Y", "yes", "Yes")) {
        Write-Log "正在通过 winget 安装 GitHub CLI..."
        try {
            winget install --id GitHub.cli --source winget --accept-package-agreements --accept-source-agreements
            Write-Success "GitHub CLI 已安装"
            Write-Log "首次使用请运行: gh auth login"
        } catch {
            Write-Warn "GitHub CLI 安装失败: $($_.Exception.Message)"
        }
    }
}

# 5. 检查并配置 VS Code 命令行工具
function Test-VSCode {
    try {
        $codeVersion = & code --version 2>$null | Select-Object -First 1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "VS Code 命令行工具已配置: $codeVersion"
            return $true
        }
    } catch {
        # code 命令未找到
    }

    # 检查 VS Code 是否已安装
    $vscodePaths = @(
        "${env:ProgramFiles}\Microsoft VS Code\bin\code.cmd",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd",
        "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\bin\code.cmd"
    )

    $vscodeInstalled = $false
    $vscodePath = $null

    foreach ($path in $vscodePaths) {
        if (Test-Path $path) {
            $vscodeInstalled = $true
            $vscodePath = $path
            break
        }
    }

    if ($vscodeInstalled) {
        Write-Log "VS Code 已安装，但命令行工具未配置"
        $configureCode = Read-Host "是否自动配置 VS Code 命令行工具 'code' 命令？(Y/n)"
        if ($configureCode -notin @("", "n", "N", "no", "No")) {
            Write-Log "正在配置 VS Code 命令行工具..."

            # 将 VS Code bin 目录添加到 PATH（当前会话）
            $vscodeBinDir = Split-Path $vscodePath -Parent
            $env:PATH = "$vscodeBinDir;$env:PATH"

            # 验证配置
            try {
                $codeVersion = & code --version 2>$null | Select-Object -First 1
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "VS Code 命令行工具配置成功: $codeVersion"
                    return $true
                }
            } catch {
                Write-Warn "VS Code 命令行工具配置失败"
            }
        } else {
            Write-Warn "跳过 VS Code 命令行工具配置"
            Write-Log "您可以稍后在 VS Code 中按 Ctrl+Shift+P，搜索 'Shell Command: Install code command in PATH' 手动配置"
        }
    } else {
        Write-Warn "VS Code 未安装。建议安装 VS Code 以获得最佳开发体验。"
        $installVSCode = Read-Host "是否通过 winget 安装 VS Code？(y/N)"
        if ($installVSCode -in @("y", "Y", "yes", "Yes")) {
            Write-Log "正在安装 VS Code..."
            try {
                winget install --id Microsoft.VisualStudioCode --source winget --accept-package-agreements --accept-source-agreements
                Write-Success "VS Code 已安装"

                # 安装后自动配置命令行工具
                $vscodeBinDir = "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\bin"
                if (Test-Path $vscodeBinDir) {
                    $env:PATH = "$vscodeBinDir;$env:PATH"

                    try {
                        $codeVersion = & code --version 2>$null | Select-Object -First 1
                        if ($LASTEXITCODE -eq 0) {
                            Write-Success "VS Code 命令行工具配置成功: $codeVersion"
                            return $true
                        }
                    } catch {
                        Write-Warn "VS Code 命令行工具配置失败，请手动配置"
                    }
                }
            } catch {
                Write-Warn "VS Code 安装失败: $($_.Exception.Message)"
            }
        }
    }

    return $false
}

Test-VSCode

# 6. （可选）安装 Copilot CLI
if (!$SkipOptional) {
    $installCopilot = Read-Host "是否安装 GitHub Copilot CLI（推荐用于 spec-kit）？(y/N)"
    if ($installCopilot -in @("y", "Y", "yes", "Yes")) {
        # 检查 Node.js
        $nodeInstalled = $false
        try {
            $nodeVersion = & node --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                $nodeVersionNumber = [version]($nodeVersion -replace "v", "")
                if ($nodeVersionNumber.Major -ge 22) {
                    Write-Success "Node.js 版本满足要求: $nodeVersion"
                    $nodeInstalled = $true
                } else {
                    Write-Warn "Node.js 版本过低（当前: $nodeVersion），GitHub Copilot CLI 需要 ≥ 22"
                }
            }
        } catch {
            Write-Warn "Node.js 未安装。GitHub Copilot CLI 需要 Node.js ≥ 22。"
        }

        if (!$nodeInstalled) {
            $installNode = Read-Host "是否通过 winget 安装最新版 Node.js？(Y/n)"
            if ($installNode -notin @("", "n", "N", "no", "No")) {
                Write-Log "正在安装 Node.js..."
                try {
                    winget install --id OpenJS.NodeJS --source winget --accept-package-agreements --accept-source-agreements
                    Write-Success "Node.js 已安装"

                    # 刷新 PATH
                    $nodePath = "${env:ProgramFiles}\nodejs"
                    $env:PATH = "$nodePath;$env:PATH"

                    $nodeInstalled = $true
                } catch {
                    Write-Warn "Node.js 安装失败: $($_.Exception.Message)"
                }
            }
        }

        # 安装 GitHub Copilot CLI
        if ($nodeInstalled) {
            try {
                $nodeVersionCheck = & node --version 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $nodeVersionNumber = [version]($nodeVersionCheck -replace "v", "")
                    if ($nodeVersionNumber.Major -ge 22) {
                        Write-Log "正在安装 GitHub Copilot CLI..."
                        Write-Log "这可能需要几分钟时间..."

                        & npm install -g @github/copilot 2>$null
                        if ($LASTEXITCODE -eq 0) {
                            Write-Success "GitHub Copilot CLI 已安装"
                            Write-Log "首次使用请运行: github-copilot-cli auth login"
                            Write-Log "或在 VS Code 中使用 GitHub Copilot Chat"
                        } else {
                            Write-Warn "GitHub Copilot CLI 安装失败"
                            Write-Log "您仍可以在 VS Code 中使用 GitHub Copilot Chat"
                        }
                    } else {
                        Write-Warn "Node.js 版本仍然不足，跳过 Copilot CLI 安装"
                    }
                }
            } catch {
                Write-Warn "GitHub Copilot CLI 安装失败: $($_.Exception.Message)"
            }
        }
    }
}

# 7. 安装 specify-cli via uv
Write-Log "正在通过 uv 安装 specify-cli（来自 GitHub spec-kit）..."

try {
    & uv tool install specify-cli --from git+https://github.com/github/spec-kit.git --python 3.11+ 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "specify CLI 安装成功！"
        Write-Host ""
        Write-Host "✅ 环境准备完成！现在可以运行：" -ForegroundColor $Colors.Green
        Write-Host "  specify init my-project --ai copilot"
        Write-Host "  specify check  # 检查工具安装状态"
    } else {
        Write-Error "specify CLI 安装失败，请手动检查"
    }
} catch {
    Write-Error "specify CLI 安装失败: $($_.Exception.Message)"
}