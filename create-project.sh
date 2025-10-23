#!/bin/bash

# create-project.sh
# 便捷的 spec-kit 项目创建脚本
# 用法: ./create-project.sh <project-name> [project-path] [--ai copilot]

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 检查参数
if [ $# -lt 1 ]; then
    echo "用法: $0 <project-name> [project-path] [--ai copilot]"
    echo "示例: $0 my-awesome-project ~/workspace --ai copilot"
    echo "      $0 my-project /path/to/projects"
    echo "如果不指定路径，默认创建到桌面"
    exit 1
fi

PROJECT_NAME=$1
PROJECT_PATH=""
AI_FLAG=""

# 解析参数
shift
while [ $# -gt 0 ]; do
    case "$1" in
        --ai)
            if [ $# -ge 2 ]; then
                AI_FLAG="--ai $2"
                shift 2
            else
                echo "错误: --ai 参数需要指定 AI 助手类型"
                exit 1
            fi
            ;;
        *)
            if [ -z "$PROJECT_PATH" ]; then
                PROJECT_PATH="$1"
                shift
            else
                echo "错误: 未知参数 $1"
                exit 1
            fi
            ;;
    esac
done

# 如果没有指定路径，询问用户
if [ -z "$PROJECT_PATH" ]; then
    echo -n "请输入项目创建路径 (默认: 桌面): "
    read -r user_input
    if [ -z "$user_input" ]; then
        PROJECT_PATH="$HOME/Desktop"
    else
        PROJECT_PATH="$user_input"
    fi
fi

# 展开 ~ 和相对路径为绝对路径
PROJECT_PATH=$(eval echo "$PROJECT_PATH")
PROJECT_PATH=$(cd "$PROJECT_PATH" 2>/dev/null && pwd || echo "$PROJECT_PATH")

# 检查 specify 命令是否可用
if ! command -v specify &> /dev/null; then
    echo "错误: specify 命令未找到。请先运行 ./setup-spec-kit.sh 安装环境。"
    exit 1
fi

# 检查目标路径是否存在
if [ ! -d "$PROJECT_PATH" ]; then
    warn "目录 $PROJECT_PATH 不存在"
    echo -n "是否创建该目录？(y/N): "
    read -r create_dir
    if [[ "$create_dir" =~ ^[Yy]$ ]]; then
        mkdir -p "$PROJECT_PATH"
        success "已创建目录: $PROJECT_PATH"
    else
        echo "操作已取消"
        exit 1
    fi
fi

# 计算完整的项目路径
FULL_PROJECT_PATH="$PROJECT_PATH/$PROJECT_NAME"

# 检查项目是否已存在
if [ -d "$FULL_PROJECT_PATH" ]; then
    warn "项目 $FULL_PROJECT_PATH 已存在，请选择其他名称或路径。"
    exit 1
fi

log "正在 $PROJECT_PATH 中创建项目: $PROJECT_NAME"

# 进入目标目录
cd "$PROJECT_PATH"

# 创建 spec-kit 项目
if [ -n "$AI_FLAG" ]; then
    log "使用 AI 助手创建项目: specify init $PROJECT_NAME $AI_FLAG"
    specify init "$PROJECT_NAME" $AI_FLAG
else
    log "创建项目: specify init $PROJECT_NAME"
    specify init "$PROJECT_NAME"
fi

# 进入项目目录
cd "$PROJECT_NAME"

success "项目 $PROJECT_NAME 创建成功！"
echo
echo "项目位置: $FULL_PROJECT_PATH"
echo

# 询问用户是否要用 VS Code 打开项目
echo -n "是否要用 VS Code 打开项目？(y/N): "
read -r open_vscode

if [[ "$open_vscode" =~ ^[Yy]$ ]]; then
    if command -v code &> /dev/null; then
        log "正在用 VS Code 打开项目..."
        code "$FULL_PROJECT_PATH"
        success "项目已在 VS Code 中打开！"
        echo
        echo "在 VS Code 中，您可以："
        echo "  • 使用 GitHub Copilot Chat 的 /speckit 命令进行规范驱动开发"
        echo "  • 在终端中运行: specify check  # 检查工具状态"
    else
        warn "VS Code 命令行工具 'code' 未找到"
        echo "请手动打开 VS Code 并打开项目目录: $FULL_PROJECT_PATH"
    fi
else
    echo "接下来您可以："
    echo "  cd $FULL_PROJECT_PATH"
    echo "  code .  # 用 VS Code 打开项目"
    echo "  在 VS Code 中使用 GitHub Copilot Chat 的 /speckit 命令"
    echo "  或者使用: specify check  # 检查工具状态"
fi

echo
log "开始您的规范驱动开发之旅！"