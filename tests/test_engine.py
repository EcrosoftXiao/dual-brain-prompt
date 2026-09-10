import unittest
from src.engine import DualBrainEngine

class TestDualBrainEngine(unittest.TestCase):
    def setUp(self):
        self.engine = DualBrainEngine()

    def test_health_check(self):
        """Verify local Ollama service connectivity."""
        status = self.engine.check_health()
        self.assertTrue(status.get("healthy"), f"Ollama not healthy: {status.get('error')}")
        self.assertIn("prompt-architect:latest", status.get("models", []))

    def test_parse_response(self):
        """Verify markdown response parsing logic."""
        mock_raw = """
### 🔍 1. 意图解析与优化策略
- 原始意图：测试需求
- 优化点：添加约束

### 🚀 2. 优化后的完整 Prompt
```markdown
# Role
测试架构师
# Tasks
执行单元测试
```

### 💡 3. 使用建议与调试技巧
- 建议温度: 0.5
"""
        mock_data = {
            "response": mock_raw,
            "eval_count": 100,
            "eval_duration": 5000000000
        }
        res = self.engine._parse_response(mock_data, "test-model")
        self.assertIn("原始意图", res.strategy)
        self.assertIn("# Role", res.prompt)
        self.assertIn("测试架构师", res.prompt)
        self.assertIn("建议温度", res.usage_tips)
        self.assertEqual(res.eval_speed, 20.0)
        self.assertEqual(res.total_tokens, 100)

    def test_live_optimization(self):
        """Run a live prompt optimization test against local M4 model."""
        res = self.engine.optimize("帮我写一个数据库健康检查函数")
        self.assertTrue(len(res.prompt) > 0, "Prompt should not be empty")
        self.assertTrue(res.total_tokens > 0, "Tokens should be greater than zero")

if __name__ == "__main__":
    unittest.main()
