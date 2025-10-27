# Windows PowerShell 版本的 spec-kit 脚本

本目录包含了适用于 Windows 系统的 PowerShell 版本脚本，对应于 macOS 的 Bash 脚本。

## 文件说明

### setup-spec-kit.ps1

自动检测并安装 spec-kit (Specify CLI) 所需的 Windows 环境。

**功能特性：**

- 检查并安装 Git
- 安装 Python ≥ 3.11（支持 pyenv-win 和 winget）
- 安装 uv 包管理器
- 可选安装 GitHub CLI
- 配置 VS Code 命令行工具
- 可选安装 GitHub Copilot CLI
- 安装 specify-cli 工具

**使用方法：**

```powershell
# 基本安装
.\setup-spec-kit.ps1

# 跳过可选组件安装
.\setup-spec-kit.ps1 -SkipOptional

# 强制重新安装
.\setup-spec-kit.ps1 -Force
```

### create-project.ps1

便捷的 spec-kit 项目创建脚本。

**功能特性：**

- 创建 spec-kit 项目
- 支持指定项目名称和路径
- 支持不同的 AI 助手（copilot、claude、gpt）
- 自动验证环境依赖
- 可选择用 VS Code 打开项目

**使用方法：**

```powershell
# 基本用法
.\create-project.ps1 my-project

# 指定路径
.\create-project.ps1 my-project "C:\workspace"

# 使用指定 AI 助手
.\create-project.ps1 my-project -AI copilot
.\create-project.ps1 my-project "D:\projects" -AI gpt
```

## 系统要求

- Windows 10 或更高版本
- PowerShell 5.1 或更高版本
- 管理员权限（某些安装步骤可能需要）

## 主要差异（与 macOS 版本相比）

### 包管理器

- **macOS**: Homebrew
- **Windows**: winget (优先)、pyenv-win

### Python 版本管理

- **macOS**: pyenv + Homebrew
- **Windows**: pyenv-win (推荐) 或 winget

### VS Code 配置

- **macOS**: 软链接到 /usr/local/bin
- **Windows**: 添加到 PATH 环境变量

### 路径处理

- **macOS**: Unix 风格路径
- **Windows**: Windows 风格路径，支持环境变量展开

## 故障排除

### 权限问题

如果遇到权限错误，请尝试：

1. 以管理员身份运行 PowerShell
2. 或在用户目录下运行脚本

### 网络问题

如果 winget 下载失败：

1. 检查网络连接
2. 考虑使用代理
3. 手动下载相关软件

### Python 安装问题

如果 pyenv-win 安装失败：

1. 尝试使用 winget 安装 Python
2. 或手动从 python.org 下载安装

### VS Code 配置问题

如果 code 命令无法识别：

1. 重新安装 VS Code
2. 在 VS Code 中手动安装 shell 命令：`Ctrl+Shift+P` → "Shell Command: Install code command in PATH"

## 脚本执行策略

Windows 默认可能阻止 PowerShell 脚本执行。如需运行，请设置执行策略：

```powershell
# 查看当前执行策略
Get-ExecutionPolicy

# 设置执行策略（选择其中之一）
Set-ExecutionPolicy RemoteSigned  # 允许本地脚本
Set-ExecutionPolicy Unrestricted  # 允许所有脚本（不推荐）
```

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这些脚本。

## 许可证

与原 macOS 脚本保持一致。
