import os
from dataclasses import dataclass

@dataclass
class EngineConfig:
    base_url: str = os.getenv("OLLAMA_BASE_URL", "https://ai.evasi0nxiao.com")
    model: str = os.getenv("OLLAMA_MODEL", "prompt-architect")
    fallback_model: str = os.getenv("OLLAMA_FALLBACK_MODEL", "qwen2.5:14b")
    api_key: str = os.getenv("OLLAMA_API_KEY", "Xiaoyao0903")
    timeout_seconds: int = int(os.getenv("OLLAMA_TIMEOUT", "120"))
    default_temperature: float = 0.6
    context_window: int = 16384

config = EngineConfig()
