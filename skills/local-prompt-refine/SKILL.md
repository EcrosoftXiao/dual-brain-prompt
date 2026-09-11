---
name: local-prompt-refine
description: Call the local Mac M4 Qwen2.5-14B prompt-architect engine to analyze, expand, and structure raw user prompts into production-grade prompts with constraints and few-shot examples. Use this skill when the user asks to optimize prompts or when building complex agent tasks.
---

# Local Prompt Refine Skill (Mac M4 Local Engine)

This skill enables Antigravity to leverage the local 14B model running on Apple Silicon M4 to refine, structure, and eliminate hallucinations in prompts.

## Quick CLI Invocations

To optimize a raw user prompt with full diagnostic report:
```bash
python3 -m src.cli optimize "用户的原始简短需求"
```

To extract only the clean markdown prompt code block (ready for copying or feeding directly to an LLM):
```bash
python3 -m src.cli prompt-only "用户的原始简短需求"
```

To include contextual background:
```bash
python3 -m src.cli optimize "重构鉴权模块" --context "基于 FastAPI + PyJWT，采用 RSA256 非对称签名"
```

## Python Integration
```python
from src.engine import DualBrainEngine

engine = DualBrainEngine()
result = engine.optimize("帮我写一个数据清洗管道")
print(result.prompt)
```
