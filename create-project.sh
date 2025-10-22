#!/bin/bash

# create-project.sh
# 便捷的 spec-kit 项目创建脚本
# 用法: ./create-project.sh <project-name> [--ai copilot]

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
    echo "用法: $0 <project-name> [--ai copilot]"
    echo "示例: $0 my-awesome-project --ai copilot"
    exit 1
fi

PROJECT_NAME=$1
AI_FLAG=""

# 检查是否有 --ai 参数
if [ $# -ge 2 ] && [ "$2" = "--ai" ] && [ $# -ge 3 ]; then
    AI_FLAG="--ai $3"
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_DIR="$SCRIPT_DIR/projects"

# 检查 specify 命令是否可用
if ! command -v specify &> /dev/null; then
    echo "错误: specify 命令未找到。请先运行 ./setup-spec-kit.sh 安装环境。"
    exit 1
fi

# 创建项目目录（如果不存在）
mkdir -p "$PROJECTS_DIR"

log "正在 $PROJECTS_DIR 中创建项目: $PROJECT_NAME"

# 进入项目目录
cd "$PROJECTS_DIR"

# 检查项目是否已存在
if [ -d "$PROJECT_NAME" ]; then
    warn "项目 $PROJECT_NAME 已存在，请选择其他名称。"
    exit 1
fi

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
echo "项目位置: $PROJECTS_DIR/$PROJECT_NAME"
echo

# 询问用户是否要用 VS Code 打开项目
echo -n "是否要用 VS Code 打开项目？(y/N): "
read -r open_vscode

if [[ "$open_vscode" =~ ^[Yy]$ ]]; then
    if command -v code &> /dev/null; then
        log "正在用 VS Code 打开项目..."
        code "$PROJECTS_DIR/$PROJECT_NAME"
        success "项目已在 VS Code 中打开！"
        echo
        echo "在 VS Code 中，您可以："
        echo "  • 使用 GitHub Copilot Chat 的 /speckit 命令进行规范驱动开发"
        echo "  • 在终端中运行: specify check  # 检查工具状态"
    else
        warn "VS Code 命令行工具 'code' 未找到"
        echo "请手动打开 VS Code 并打开项目目录: $PROJECTS_DIR/$PROJECT_NAME"
    fi
else
    echo "接下来您可以："
    echo "  cd $PROJECTS_DIR/$PROJECT_NAME"
    echo "  code .  # 用 VS Code 打开项目"
    echo "  在 VS Code 中使用 GitHub Copilot Chat 的 /speckit 命令"
    echo "  或者使用: specify check  # 检查工具状态"
fi

echo
log "开始您的规范驱动开发之旅！"