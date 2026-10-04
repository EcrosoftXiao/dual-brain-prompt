import argparse
import sys
from .engine import DualBrainEngine

def main():
    parser = argparse.ArgumentParser(
        description="Dual-Brain Prompt Optimizer (Local M4 Engine)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""示例用法:
  python3 -m src.cli optimize "帮我写一个给大模型的提示词：做代码审查"
  python3 -m src.cli prompt-only "设计一个统一错误处理中间件"
  python3 -m src.cli check
"""
    )

    subparsers = parser.add_subparsers(dest="command", help="子命令")

    # Command: optimize
    opt_parser = subparsers.add_parser("optimize", help="优化提示词并输出完整报告")
    opt_parser.add_argument("query", type=str, help="原始提示词或需求描述")
    opt_parser.add_argument("-c", "--context", type=str, default="", help="补充任务背景或工程上下文")
    opt_parser.add_argument("-m", "--model", type=str, default=None, help="覆盖使用的模型名称")

    # Command: prompt-only
    po_parser = subparsers.add_parser("prompt-only", help="仅提取优化后的 Prompt 代码块（适合脚本管道和复制）")
    po_parser.add_argument("query", type=str, help="原始提示词或需求描述")
    po_parser.add_argument("-c", "--context", type=str, default="", help="补充任务背景或工程上下文")

    # Command: check
    subparsers.add_parser("check", help="检查本地 Ollama 服务与模型健康状态")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    engine = DualBrainEngine(model=getattr(args, "model", None))

    if args.command == "check":
        status = engine.check_health()
        if status.get("healthy"):
            print("✅ 本地 Ollama 引擎连接正常！")
            print("📦 可用模型列表:")
            for m in status.get("models", []):
                print(f"   - {m}")
        else:
            print("❌ 无法连接到本地 Ollama 服务:")
            print(f"   {status.get('error')}")
            sys.exit(1)

    elif args.command == "optimize":
        print(f"⏳ 正在通过本地 M4 芯片（模型: {engine.model}）进行深度意图解析与重构...\n")
        try:
            result = engine.optimize(args.query, task_context=args.context)
            print(result.raw_response)
            print("\n" + "=" * 60)
            print(f"📊 推理统计: 速度 {result.eval_speed} tok/s | 生成 {result.total_tokens} tokens | 使用模型 {result.model_used}")
            print("=" * 60)
        except Exception as e:
            print(f"❌ 优化失败: {e}", file=sys.stderr)
            sys.exit(1)

    elif args.command == "prompt-only":
        try:
            result = engine.optimize(args.query, task_context=args.context)
            print(result.prompt)
        except Exception as e:
            print(f"❌ 优化失败: {e}", file=sys.stderr)
            sys.exit(1)

if __name__ == "__main__":
    main()
