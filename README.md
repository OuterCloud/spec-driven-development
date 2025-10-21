# Spec-Driven Development 脚手架

一个用于自动安装和部署 [spec-kit](https://github.com/github/spec-kit) 并开始规格驱动开发的脚手架项目。

## 项目简介

本项目提供了一个完整的自动化脚本，用于在 macOS 系统上快速配置 spec-kit 开发环境。spec-kit 是 GitHub 开发的一个强大的规格驱动开发工具，它使用 AI 助手来生成规格说明、编写代码和管理项目。

## 特性

- 🚀 **一键安装**: 自动检测并安装所有必需的依赖
- 🔍 **智能检测**: 检查系统现有环境，避免重复安装
- 🎨 **友好界面**: 彩色输出和清晰的进度提示
- ⚡ **最新工具**: 使用 uv 包管理器进行快速安装
- 🔐 **可选增强**: 支持 GitHub CLI 和 Copilot CLI 集成
- 📁 **项目管理**: 内置项目创建脚本和推荐的目录结构
- 🛡️ **隔离设计**: 脚手架工具与生成项目完全分离

## 系统要求

- **操作系统**: macOS
- **Python**: ≥ 3.11
- **Git**: 已安装（通常包含在 Xcode Command Line Tools 中）

## 快速开始

### 1. 克隆或下载此项目

```bash
# 克隆项目
git clone https://github.com/your-username/spec-driven-development.git
cd spec-driven-development

# 或直接下载脚本
curl -O https://raw.githubusercontent.com/your-username/spec-driven-development/main/setup-spec-kit.sh
```

### 2. 运行安装脚本

```bash
# 给脚本添加执行权限
chmod +x setup-spec-kit.sh

# 运行安装脚本
./setup-spec-kit.sh
```

### 3. 开始使用 spec-kit

安装完成后，建议创建专门的项目目录来管理您的 spec-kit 项目：

```bash
# 创建项目工作空间（推荐做法）
mkdir -p ~/spec-projects
cd ~/spec-projects

# 创建新的规格驱动项目
specify init my-awesome-project --ai copilot

# 进入项目目录
cd my-awesome-project

# 开始开发
specify generate spec --description "创建一个用户认证系统"
```

## 推荐的目录结构

为了更好地组织您的开发工作，建议采用以下目录结构：

```
~/spec-projects/                    # 主工作目录
├── my-awesome-project/             # 项目1
│   ├── specs/                      # 规格文件
│   ├── src/                        # 源代码
│   └── tests/                      # 测试文件
├── another-project/                # 项目2
├── experimental-features/          # 实验性项目
└── templates/                      # 项目模板
```

您也可以使用脚手架目录下的便捷脚本：

```bash
# 回到脚手架目录，使用便捷命令
cd /path/to/spec-driven-development
./create-project.sh my-new-project  # 这将创建项目到 ./projects/ 目录
```

## 安装的组件

脚本会自动安装和配置以下组件：

### 必需组件

- **Git**: 版本控制系统
- **Python ≥ 3.11**: spec-kit 的运行环境
- **uv**: 现代化的 Python 包管理器
- **specify-cli**: spec-kit 的命令行工具

### 可选组件

- **Homebrew**: macOS 包管理器（如果未安装）
- **GitHub CLI (gh)**: GitHub 命令行工具，用于身份验证
- **Copilot CLI**: GitHub Copilot 命令行工具，增强 AI 功能

## 使用指南

### 基本命令

```bash
# 查看帮助
specify --help

# 初始化新项目
specify init <project-name> --ai copilot

# 生成规格说明
specify generate spec --description "<需求描述>"

# 从规格生成代码
specify generate code --spec <spec-file>

# 运行测试
specify test

# 查看项目状态
specify status
```

### 配置 AI 助手

如果您选择安装了 Copilot CLI，需要先进行身份验证：

```bash
# GitHub CLI 登录
gh auth login

# Copilot CLI 初始化
copilot-cli
```

## 故障排除

### Python 版本问题

如果遇到 Python 版本过低的问题：

```bash
# 使用 pyenv 安装新版本 Python
brew install pyenv
pyenv install 3.12
pyenv global 3.12
```

### uv 安装问题

如果 uv 安装失败：

```bash
# 手动安装 uv
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc  # 或 source ~/.zshrc
```

### specify 命令未找到

如果安装后找不到 specify 命令：

```bash
# 检查 uv 工具路径
uv tool list

# 手动添加到 PATH
export PATH="$HOME/.local/bin:$PATH"
```

## 开发流程建议

1. **规格先行**: 使用 `specify generate spec` 先定义需求
2. **代码生成**: 基于规格使用 AI 生成初始代码
3. **迭代改进**: 通过规格和代码的对比不断改进
4. **测试验证**: 使用生成的测试确保代码质量

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个脚手架项目。

### 开发设置

```bash
# Fork 并克隆项目
git clone https://github.com/your-username/spec-driven-development.git
cd spec-driven-development

# 测试脚本
./setup-spec-kit.sh

# 提交改进
git add .
git commit -m "改进: 描述您的更改"
git push origin main
```

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 相关链接

- [spec-kit GitHub 仓库](https://github.com/github/spec-kit)
- [uv 文档](https://docs.astral.sh/uv/)
- [GitHub CLI 文档](https://cli.github.com/)
- [GitHub Copilot](https://github.com/features/copilot)

## 更新日志

### v1.0.0

- 初始版本
- 支持 macOS 自动安装
- 集成 uv 包管理器
- 可选 GitHub CLI 和 Copilot CLI 支持

---

> 💡 **提示**: 如果您是第一次使用规格驱动开发，建议先阅读 [spec-kit 官方文档](https://github.com/github/spec-kit) 了解核心概念。
