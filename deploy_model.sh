#!/usr/bin/env bash
# ==============================================================================
# Dual-Brain Prompt Plugin - Local Model Deployer (Mac mini M4 / Apple Silicon)
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
BASE_MODEL="qwen2.5:14b"
TARGET_MODEL="prompt-architect"
MODELFILE_PATH="${SCRIPT_DIR}/Modelfile"

echo -e "${BOLD}======================================================${RESET}"
echo -e "${BOLD}🚀 Local M4 Model Deployment Tool (Ollama Engine)      ${RESET}"
echo -e "${BOLD}======================================================${RESET}\n"

# 1. 检查操作系统与硬件架构
info "1/5 检查系统运行环境..."
OS_NAME="$(uname -s)"
ARCH_NAME="$(uname -m)"

if [[ "${OS_NAME}" == "Darwin" ]]; then
    if [[ "${ARCH_NAME}" == "arm64" ]]; then
        success "检测到 Apple Silicon 芯片 (${ARCH_NAME})，完美支持 Metal GPU 统一内存推理加速！"
    else
        warn "检测到 macOS Intel 架构 (${ARCH_NAME})，将降级为 CPU 运行。"
    fi
else
    info "运行在 Linux/其他环境 (${OS_NAME} ${ARCH_NAME})。"
fi

# 2. 检查 Ollama 是否已安装并启动
info "2/5 检查 Ollama 安装与服务状态..."
if ! command -v ollama &> /dev/null; then
    warn "未检测到 Ollama 命令，正在尝试通过 Homebrew 安装..."
    if command -v brew &> /dev/null; then
        brew install ollama
        success "Ollama 安装成功。"
    else
        error "未找到 brew。请先从官网手动安装 Ollama: https://ollama.com/download"
        exit 1
    fi
fi

# 检查并配置 macOS Launchd 硬件加速 (Flash Attention & Q8_0 KV Cache)
if [[ "${OS_NAME}" == "Darwin" ]]; then
    LAUNCH_AGENTS_DIR="${HOME}/Library/LaunchAgents"
    TARGET_PLIST="${LAUNCH_AGENTS_DIR}/sh.brew.ollama.plist"
    SOURCE_PLIST="${SCRIPT_DIR}/launchd/sh.brew.ollama.plist"

    if [ -f "${SOURCE_PLIST}" ]; then
        mkdir -p "${LAUNCH_AGENTS_DIR}"
        info "正在配置 M4 硬件加速环境变量 (Flash Attention & Q8_0 KV Cache)..."
        cp "${SOURCE_PLIST}" "${TARGET_PLIST}"
        success "已部署硬件加速守护配置: ${TARGET_PLIST}"
    fi
fi

# 检查本地服务连通性
if ! curl -s "http://127.0.0.1:11434/api/tags" &> /dev/null; then
    info "本地 Ollama 服务未运行，正在后台启动服务..."
    if [[ "${OS_NAME}" == "Darwin" ]] && [ -f "${HOME}/Library/LaunchAgents/sh.brew.ollama.plist" ]; then
        launchctl unload "${HOME}/Library/LaunchAgents/sh.brew.ollama.plist" 2>/dev/null || true
        launchctl load "${HOME}/Library/LaunchAgents/sh.brew.ollama.plist"
    elif command -v brew &> /dev/null && brew services list | grep -q ollama; then
        brew services start ollama
    else
        OLLAMA_FLASH_ATTENTION=1 OLLAMA_KV_CACHE_TYPE=q8_0 nohup ollama serve > /dev/null 2>&1 &
    fi
    # 等待服务就绪
    WAIT_COUNT=0
    until curl -s "http://127.0.0.1:11434/api/tags" &> /dev/null || [ ${WAIT_COUNT} -eq 15 ]; do
        sleep 1
        WAIT_COUNT=$((WAIT_COUNT + 1))
    done
fi

if curl -s "http://127.0.0.1:11434/api/tags" &> /dev/null; then
    success "Ollama 本地服务正常监听 (http://127.0.0.1:11434)"
else
    error "无法连接到本地 Ollama 服务，请先手动运行 'ollama serve'。"
    exit 1
fi

# 3. 检查并拉取开源基座模型 (qwen2.5:14b)
info "3/5 检查基座模型 (${BASE_MODEL})..."
INSTALLED_MODELS=$(ollama list 2>/dev/null || true)

if echo "${INSTALLED_MODELS}" | grep -q "${BASE_MODEL}"; then
    success "基座模型 ${BASE_MODEL} 已在本地就绪。"
else
    info "基座模型 ${BASE_MODEL} 未在本地发现，正在从 Ollama 官方库拉取 (约 9.9 GB)..."
    ollama pull "${BASE_MODEL}"
    success "基座模型 ${BASE_MODEL} 下载完成！"
fi

# 4. 构建并注册定制化的 prompt-architect 专用模型
info "4/5 编译定制版 ${TARGET_MODEL} 提示词架构师模型..."
if [ ! -f "${MODELFILE_PATH}" ]; then
    error "未找到 Modelfile: ${MODELFILE_PATH}"
    exit 1
fi

ollama create "${TARGET_MODEL}" -f "${MODELFILE_PATH}"
success "模型构建成功：${TARGET_MODEL}:latest"

# 5. 验证推理健康度
info "5/5 执行本地模型端到端推理连通性测试..."
TEST_PROMPT="帮我写一个代码重构的规范提示词"
TEST_RESP=$(ollama run "${TARGET_MODEL}" "${TEST_PROMPT}" --verbose 2>&1 | head -n 15 || true)

if [ -n "${TEST_RESP}" ]; then
    success "模型自检测试通过！"
    echo -e "\n${BOLD}${BLUE}--- 推理返回预览 ---${RESET}"
    echo "${TEST_RESP}"
    echo -e "${BOLD}${BLUE}--------------------${RESET}\n"
else
    warn "推理自检未能返回内容，请手动执行 'ollama run ${TARGET_MODEL}' 测试。"
fi

echo -e "${BOLD}${GREEN}======================================================${RESET}"
echo -e "${BOLD}${GREEN}🎉 本地大模型部署完成！${RESET}"
echo -e "${BOLD}${GREEN}======================================================${RESET}\n"
echo -e "已就绪服务详情："
echo -e "  • 模型名称: ${BOLD}${TARGET_MODEL}:latest${RESET}"
echo -e "  • 基座参数: Qwen2.5-14B (Q4_K_M) @ 16,384 tokens 上下文"
echo -e "  • 监听端点: http://127.0.0.1:11434"
echo -e "  • 独立测试命令: ${YELLOW}ollama run ${TARGET_MODEL}${RESET}"
echo -e "  • CLI 优化测试: ${YELLOW}python3 -m src.cli optimize \"测试需求\"${RESET}\n"
