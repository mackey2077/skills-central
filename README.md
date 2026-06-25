# skills-central

> One skills folder to rule them all — zero daemon, zero overhead, zero config.

Unify AI skills across multiple tools (Trae, Kiro, Codex, Doubao, CC Switch, WorkBuddy, etc.) using **NTFS Directory Junctions**. No sync daemon, no background process, no runtime dependency — just the file system doing what it's designed to do.

## Why not a skill manager?

Existing solutions add a software layer (daemon / service / tray app) to keep folders in sync. `skills-central` takes a different approach:

| | skills-central | Typical skill manager |
|---|---|---|
| **Runtime** | **Zero** — no process needed | Daemon / background service |
| **Sync latency** | **Instant** — same filesystem write | Polling or event listener |
| **Failure mode** | **None** — OS-native mechanism | Daemon crash = no sync |
| **Boot persistence** | **Permanent** — survives reboots | Must register as startup service |
| **Rollback** | Delete Junction + rename backup | Stop service + cleanup |
| **Setup** | One command, done forever | Install + configure + autostart |

The key insight: instead of *adding software to sync folders*, let the *filesystem itself unify them*. Junctions are an NTFS kernel-level feature — they don't depend on any process, don't add latency, and can't crash.

## How it works

Each AI tool stores its skills in a dedicated folder (e.g. `~/.trae-cn/skills`, `~/.kiro/skills`). Normally these are isolated, so installing a skill in one tool doesn't make it available in others.

`skills-central` replaces each tool's skills folder with an NTFS **Junction** (directory symlink) pointing to a single central folder. After setup, all tools share the same skills — install once, use everywhere.

```
~/.trae-cn/skills  ──┐
~/.kiro/skills     ──┤
~/.codex/skills    ──┼──►  your-central-folder\  (all skills here)
~/.doubao/skills   ──┤
~/.agents/skills   ──┤
~/.workbuddy/skills──┘
```

## Requirements

- Windows 10/11
- PowerShell 5+
- No admin rights needed (NTFS Junctions work without elevation)

## Quick Start

```powershell
# 1. Clone the repo
git clone https://github.com/mackey2077/skills-central.git
cd skills-central

# 2. Run setup (merges existing skills + creates Junctions)
.\scripts\setup.ps1 -Dest "D:\my-skills"
```

Restart your AI tools — they'll all see the unified skill list.

## Scripts

| Script | What it does |
|--------|-------------|
| `scripts\merge.ps1` | Scans all tool skill folders, copies unique skills to central folder |
| `scripts\link.ps1` | Replaces each tool's skills folder with a Junction |
| `scripts\setup.ps1` | Runs merge + link in one step |

## Supported Tools

Auto-detected under `$env:USERPROFILE`:

| Tool | Path |
|------|------|
| Trae / Trae CN | `.trae-cn\skills` |
| Kiro | `.kiro\skills` |
| Codex | `.codex\skills` |
| Doubao | `.doubao\skills` |
| CC Switch | `.cc-switch\skills` |
| WorkBuddy | `.workbuddy\skills` |
| Agents (npx skills) | `.agents\skills` |

To add more tools, edit the `$TOOLS` array in `scripts\link.ps1`.

## Safety

Original folders are renamed to `skills_backup` before any Junction is created — nothing is deleted.

To revert a single tool:
```powershell
Remove-Item "$env:USERPROFILE\.kiro\skills"
Rename-Item "$env:USERPROFILE\.kiro\skills_backup" "skills"
```

## After Setup

Skills installed in any tool are written directly to the central folder and become available to all other tools immediately (after tool restart).

Verify new installs land in the central folder:
```powershell
Get-ChildItem "D:\my-skills" | Sort-Object LastWriteTime -Descending | Select-Object -First 5 Name, LastWriteTime
```

## License

MIT
