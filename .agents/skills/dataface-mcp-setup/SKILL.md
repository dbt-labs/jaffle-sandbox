---
name: dataface-mcp-setup
kind: workflow
surfaces: [cli]
description: >
  Set up the Dataface MCP server for AI assistant integration. Use when
  running 'dft init mcp', installing Dataface, configuring MCP for Cursor,
  Claude Desktop, VS Code, Codex, Copilot, or any MCP-compatible client,
  or troubleshooting MCP connection issues like 'server not starting',
  'tools not appearing', 'MCP requires additional dependencies'. Do NOT
  use for building dashboards (use dashboard-build). Do NOT
  use for dashboard errors (use dataface-troubleshooting).
metadata:
  author: fivetran
---
# Configuring Dataface MCP Server

Set up the Dataface MCP server to give AI assistants access to dashboard tools and resources.

> This skill is **CLI-only** (`surfaces: [cli]`) — it walks a human operator
> through installing the MCP server from a shell. An already-connected MCP
> agent does not need to read it.

## Quick Setup

The fastest way — auto-detects your AI clients and configures them:

```bash
pip install "dataface[mcp]"
dft init mcp
```

This detects Cursor, VS Code, Claude Desktop, Claude Code, Copilot, and Codex, then writes the appropriate config files.

### Target a Specific Client

```bash
dft init mcp cursor       # Configure Cursor only
dft init mcp vscode       # Configure VS Code only
dft init mcp claude       # Configure Claude Desktop only
dft init mcp claude-code  # Configure Claude Code only
dft init mcp codex        # Configure Codex CLI only
dft init mcp copilot      # Configure GitHub Copilot Coding Agent only
dft init mcp --all        # Write every supported config file
dft init mcp print        # Print JSON config to stdout (manual setup)
```

### Force Update

```bash
dft init mcp cursor -f    # Overwrite existing config
```

After running `dft init mcp`, restart your AI client for changes to take effect.

## Manual Configuration

If you prefer manual setup, add this to your client's MCP config.

For JSON-based clients (Cursor, VS Code, Claude Desktop, Claude Code, Copilot):

```json
{
  "mcpServers": {
    "dataface": {
      "command": "/path/to/dft",
      "args": ["mcp", "serve"]
    }
  }
}
```

For Codex (TOML — `.codex/config.toml`):

```toml
[mcp_servers.dataface]
command = "/path/to/dft"
args = ["mcp", "serve"]
```

If your Dataface or dbt project lives in a subdirectory of the workspace your
AI client opens (or the server otherwise won't be launched with cwd at the
project root), append `"--project-dir", "/abs/path/to/your/project"` to `args`.
`dft init mcp` will add this for you when its `--project-dir` flag is used or
when it detects that the workspace and project roots diverge.

Config file locations:
- **Cursor**: `.cursor/mcp.json`
- **VS Code / Copilot agent mode**: `.vscode/mcp.json` with a `servers` root key
- **Claude Desktop**: `~/.config/claude/config.json`
- **Claude Code**: `.mcp.json` at the project root
- **Codex**: `.codex/config.toml` (project must be trusted by Codex) — globally, `~/.codex/config.toml`
- **GitHub Copilot Coding Agent**: `.github/copilot/mcp.json` with a `servers` root key

Use the absolute path to `dft` in the `command` field. Find it with `which dft`.

## Available Tools

After setup, your AI assistant has access to these tools:

| Tool | Purpose |
|------|---------|
| `validate_dashboard` | Fast YAML schema and cross-reference validation — use after every file edit |
| `render_dashboard` | Compile, execute queries, and generate visual HTML/text output |
| `query_face` | Run one named query from a saved face and inspect columns/sample rows |
| `execute_query` | Run ad-hoc SQL queries while exploring data or testing SQL |
| `describe_query` | Return column schema for a SQL string without fetching rows |
| `schema` | Drill the data hierarchy: source → schema → table → column. Use `--json \| jq` at the CLI for ad-hoc cross-cutting queries; use `dft schema -s <kw>` for keyword/predicate corpus search, or `schema(source=S, schema=N, table_search="pattern")` at level 3 to filter the table list by regexp (table name or cached column name match). |
| `schema_search` | Full-text + filter search across the schema corpus (CLI equivalent: `dft schema -s <kw>`) |
| `docs` | Browse the packaged YAML reference corpus offline |
| `list_skills` / `get_skill` | Discover and read packaged Dataface authoring skills — `get_skill` returns the full body including example YAML |

## Available Resources

| Resource | Content |
|----------|---------|
| `dataface://docs/all` | Complete DATAFACE_SYNTAX.md (whole reference, unsliced) |
| `dataface://docs/{topic}` | One H2 section by slug (`cheatsheet`, `face`, `charts`, `queries`, `variables`, `layout`, `errors`) |
| `dataface://guide/dashboard-design` | Dashboard design principles and patterns |
| `dataface://guide/report-design` | Report design principles and narrative structure |
| `dataface://guide/dashboard-build` | Build-test-iterate workflow best practices |
| `dataface://guide/dashboard-review` | Self-review checklist for a finished face |
| `dataface://dashboards` | List of all dashboards in the project |
| `dataface://dashboard/{path}` | YAML content and compiled structure of a specific dashboard |

## Troubleshooting

### "MCP server requires additional dependencies"

Install the MCP extras:

```bash
pip install "dataface[mcp]"
```

### MCP server not starting

1. Verify `dft` is accessible: `which dft`
2. Ensure the path in MCP config is absolute, not relative
3. Check that your Python environment has `dataface[mcp]` installed
4. Try running `dft mcp serve` manually to see error output

### "No AI client directories detected"

`dft init mcp` looks for `.cursor/`, `.codex/`, `.vscode/`, `.github/`, `CLAUDE.md`, `AGENTS.md`, or `~/.config/claude/` to auto-detect clients. If none exist yet, specify the client explicitly:

```bash
dft init mcp cursor
```

### Tools not appearing in AI client

1. Restart the AI client after running `dft init mcp`
2. Verify the config file was written: check `.cursor/mcp.json` or equivalent
3. Ensure the `command` path in the config points to the correct `dft` binary

## Verifying the Setup

After configuration, test by asking your AI assistant:

- "List available data sources" → should invoke `schema` (no args)
- "Show me the database schema" → should invoke `schema(source=...)`
- "Validate this dashboard YAML file" → should invoke `validate_dashboard`

If the assistant doesn't recognize these tools, the MCP server isn't connected — check the troubleshooting steps above.

## Authoring Metadata Convention

When the assistant edits Dataface YAML through MCP tools, require `description` metadata on:

- `queries.*.description`
- `charts.*.description`
- `variables.*.description`
- Layout objects (`rows`/`cols`/`grid.items`/`tabs.items`) where meaningful

This improves downstream AI search/context quality and enables optional UI tooltips.
