#!/bin/bash

# setup-spec-kit.sh
# 自动检测并安装 spec-kit (Specify CLI) 所需的 macOS 环境
# 作者: Qwen
# 用法: chmod +x setup-spec-kit.sh && ./setup-spec-kit.sh

set -e  # 遇错退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# 检查是否在 macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "此脚本仅支持 macOS。当前系统: $OSTYPE"
fi

log "开始检查 spec-kit 环境依赖..."

# 1. 检查 Git
if ! command -v git &> /dev/null; then
    error "Git 未安装。请先安装 Xcode Command Line Tools: xcode-select --install"
else
    success "Git 已安装: $(git --version)"
fi

# 2. 检查 Python ≥ 3.11
PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "0.0")
IFS='.' read -ra VER <<< "$PYTHON_VERSION"
if [[ ${VER[0]} -lt 3 ]] || ([[ ${VER[0]} -eq 3 ]] && [[ ${VER[1]} -lt 11 ]]); then
    warn "Python 版本过低（当前: $PYTHON_VERSION），需要 ≥ 3.11"
    log "推荐使用 pyenv 安装新版 Python"
    read -p "是否尝试用 Homebrew 安装 Python 3.12？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ! command -v brew &> /dev/null; then
            log "正在安装 Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install python@3.12
        success "Python 3.12 已通过 Homebrew 安装"
    else
        error "请手动安装 Python ≥ 3.11 后重试"
    fi
else
    success "Python 版本满足要求: $PYTHON_VERSION"
fi

# 3. 检查并安装 uv
if ! command -v uv &> /dev/null; then
    log "uv 未安装，正在安装..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # 将 uv 加入 PATH（当前 shell）
    export PATH="$HOME/.cargo/bin:$PATH"
    success "uv 已安装"
else
    success "uv 已安装: $(uv --version)"
fi

# 4. （可选）检查 GitHub CLI
if ! command -v gh &> /dev/null; then
    warn "GitHub CLI (gh) 未安装。建议安装以简化身份验证。"
    read -p "是否用 Homebrew 安装 gh？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install gh
        log "请运行 'gh auth login' 完成登录"
    fi
else
    success "GitHub CLI 已安装: $(gh --version)"
fi

# 5. （可选）安装 Copilot CLI
read -p "是否安装 GitHub Copilot CLI（推荐用于 spec-kit）？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if ! command -v npm &> /dev/null; then
        error "npm 未安装。请先安装 Node.js（建议通过 Homebrew: brew install node）"
    fi
    if ! command -v copilot &> /dev/null; then
        log "正在安装 @copilot-cli/copilot..."
        npm install -g @copilot-cli/copilot
        success "Copilot CLI 已安装"
        log "首次使用请运行: copilot-cli"
    else
        success "Copilot CLI 已安装"
    fi
fi

# 6. 安装 specify-cli via uv
log "正在通过 uv 安装 specify-cli（来自 GitHub spec-kit）..."
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git --python 3.11+

if command -v specify &> /dev/null; then
    success "specify CLI 安装成功！版本: $(specify --version)"
    echo
    echo -e "${GREEN}✅ 环境准备完成！现在可以运行：${NC}"
    echo "  specify init my-project --ai copilot"
else
    error "specify CLI 安装失败，请手动检查"
fi