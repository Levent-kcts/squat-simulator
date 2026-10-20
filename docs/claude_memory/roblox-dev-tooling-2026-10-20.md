---
name: roblox-dev-tooling-2026-10-20
description: "Free dev/video tools installed 2026-10-20 (Rokit toolchain, typecheck.py, official Studio MCP, UI Labs, OBS, CapCut) and when to use them"
metadata:
  node_type: memory
  type: project
  originSessionId: 344cd710-ea0c-4a77-8827-843b2486537d
  modified: 2026-10-19T23:12:23.734Z
---

On 2026-10-20 the owner asked to install every free tool rated above 6/10 and to use them in future work.
Installed: rokit tools (selene, StyLua, lune, wally, luau-lsp), VS Code Luau LSP/Selene/StyLua extensions, `tools/typecheck.py` (luau-lsp with real Roblox types + Selene; luau-lsp cannot open the non-ASCII 'Masaüstü' path, so the script copies src to a temp ASCII dir), `.mcp.json` pointing Claude Code at Studio's built-in MCP (`%LOCALAPPDATA%\Roblox\mcp.bat`; handshake verified), UI Labs plugin in `%LOCALAPPDATA%\Roblox\Plugins`, OBS + CapCut via winget. NVIDIA App was already there.
Not installed: community MCPs (boshyxd archived, Meganugger untrusted), Moon Animator 2 (paid), DaVinci Resolve (needs Blackmagic form, owner downloads), F3X/Archimedes (owner gets them from Creator Store with their account).

**Why:** owner wants Claude to use these tools by itself instead of leaving all Studio checks to them.
**How to apply:** use `py` (no `python` on PATH); run typecheck.py after Roblox-API changes; when the Roblox_Studio MCP tools are available, playtest, read Output and take screenshots yourself. Studio MCP was enabled 2026-10-20 (Assistant panel > … > Ayarlar > MCP Sunucuları). If the session has no Roblox_Studio tools, use `py -I tools/studio_mcp.py` from Bash (call/lua/list); the Assistant button is the top-right sparkle icon in the Turkish Studio. Live stats 2026-10-20: 18 visits total, 0 playing, 2 likes; thumbnails/icon/badges/event done, no video yet. Related: [[roblox-mocktest-tool]], [[roblox-video-shoot-2026-10-19]].

GRAPHIFY (2026-10-20): knowledge graph at graphify-out/ (graph.json, GRAPH_REPORT.md, graph.html). It covers code, CLAUDE.md, README, plans, research and a memory copy in docs/claude_memory/.
- Before a codebase question, run `graphify query "..."` (CLI in ~/.local/bin; in bash, `export PATH="$HOME/.local/bin:$PATH"`).
- After code edits, run `graphify update .`.
- When memory notes change, re-copy them into docs/claude_memory/.
- To rebuild semantics, run `/graphify --update`.
