#!/usr/bin/env bash
# ==============================================================================
# Dual-Brain Prompt Plugin - Antigravity One-Click Installer & Deployer
# ==============================================================================
set -euo pipefail

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

info() { echo -e "${BLUE}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${RESET} $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error() { echo -e "${RED}[ERROR]${RESET} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANTIGRAVITY_PLUGINS_DIR="${HOME}/.gemini/config/plugins"
TARGET_DIR="${ANTIGRAVITY_PLUGINS_DIR}/dual-brain-prompt"

echo -e "${BOLD}======================================================${RESET}"
echo -e "${BOLD}🧠 Dual-Brain Prompt Plugin Installer for Antigravity ${RESET}"
echo -e "${BOLD}======================================================${RESET}\n"

# 1. 检查 Python 3 环境
info "1/5 检查 Python 环境..."
if ! command -v python3 &> /dev/null; then
    error "未找到 python3，请先安装 Python 3.10+。"
    exit 1
fi
PYTHON_VER=$(python3 --version 2>&1)
success "Python 环境就绪: ${PYTHON_VER}"

# 2. 检查后端健康状态 (通过域名或本地服务)
info "2/5 检查双脑后端连接状态..."
if python3 -m src.cli check; then
    success "模型后端连通性检查通过！"
else
    warn "未能通过默认域名访问，请确保本地 Ollama 或 Cloudflare Tunnel 正在运行。"
fi

# 3. 确保脚本可执行权限
info "3/5 配置文件权限..."
chmod +x "${SCRIPT_DIR}/src/mcp_server.py"
chmod +x "${SCRIPT_DIR}/src/cli.py"
success "权限配置完成。"

# 4. 创建 Antigravity 插件目录并建立软链接
info "4/5 部署插件到 Antigravity 全局目录 (${TARGET_DIR})..."
mkdir -p "${ANTIGRAVITY_PLUGINS_DIR}"

if [ -L "${TARGET_DIR}" ]; then
    info "检测到已存在的软链接，正在更新..."
    rm -f "${TARGET_DIR}"
elif [ -d "${TARGET_DIR}" ]; then
    warn "检测到已存在的插件普通目录，备份至 ${TARGET_DIR}.bak..."
    rm -rf "${TARGET_DIR}.bak"
    mv "${TARGET_DIR}" "${TARGET_DIR}.bak"
fi

ln -s "${SCRIPT_DIR}" "${TARGET_DIR}"
success "已成功软链接: ${TARGET_DIR} -> ${SCRIPT_DIR}"

# 5. 验证 MCP 服务可用性 (Ping 验证)
info "5/5 验证 MCP 服务响应..."
MCP_TEST_REQ='{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
MCP_RESP=$(echo "${MCP_TEST_REQ}" | python3 "${SCRIPT_DIR}/src/mcp_server.py" 2>/dev/null | head -n 1)

if echo "${MCP_RESP}" | grep -q "optimize_prompt"; then
    success "MCP 工具注册验证成功 (optimize_prompt 已就绪)！"
else
    error "MCP 验证异常，输出: ${MCP_RESP}"
    exit 1
fi

echo -e "\n${BOLD}${GREEN}======================================================${RESET}"
echo -e "${BOLD}${GREEN}🎉 部署完成！Dual-Brain 插件已装载进 Antigravity。${RESET}"
echo -e "${BOLD}${GREEN}======================================================${RESET}\n"
echo -e "现在你可以在 Antigravity 中直接使用："
echo -e "  👉 自然语言：'用本地模型帮我优化这个提示词：...'"
echo -e "  👉 独立命令行：'python3 -m src.cli optimize \"...\"'"
echo -e "  👉 终端管道：'python3 -m src.cli prompt-only \"...\" | pbcopy'\n"
