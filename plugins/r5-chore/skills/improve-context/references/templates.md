# Templates

## Findings log
One row per issue.

| ID | Sev | Location | Category | Evidence | Fix |
| --- | --- | --- | --- | --- | --- |
| F1 | high | CLAUDE.md:42 | Contradiction | says `npm test`; package.json has `pnpm test` | use `pnpm test` |

Severity: critical = causes unsafe or wrong code. high = misleads or always-loaded over limit. med = costs tokens or clarity. low = polish.

## Inventory row

| Path | Purpose | Lines | Chars | Modified | Loaded |
| --- | --- | --- | --- | --- | --- |
| CLAUDE.md | root rules | 210 | 9400 | 2026-10-01 | always |

## Plan file

```
# Context audit plan
## 1. Summary
Current state, top risks, expected gain (10 lines at most).
## 2. Findings
Findings log table.
## 3. Proposed doc architecture
Target files, what lives where, always-loaded vs on-demand, canonical-source map (fact -> file), size per file (150 lines / 16,000 chars at most).
## 4. Change list per file
| File | Action (keep/rewrite/merge/split/delete/add) | Lines before->after | Chars before->after | Drafted by |
## 5. Rewrite principles
See references/rewrite-checklist.md.
## 6. Open questions and assumptions
## 7. Risks and rollback
Backup location, how to revert.
## 8. Verification
Commands run, paths exist, no contradictions, size limits met.
```

## Agent brief

```
Role: <read | analyze | verify | research | draft>
Model: Sonnet or Haiku only
Scope: <one doc, one directory, or one research angle>
Read-only: do not edit, create or delete anything. (Drafters: write only <file>, and only after approval.)
Task: <one sentence>
Return: at most 200 words, or findings as `file:line | category | severity | evidence | fix`. Mark unverified claims.
```
