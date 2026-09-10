import json
import re
import urllib.request
import urllib.error
from dataclasses import dataclass
from typing import Optional, Dict, Any
from .config import config

@dataclass
class PromptResult:
    raw_response: str
    strategy: str
    prompt: str
    usage_tips: str
    eval_speed: float
    total_tokens: int
    model_used: str

class DualBrainEngine:
    def __init__(self, base_url: Optional[str] = None, model: Optional[str] = None):
        self.base_url = (base_url or config.base_url).rstrip("/")
        self.model = model or config.model
        self.fallback_model = config.fallback_model

    def check_health(self) -> Dict[str, Any]:
        """Check if local Ollama service is reachable and list models."""
        url = f"{self.base_url}/api/tags"
        req = urllib.request.Request(url, headers={"User-Agent": "DualBrain/1.0"})
        try:
            with urllib.request.urlopen(req, timeout=5) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                models = [m.get("name", "") for m in data.get("models", [])]
                return {"healthy": True, "models": models}
        except Exception as e:
            return {"healthy": False, "error": str(e)}

    def optimize(self, user_request: str, task_context: str = "") -> PromptResult:
        """Send prompt optimization request to local M4 model."""
        prompt_input = user_request.strip()
        if task_context:
            prompt_input = f"【任务背景与上下文】\n{task_context.strip()}\n\n【原始需求】\n{prompt_input}"

        payload = {
            "model": self.model,
            "prompt": prompt_input,
            "stream": False,
            "options": {
                "temperature": config.default_temperature,
                "num_ctx": config.context_window,
            }
        }

        try:
            resp_data = self._call_generate(payload)
            model_used = self.model
        except Exception as primary_err:
            # Fallback to secondary model if primary fails
            if self.model != self.fallback_model:
                payload["model"] = self.fallback_model
                resp_data = self._call_generate(payload)
                model_used = self.fallback_model
            else:
                raise primary_err

        return self._parse_response(resp_data, model_used)

    def _call_generate(self, payload: dict) -> dict:
        url = f"{self.base_url}/api/generate"
        req_data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=req_data,
            headers={"Content-Type": "application/json", "User-Agent": "DualBrain/1.0"}
        )
        try:
            with urllib.request.urlopen(req, timeout=config.timeout_seconds) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.URLError as e:
            raise RuntimeError(f"Failed to connect to local Ollama at {url}: {e}")

    def _parse_response(self, data: dict, model_used: str) -> PromptResult:
        raw_text = data.get("response", "")
        eval_count = data.get("eval_count", 0)
        eval_duration = data.get("eval_duration", 1) / 1e9
        eval_speed = round(eval_count / eval_duration, 2) if eval_duration > 0 else 0.0

        strategy = ""
        prompt = ""
        usage_tips = ""

        # Section 1 extraction
        s1_match = re.search(r"###\s*🔍\s*1\.\s*意图解析与优化策略(.*?)(?=###\s*🚀\s*2|$)", raw_text, re.DOTALL)
        if s1_match:
            strategy = s1_match.group(1).strip()

        # Section 2 extraction
        s2_match = re.search(r"###\s*🚀\s*2\.\s*优化后的完整 Prompt(.*?)(?=###\s*💡\s*3|$)", raw_text, re.DOTALL)
        if s2_match:
            prompt = s2_match.group(1).strip()
            # Extract inner code block if present
            code_match = re.search(r"```(?:markdown)?\s*(.*?)\s*```", prompt, re.DOTALL)
            if code_match:
                prompt = code_match.group(1).strip()
        else:
            # Fallback if strict header missing
            prompt = raw_text

        # Section 3 extraction
        s3_match = re.search(r"###\s*💡\s*3\.\s*使用建议与调试技巧(.*)", raw_text, re.DOTALL)
        if s3_match:
            usage_tips = s3_match.group(1).strip()

        return PromptResult(
            raw_response=raw_text,
            strategy=strategy,
            prompt=prompt,
            usage_tips=usage_tips,
            eval_speed=eval_speed,
            total_tokens=eval_count,
            model_used=model_used
        )
