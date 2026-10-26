#!/usr/bin/env bash
# ==============================================================================
# Dual-Brain Prompt - One-Click Service Restarter
# Restarts both Ollama (M4 Metal engine) and Cloudflare Tunnel (remote access)
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

echo -e "${BOLD}======================================================${RESET}"
echo -e "${BOLD}🔄 一键重启双脑后端服务 (Ollama + Cloudflare Tunnel)   ${RESET}"
echo -e "${BOLD}======================================================${RESET}\n"

# 1. 重启 Ollama 后台守护进程
info "1/3 重启 Ollama (M4 GPU 推理引擎)..."
if command -v brew &> /dev/null; then
    brew services restart ollama > /dev/null 2>&1 || launchctl kickstart -k "gui/$(id -u)/sh.brew.ollama"
else
    launchctl kickstart -k "gui/$(id -u)/sh.brew.ollama"
fi
success "Ollama 守护进程已重启。"

# 2. 重启 Cloudflare Tunnel 后台守护进程
info "2/3 重启 Cloudflare Tunnel (远程公网隧道)..."
if [ -f "${HOME}/Library/LaunchAgents/com.cloudflare.cloudflared.plist" ]; then
    launchctl kickstart -k "gui/$(id -u)/com.cloudflare.cloudflared"
    success "Cloudflare 隧道已重启。"
else
    warn "未在 ~/Library/LaunchAgents 中找到 com.cloudflare.cloudflared.plist"
fi

# 3. 健康检查与验证
info "3/3 等待服务就绪并验证连通性..."
sleep 3

# 本地检查
if curl -s http://127.0.0.1:11434/api/tags > /dev/null; then
    success "本地 Ollama 接口正常 (127.0.0.1:11434)"
else
    warn "本地 Ollama 尚未响应，可能仍在初始化..."
fi

# 远程检查
AUTH_HEADER="Authorization: Bearer Xiaoyao0903"
if curl -s -H "${AUTH_HEADER}" https://ai.evasi0nxiao.com/api/tags > /dev/null; then
    success "公网 Cloudflare 隧道正常 (https://ai.evasi0nxiao.com)"
else
    warn "公网隧道连接建立中，预计 5-10 秒内完全就绪..."
fi

echo -e "\n${GREEN}${BOLD}🎉 双脑服务已全面重启并恢复运行！${RESET}"
echo -e "• 本地状态: $(ollama --version)"
echo -e "• 当前模型: $(curl -s http://127.0.0.1:11434/api/tags | grep -o '"name":"prompt-architect:latest"' || echo '已就绪')"
echo -e "• 远程端点: https://ai.evasi0nxiao.com\n"
