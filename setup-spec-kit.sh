#!/bin/bash

# setup-spec-kit.sh
# 自动检测并安装 spec-kit (Specify CLI) 所需的 macOS 环境
# 作者: Qwen
# 用法: chmod +x setup-spec-kit.sh && ./setup-spec-kit.sh

set -e  # 遇错退出

# 确保正确的编码环境
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

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

install_python_via_pyenv() {
    local python_version="3.12.7"  # 推荐的稳定版本
    
    # 检查并安装 pyenv
    if ! command -v pyenv &> /dev/null; then
        log "pyenv 未安装，正在安装..."
        if ! command -v brew &> /dev/null; then
            log "正在安装 Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        log "通过 Homebrew 安装 pyenv..."
        brew install pyenv
        
        # 配置 shell 环境
        log "配置 pyenv 环境变量..."
        SHELL_RC=""
        if [[ "$SHELL" == *"zsh"* ]] || [[ -n "$ZSH_VERSION" ]]; then
            SHELL_RC="$HOME/.zshrc"
        elif [[ "$SHELL" == *"bash"* ]]; then
            SHELL_RC="$HOME/.bash_profile"
        fi
        
        if [[ -n "$SHELL_RC" ]]; then
            # 检查是否已经配置过 pyenv
            if ! grep -q 'pyenv init' "$SHELL_RC" 2>/dev/null; then
                log "配置 $SHELL_RC..."
                echo '' >> "$SHELL_RC"
                echo '# pyenv configuration' >> "$SHELL_RC"
                echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> "$SHELL_RC"
                echo 'eval "$(pyenv init --path)"' >> "$SHELL_RC"
                echo 'eval "$(pyenv init -)"' >> "$SHELL_RC"
            fi
            
            # 加载 pyenv 到当前 shell
            export PATH="$HOME/.pyenv/bin:$PATH"
            if command -v pyenv &> /dev/null; then
                eval "$(pyenv init --path)"
                eval "$(pyenv init -)"
            fi
        fi
        
        success "pyenv 已安装"
    else
        success "pyenv 已安装: $(pyenv --version)"
        # 确保当前 shell 中 pyenv 可用
        export PATH="$HOME/.pyenv/bin:$PATH"
        eval "$(pyenv init --path)" 2>/dev/null || true
        eval "$(pyenv init -)" 2>/dev/null || true
    fi
    
    # 检查是否已安装所需的 Python 版本
    if pyenv versions | grep -q "$python_version"; then
        log "Python $python_version 已通过 pyenv 安装"
        pyenv global "$python_version"
        success "已切换到 Python $python_version"
    else
        log "正在通过 pyenv 安装 Python $python_version..."
        log "这可能需要几分钟时间..."
        
        # 安装编译依赖
        if ! command -v brew &> /dev/null; then
            log "正在安装 Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        log "安装 Python 编译依赖..."
        brew install openssl readline sqlite3 xz zlib tcl-tk
        
        # 设置编译环境变量
        export LDFLAGS="-L$(brew --prefix openssl)/lib -L$(brew --prefix readline)/lib -L$(brew --prefix sqlite)/lib -L$(brew --prefix xz)/lib -L$(brew --prefix zlib)/lib"
        export CPPFLAGS="-I$(brew --prefix openssl)/include -I$(brew --prefix readline)/include -I$(brew --prefix sqlite)/include -I$(brew --prefix xz)/include -I$(brew --prefix zlib)/include"
        export PKG_CONFIG_PATH="$(brew --prefix openssl)/lib/pkgconfig:$(brew --prefix readline)/lib/pkgconfig:$(brew --prefix sqlite)/lib/pkgconfig:$(brew --prefix xz)/lib/pkgconfig:$(brew --prefix zlib)/lib/pkgconfig"
        
        # 安装 Python
        if pyenv install "$python_version"; then
            pyenv global "$python_version"
            success "Python $python_version 已通过 pyenv 安装并设为全局版本"
            
            # 刷新当前 shell 的 Python 环境
            export PATH="$(pyenv root)/shims:$PATH"
            hash -r
        else
            error "Python $python_version 通过 pyenv 安装失败"
        fi
    fi
    
    # 验证安装
    if command -v python3 &> /dev/null; then
        NEW_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")' 2>/dev/null || echo "未知")
        success "当前 Python 版本: $NEW_VERSION"
        log "Python 路径: $(which python3)"
    fi
}

install_python_via_homebrew() {
    if ! command -v brew &> /dev/null; then
        log "正在安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    log "通过 Homebrew 安装 Python 3.12..."
    brew install python@3.12
    
    # 确保新安装的 Python 在 PATH 中
    export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
    hash -r
    
    success "Python 3.12 已通过 Homebrew 安装"
    
    # 验证安装
    if command -v python3 &> /dev/null; then
        NEW_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")' 2>/dev/null || echo "未知")
        success "当前 Python 版本: $NEW_VERSION"
        log "Python 路径: $(which python3)"
    fi
}

if [[ ${VER[0]} -lt 3 ]] || ([[ ${VER[0]} -eq 3 ]] && [[ ${VER[1]} -lt 11 ]]); then
    warn "Python 版本过低（当前: $PYTHON_VERSION），需要 ≥ 3.11"
    echo
    echo "请选择 Python 安装方式："
    echo "1) pyenv（推荐）- 可管理多个 Python 版本"
    echo "2) Homebrew - 简单快速安装"
    echo "3) 跳过安装"
    echo
    read -p "请输入选择 (1/2/3): " -n 1 -r PYTHON_CHOICE
    echo
    
    case $PYTHON_CHOICE in
        1)
            log "选择通过 pyenv 安装 Python..."
            install_python_via_pyenv
            ;;
        2)
            log "选择通过 Homebrew 安装 Python..."
            install_python_via_homebrew
            ;;
        3)
            warn "跳过 Python 安装"
            error "请手动安装 Python ≥ 3.11 后重试"
            ;;
        *)
            warn "无效选择，默认使用 pyenv 安装..."
            install_python_via_pyenv
            ;;
    esac
    
    # 重新检查 Python 版本
    PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "0.0")
    IFS='.' read -ra VER <<< "$PYTHON_VERSION"
    if [[ ${VER[0]} -lt 3 ]] || ([[ ${VER[0]} -eq 3 ]] && [[ ${VER[1]} -lt 11 ]]); then
        error "Python 安装后版本仍不满足要求（当前: $PYTHON_VERSION）"
    else
        success "Python 版本现在满足要求: $PYTHON_VERSION"
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

# 5. 检查并配置 VS Code 命令行工具
if ! command -v code &> /dev/null; then
    # 检查 VS Code 是否已安装（应用程序存在但命令行工具未配置）
    if [[ -d "/Applications/Visual Studio Code.app" ]]; then
        log "VS Code 已安装，但命令行工具未配置"
        read -p "是否自动配置 VS Code 命令行工具 'code' 命令？(Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            warn "跳过 VS Code 命令行工具配置"
            warn "您可以稍后在 VS Code 中按 Cmd+Shift+P，搜索 'Shell Command: Install code command in PATH' 手动配置"
        else
            log "正在配置 VS Code 命令行工具..."
            # 检查 /usr/local/bin 目录是否存在，不存在则创建
            if [[ ! -d "/usr/local/bin" ]]; then
                sudo mkdir -p /usr/local/bin
            fi
            # 创建软链接
            if sudo ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code; then
                success "VS Code 命令行工具配置成功: $(code --version | head -1)"
            else
                warn "VS Code 命令行工具配置失败，请手动配置"
                warn "或在 VS Code 中按 Cmd+Shift+P，搜索 'Shell Command: Install code command in PATH'"
            fi
        fi
    else
        warn "VS Code 未安装。建议安装 VS Code 以获得最佳开发体验。"
        read -p "是否用 Homebrew 安装 VS Code？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if ! command -v brew &> /dev/null; then
                log "正在安装 Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            log "正在安装 VS Code..."
            brew install --cask visual-studio-code
            success "VS Code 已安装"
            # 安装后自动配置命令行工具
            if [[ -d "/Applications/Visual Studio Code.app" ]]; then
                log "正在配置 VS Code 命令行工具..."
                if [[ ! -d "/usr/local/bin" ]]; then
                    sudo mkdir -p /usr/local/bin
                fi
                if sudo ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code; then
                    success "VS Code 命令行工具配置成功"
                fi
            fi
        fi
    fi
else
    success "VS Code 命令行工具已配置: $(code --version | head -1)"
fi

# 6. （可选）安装 Copilot CLI
read -p "是否安装 GitHub Copilot CLI（推荐用于 spec-kit）？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 检查并处理 Node.js 安装和版本问题
    INSTALL_COPILOT_CLI=false
    
    if ! command -v node &> /dev/null; then
        warn "Node.js 未安装。GitHub Copilot CLI 需要 Node.js ≥ 22。"
        read -p "是否通过 Homebrew 安装最新版 Node.js？(Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            if ! command -v brew &> /dev/null; then
                log "正在安装 Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            log "正在安装最新版 Node.js..."
            brew install node
            # 刷新环境变量
            export PATH="/opt/homebrew/bin:$PATH"
            if command -v node &> /dev/null; then
                success "Node.js 已安装: $(node --version)"
                INSTALL_COPILOT_CLI=true
            else
                warn "Node.js 安装可能未完成，请重新启动终端后再试"
            fi
        else
            warn "跳过 GitHub Copilot CLI 安装。"
        fi
    else
        # 检查 Node.js 版本和管理器
        NODE_VERSION=$(node --version | sed 's/v//')
        NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
        NODE_PATH=$(which node)
        log "检测到 Node.js 版本: v$NODE_VERSION"
        log "Node.js 路径: $NODE_PATH"
        
        # 检测是否使用 NVM
        if [[ "$NODE_PATH" == *".nvm"* ]]; then
            log "检测到使用 NVM 管理 Node.js"
            if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
                source "$HOME/.nvm/nvm.sh"
                log "当前已安装的 Node.js 版本:"
                nvm list | grep -v "N/A" || log "暂无已安装的版本"
                # 检查是否有满足要求的已安装版本
                INSTALLED_VERSIONS=$(nvm list | grep -E "v(2[2-9]|[3-9][0-9])" | grep -v "N/A" | head -1)
                if [[ -n "$INSTALLED_VERSIONS" ]]; then
                    # 清理版本号，移除箭头、空格等符号，只保留版本号
                    LATEST_SUITABLE=$(echo "$INSTALLED_VERSIONS" | grep -o 'v[0-9][0-9.]*' | sed 's/v//' | head -1)
                    log "发现已安装的可用版本: v$LATEST_SUITABLE"
                    printf "是否切换到 v%s？(Y/n): " "$LATEST_SUITABLE"
                    read -n 1 -r REPLY
                    echo
                    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                        if nvm use "$LATEST_SUITABLE"; then
                            success "已切换到 Node.js $(node --version)"
                            INSTALL_COPILOT_CLI=true
                        else
                            warn "切换失败，将尝试安装新版本"
                        fi
                    fi
                fi
                
                # 如果没有合适的已安装版本，或切换失败，则安装新版本
                if [[ "$INSTALL_COPILOT_CLI" != "true" ]]; then
                    read -p "是否通过 NVM 安装最新稳定版 Node.js？(Y/n): " -n 1 -r
                    echo
                    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                        log "正在安装最新稳定版 Node.js..."
                        if nvm install --lts && nvm use --lts; then
                            success "Node.js 已安装并切换到: $(node --version)"
                            INSTALL_COPILOT_CLI=true
                        else
                            warn "Node.js 安装失败"
                        fi
                    fi
                fi
            fi
        fi
        
        if [[ $NODE_MAJOR -lt 22 ]] && [[ "$INSTALL_COPILOT_CLI" != "true" ]]; then
            warn "Node.js 版本过低（当前: v$NODE_VERSION），GitHub Copilot CLI 需要 ≥ 22"
            
            # 检查是否有更新版本的 Node.js 可用
            if command -v brew &> /dev/null; then
                log "检查 Homebrew 中的 Node.js 版本..."
                BREW_NODE_VERSION=$(brew list --versions node 2>/dev/null | tail -1 | awk '{print $2}' || echo "")
                if [[ -n "$BREW_NODE_VERSION" ]]; then
                    BREW_NODE_MAJOR=$(echo "$BREW_NODE_VERSION" | cut -d. -f1)
                    if [[ $BREW_NODE_MAJOR -ge 22 ]]; then
                        log "发现 Homebrew 已安装 Node.js v$BREW_NODE_VERSION，但当前使用的是旧版本"
                        read -p "是否切换到新版本并重新链接？(Y/n): " -n 1 -r
                        echo
                        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                            log "正在重新链接 Node.js..."
                            brew unlink node 2>/dev/null || true
                            brew link --overwrite node
                            # 刷新环境变量
                            export PATH="/opt/homebrew/bin:$PATH"
                            hash -r  # 刷新命令缓存
                            if command -v node &> /dev/null; then
                                NEW_VERSION=$(node --version)
                                success "Node.js 已切换到: $NEW_VERSION"
                                INSTALL_COPILOT_CLI=true
                            fi
                        fi
                    else
                        log "正在升级 Node.js 到最新版..."
                        brew upgrade node
                        export PATH="/opt/homebrew/bin:$PATH"
                        hash -r
                        success "Node.js 已升级到: $(node --version)"
                        INSTALL_COPILOT_CLI=true
                    fi
                else
                    read -p "是否通过 Homebrew 升级到最新版 Node.js？(Y/n): " -n 1 -r
                    echo
                    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                        log "正在升级 Node.js..."
                        brew upgrade node
                        export PATH="/opt/homebrew/bin:$PATH"
                        hash -r
                        success "Node.js 已升级到: $(node --version)"
                        INSTALL_COPILOT_CLI=true
                    fi
                fi
            else
                warn "建议安装 Homebrew 来管理 Node.js 版本"
            fi
            
            if [[ "$INSTALL_COPILOT_CLI" != "true" ]]; then
                warn "跳过 GitHub Copilot CLI 安装。当前 Node.js 版本不满足要求。"
            fi
        elif [[ "$INSTALL_COPILOT_CLI" != "true" ]]; then
            success "Node.js 版本满足要求: v$NODE_VERSION"
            INSTALL_COPILOT_CLI=true
        fi
    fi
    
    # 安装 GitHub Copilot CLI
    if [[ "$INSTALL_COPILOT_CLI" == "true" ]] && command -v npm &> /dev/null && command -v node &> /dev/null; then
        NODE_MAJOR=$(node --version | sed 's/v//' | cut -d. -f1)
        if [[ $NODE_MAJOR -ge 22 ]]; then
            if ! command -v github-copilot-cli &> /dev/null; then
                log "正在安装 GitHub Copilot CLI..."
                log "这可能需要几分钟时间..."
                if npm install -g @github/copilot; then
                    success "GitHub Copilot CLI 已安装"
                    log "首次使用请运行: github-copilot-cli auth login"
                    log "或在 VS Code 中使用 GitHub Copilot Chat"
                else
                    warn "GitHub Copilot CLI 安装失败"
                    warn "您仍可以在 VS Code 中使用 GitHub Copilot Chat"
                fi
            else
                success "GitHub Copilot CLI 已安装"
            fi
        else
            warn "Node.js 版本仍然不足，跳过 Copilot CLI 安装"
        fi
    fi
fi

# 7. 安装 specify-cli via uv
log "正在通过 uv 安装 specify-cli（来自 GitHub spec-kit）..."
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git --python 3.11+

if command -v specify &> /dev/null; then
    success "specify CLI 安装成功！"
    echo
    echo -e "${GREEN}✅ 环境准备完成！现在可以运行：${NC}"
    echo "  specify init my-project --ai copilot"
    echo "  specify check  # 检查工具安装状态"
else
    error "specify CLI 安装失败，请手动检查"
fi