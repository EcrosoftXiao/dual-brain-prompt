import os
from dataclasses import dataclass

@dataclass
class EngineConfig:
    base_url: str = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
    model: str = os.getenv("OLLAMA_MODEL", "prompt-architect")
    fallback_model: str = os.getenv("OLLAMA_FALLBACK_MODEL", "qwen2.5:14b")
    timeout_seconds: int = int(os.getenv("OLLAMA_TIMEOUT", "120"))
    default_temperature: float = 0.6
    context_window: int = 16384

config = EngineConfig()
