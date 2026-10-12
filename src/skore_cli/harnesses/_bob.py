"""Bob Shell and Bob IDE configuration and launch."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from skore_cli._project import ensure_gitignore_entry
from skore_cli._style import console
from skore_cli.harnesses import _process
from skore_cli.harnesses._context import SKORE_PROVIDER_KEY, HarnessContext
from skore_cli.harnesses._cursor import _load_json_object

BOB_IDE_APP_PATH = Path("/Applications/IBM Bob.app")


def _configure_bob(ctx: HarnessContext, transport: dict[str, str]) -> dict[str, Any]:
    """Register the hub's MCP server in ``.bob/mcp.json``.

    Both Bobs read this file but declare a streamable-HTTP server differently,
    so the transport keys come from the caller. Unlike Cursor, Bob takes the
    server's enabled state and the tool approval from the file, so there is no
    manual step left to the user.
    """
    config_dir = ctx.workspace / ".bob"
    config_dir.mkdir(parents=True, exist_ok=True)
    config_path = config_dir / "mcp.json"

    config = _load_json_object(config_path)
    servers = config.get("mcpServers")
    if not isinstance(servers, dict):
        servers = {}
    servers[SKORE_PROVIDER_KEY] = {
        **transport,
        "headers": {"Authorization": f"Bearer {ctx.api_key}"},
        "alwaysAllow": ["skore_agent"],
        "disabled": False,
    }
    config["mcpServers"] = servers
    config_path.write_text(json.dumps(config, indent=2) + "\n")
    ensure_gitignore_entry(ctx.workspace, ".bob/mcp.json")

    console.print(f"[skore.ok]+[/] wrote [skore.path]{config_path}[/]")
    return {"config_path": str(config_path)}


def _configure_bob_shell(ctx: HarnessContext) -> dict[str, Any]:
    """Configure Bob Shell, which reads a streamable-HTTP server from ``httpURL``."""
    # A plain `url` would be read as the legacy SSE endpoint, which the hub does
    # not serve.
    return _configure_bob(ctx, {"httpURL": ctx.mcp_url})


def _configure_bob_ide(ctx: HarnessContext) -> dict[str, Any]:
    """Configure Bob IDE, which reads a streamable-HTTP server from ``type``/``url``."""
    from skore_cli._style import action_required

    written = _configure_bob(ctx, {"type": "streamable-http", "url": ctx.mcp_url})
    action_required(
        f"raise the network timeout for [skore.warn]{SKORE_PROVIDER_KEY}[/] to "
        "5 minutes under Settings -> MCP; a turn can outlast the 1 minute default."
    )
    return written


def _launch_bob_shell(_workspace: Path, _model_id: str) -> None:
    _process._exec_harness("bob", ["bob"])


def _launch_bob_ide(workspace: Path, _model_id: str) -> None:
    if _process.sys.platform == "darwin":
        _process._exec_harness(
            "open",
            ["open", "-a", str(BOB_IDE_APP_PATH), str(workspace)],
        )
    else:
        _process._exec_harness("bobide", ["bobide", str(workspace)])
