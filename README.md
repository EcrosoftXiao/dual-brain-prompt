# 🧠 Dual-Brain Prompt Plugin (双脑协同 Antigravity 插件)

> **Mac mini M4 (本地 14B 提示词架构师) × Antigravity (主驾驶编程智能体)**  
> 打造私密、零成本试错、高确定性的端到端 AI 研发工作流与原生 Antigravity 插件。

---

## 🏛️ 双脑协同架构

```mermaid
flowchart TD
    User["开发者输入 (粗糙想法 / 复杂业务需求)"] --> LocalBrain
    
    subgraph LocalBrain ["🧠 脑一：Mac mini M4 本地私密引擎 (Ollama)"]
        direction TB
        M4Model["prompt-architect (Qwen2.5-14B)"]
        Parse["1. 意图深度拆解"]
        Rule["2. 边界约束强化 (防幻觉)"]
        Format["3. 角色/上下文/步骤结构化"]
        M4Model --> Parse --> Rule --> Format
    end
    
    Format --> CleanPrompt["🚀 生产级结构化 Prompt (带占位符与负向约束)"]
    
    CleanPrompt --> CloudBrain
    
    subgraph CloudBrain ["⚡ 脑二：Antigravity 深度工程落地"]
        direction TB
        AGY["Antigravity Agent (通过 MCP 原生工具调用)"]
        AGY_Read["全代码库检索与上下文建模"]
        AGY_Write["多文件协同重构与代码生成"]
        AGY_Test["自动化测试套件与安全验证"]
        AGY --> AGY_Read --> AGY_Write --> AGY_Test
    end
    
    AGY_Test --> ProductionCode["🎯 交付生产级高质量代码与文档"]
```

---

## 🔌 插件架构与规范

本项目符合标准 **Antigravity 插件规范**：

```text
dual-brain-prompt/
├── plugin.json                 # 插件元数据声明清单
├── mcp_config.json             # 原生 MCP Server 配置 (Eager 装载)
├── rules/
│   └── AGENTS.md               # 插件内置双脑协同规范
├── skills/
│   └── local-prompt-refine/
│       └── SKILL.md            # 提示词优化工作流技能
├── src/                        # 核心引擎驱动模块
│   ├── config.py
│   ├── engine.py
│   ├── mcp_server.py           # 原生 MCP Stdio Server
│   └── cli.py                  # 本地独立命令行工具
├── templates/                  # 预置提示词模板
└── tests/                      # 单元与集成测试套件
```

---

## 🚀 日常使用

### 1. 在 Antigravity 中直接使用（自然语言）
因为已安装为全局插件，在任何项目对话中直接说：
> *“用本地模型帮我优化这个提示词：写一个带重试的 HTTP 客户端”*

Antigravity 会自动通过 MCP 原生工具 `optimize_prompt` 调用本地 M4 芯片计算并返回。

### 2. 命令行工具（终端独立使用）
```bash
# 检查健康状态
python3 -m src.cli check

# 完整诊断与优化
python3 -m src.cli optimize "实现一个安全的密码哈希校验函数"

# 仅输出纯净 Prompt 并复制到剪贴板
python3 -m src.cli prompt-only "设计一个统一错误处理中间件" | pbcopy
```

---

## 🧪 测试

```bash
python3 -m unittest discover tests/
```
