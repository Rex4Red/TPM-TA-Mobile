

# Project Memory — TPM-TA-Mobile
> 46 notes | Score threshold: >40

## Safety — Never Run Destructive Commands

> Dangerous commands are actively monitored.
> Critical/high risk commands trigger error notifications in real-time.

- **NEVER** run `rm -rf`, `del /s`, `rmdir`, `format`, or any command that deletes files/directories without EXPLICIT user approval.
- **NEVER** run `DROP TABLE`, `DELETE FROM`, `TRUNCATE`, or any destructive database operation.
- **NEVER** run `git push --force`, `git reset --hard`, or any command that rewrites history.
- **NEVER** run `npm publish`, `docker rm`, `terraform destroy`, or any irreversible deployment/infrastructure command.
- **NEVER** pipe remote scripts to shell (`curl | bash`, `wget | sh`).
- **ALWAYS** ask the user before running commands that modify system state, install packages, or make network requests.
- When in doubt, **show the command first** and wait for approval.

**Stack:** Dart · Flutter · DB: Hive, Supabase

## 📝 NOTE: 1 uncommitted file(s) in working tree.\n\n## Project Standards

- convention in .gitignore
- convention in .gitignore
- convention in .gitignore
- [.windsurfrules] NEVER use TailwindCSS. Only use vanilla CSS.
- [CLAUDE.md] Always add empty states ("No items yet" with call-to-action)
- [CLAUDE.md] Disable submit button during form submission — prevent double-submit
- [CLAUDE.md] Make layouts responsive from the start — mobile-first approach
- [CLAUDE.md] Handle timezone correctly — store UTC, display in user's timezone

## Learned Patterns

- Avoid: Dispose controllers in StatefulWidget.dispose() (seen 2x)
- Agent generates new migration for every change (squash related changes)
- Agent installs packages without checking if already installed

### 📚 Core Framework Rules: [supabase/postgres-best-practices]
# Supabase Postgres Best Practices

Comprehensive performance optimization guide for Postgres, maintained by Supabase. Contains rules across 8 categories, prioritized by impact to guide automated query optimization and schema design.

## When to Apply

Reference these guidelines when:
- Writing SQL queries or designing schemas
- Implementing indexes or query optimization
- Reviewing database performance issues
- Configuring connection pooling or scaling
- Optimizing for Postgres-specific features
- Working with Row-Level Security (RLS)

## Rule Categories by Priority

| Priority | Category | Impact | Prefix |
|----------|----------|--------|--------|
| 1 | Query Performance | CRITICAL | `query-` |
| 2 | Connection Management | CRITICAL | `conn-` |
| 3 | Security & RLS | CRITICAL | `security-` |
| 4 | Schema Design | HIGH | `schema-` |
| 5 | Concurrency & Locking | MEDIUM-HIGH | `lock-` |
| 6 | Data Access Patterns | MEDIUM | `data-` |
| 7 | Monitoring & Diagnostics | LOW-MEDIUM | `monitor-` |
| 8 | Advanced Features | LOW | `advanced-` |

## How to Use

Read individual rule files for detailed explanations and SQL examples:



Each rule file contains:
- Brief explanation of why it m...
(truncated)

- [Flutter/Dart] Use const constructors wherever possible (improves rebuild performance)
- [Flutter/Dart] Dispose controllers in StatefulWidget.dispose()
- [Supabase] Enable Row Level Security (RLS) on all tables
- [Supabase] Use Supabase Auth for authentication (don't build custom auth)

## Available Tools (ON-DEMAND only)
- `sys_core_01(q)` — Deep search when stuck
- `sys_core_05(query)` — Full-text lookup
> Context above IS your context. Do NOT call sys_core_14() at startup.
