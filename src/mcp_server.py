#!/usr/bin/env python3
"""
Zero-dependency Model Context Protocol (MCP) server for Local M4 prompt-architect.
Communicates via JSON-RPC 2.0 over Stdio.
"""
import sys
import json
import os

# Ensure local src module is importable
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from src.engine import DualBrainEngine

engine = DualBrainEngine()

TOOL_DEFINITION = {
    "name": "optimize_prompt",
    "description": (
        "Call the local Mac mini M4 (Qwen2.5-14B prompt-architect) model to deeply analyze, "
        "structure, and optimize a raw user prompt or requirement into a production-grade prompt "
        "with Role, Context, Tasks, negative anti-hallucination Constraints, and Few-shot examples."
    ),
    "inputSchema": {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "The raw prompt or requirement description to be optimized."
            },
            "context": {
                "type": "string",
                "description": "Optional engineering context, stack details, or project background."
            }
        },
        "required": ["query"]
    }
}

def send_response(response_dict):
    out = json.dumps(response_dict, ensure_ascii=False)
    sys.stdout.write(out + "\n")
    sys.stdout.flush()

def handle_request(req):
    req_id = req.get("id")
    method = req.get("method")
    params = req.get("params", {})

    # 1. initialize
    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {}
                },
                "serverInfo": {
                    "name": "prompt-architect-mcp",
                    "version": "1.0.0"
                }
            }
        }

    # 2. initialized notification
    if method in ("notifications/initialized", "initialized"):
        return None

    # 3. ping
    if method == "ping":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {}
        }

    # 4. tools/list
    if method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "tools": [TOOL_DEFINITION]
            }
        }

    # 5. tools/call
    if method == "tools/call":
        tool_name = params.get("name")
        args = params.get("arguments", {})

        if tool_name == "optimize_prompt":
            query = args.get("query", "")
            context = args.get("context", "")
            try:
                res = engine.optimize(query, task_context=context)
                content_text = (
                    f"{res.raw_response}\n\n"
                    f"---\n"
                    f"**[M4 Local Inference Stats]**: {res.eval_speed} tokens/s | "
                    f"Generated {res.total_tokens} tokens | Model: {res.model_used}"
                )
                return {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "content": [
                            {
                                "type": "text",
                                "text": content_text
                            }
                        ]
                    }
                }
            except Exception as e:
                return {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "isError": True,
                        "content": [
                            {
                                "type": "text",
                                "text": f"Error calling local M4 prompt-architect: {str(e)}"
                            }
                        ]
                    }
                }

        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "error": {
                "code": -32601,
                "message": f"Tool '{tool_name}' not found"
            }
        }

    # Unknown method
    if req_id is not None:
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "error": {
                "code": -32601,
                "message": f"Method '{method}' not found"
            }
        }
    return None

def main():
    chmod_self = os.stat(__file__).st_mode
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
            res = handle_request(req)
            if res is not None:
                send_response(res)
        except Exception as e:
            sys.stderr.write(f"MCP server parse error: {e}\n")
            sys.stderr.flush()

if __name__ == "__main__":
    main()
