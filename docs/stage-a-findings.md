# Stage A findings (research, not shipped in the plugin)

Sources: code.claude.com/docs (plugins, skills, sub-agents, hooks, settings, permissions), read by a haiku agent. UNVERIFIED means no run or primary read yet.

## Plugin capabilities
- Manifest `.claude-plugin/plugin.json`, only `name` required. Components at plugin root: skills/, agents/, hooks/hooks.json, bin/, output-styles/.
- Plugin root CLAUDE.md is not loaded. No rules/ dir. Plugin settings.json keeps only `agent` and `subagentStatusLine`.
- Plugins cannot ship `permissions`, `availableModels` or `env`.
- Plugin agents can pin `model` and `effort`. They ignore `permissionMode`, `hooks`, `mcpServers`.
- Model resolution: Agent-call `model` > agent frontmatter > CLAUDE_CODE_SUBAGENT_MODEL > parent. A caller's model overrides the pin.
- `fable` is a valid alias.
- Manual-only skill: `disable-model-invocation: true` (also hides it from the listing).
- Skill description plus when_to_use is capped at 1,536 chars in the listing.

## Hooks
- PreToolUse input: tool_name, tool_input, cwd, agent_id/agent_type for subagents.
- Block: exit 2 with stderr, or exit 0 with JSON `hookSpecificOutput.permissionDecision: "deny"` plus `permissionDecisionReason`.
- `${CLAUDE_PLUGIN_ROOT}` is available to hook commands. Plugin hooks also run in subagents.
- Agent `model` should appear in tool_input.model for matcher `Agent`. UNVERIFIED by run.
- Deny rules and hooks take precedence over allow. No documented harness to run a hook by hand; pipe JSON to stdin.

## Always-loaded delivery
- Shippable: SessionStart hook `additionalContext`; settings `agent` (replaces the main system prompt); output style (user must activate); skill descriptions.
- Not shippable: CLAUDE.md, .claude/rules, permissions.
- Recommendation: SessionStart hook with the core rules (about 40 lines, once per session). Enable by enabling the plugin; no other step.

## Testing
- `claude --plugin-dir .`, `claude plugin validate . --strict`, `/context`, `/skill-doctor`, `/reload-plugins`, `claude --debug`.

## Odin
- Latest: dev-2026-10 (6 Oct 2026). Installed: dev-2026-09:a2fb372b7. Homebrew 2026-10 bottle UNVERIFIED.
- Core root: /opt/homebrew/Cellar/odin/2026-09/libexec.
- core:mem allocators: nil, panic, arena, scratch, stack, small_stack, dynamic_arena, buddy, compat, mutex, rollback_stack, tracking. Also mem/virtual arena and mem/tlsf.
- 2026-10 notes: mem.Scratch change from #6476 reverted (#7516); bit_set may use integer arrays. 2026-09: multi-line string literals, inline and no_inline removed, comparisons against 0 rejected, Win64 long is int64_t.
- Release page for dev-2026-10 was read only to char 100000 of 109778.
- odin-c-bindgen: last commit 2026-07-27, no maturity label, 423 stars.

## odx
- odx.json pins `dev-2026-10-nightly:84bc3fc`; mise.toml says `dev-2026-10`. README says --version names the mise value. Conflict.
- ADR 0002 describes `odx test` and `odx run` as present; README says planned. Conflict.
- Missing: spec referenced by ADR 0002; error code `format-timeout` is not in the README.
- Old skill SKILL.md line 108 claims odx run and odx test exist (wrong); it also attributes a "strict profile" to odx.
