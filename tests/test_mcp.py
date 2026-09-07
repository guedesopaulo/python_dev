"""Tests for the MCP server auto-generated from the FastAPI routes.

The tools call back into the FastAPI app over HTTP, so these also guard the auth wiring:
without a Bearer token on that loopback request, every tool call fails with 401.
"""

from fastmcp import Client


async def test_list_tools_when_called_exposes_echo_tool() -> None:
    from src.main import mcp

    async with Client(mcp) as mcp_client:
        tools = await mcp_client.list_tools()

    assert [t.name for t in tools] == ["echo_echo_get"]


async def test_call_tool_when_authenticated_returns_echoed_message() -> None:
    from src.main import mcp

    async with Client(mcp) as mcp_client:
        result = await mcp_client.call_tool("echo_echo_get", {"message": "hello-mcp"})

    assert result.is_error is False
    assert result.content[0].text == '{"message":"hello-mcp"}'
