# skills-central

[English](README.md)

> 一个技能文件夹，统一所有工具——零守护进程、零开销、零配置。

使用 NTFS **目录联接（Junction）** 跨工具（Trae、Kiro、Codex、Doubao、CC Switch、WorkBuddy 等）统一 AI 技能。不需要同步守护进程，不需要后台服务，不需要运行时依赖——让文件系统做它本就该做的事。

## 为什么不做一个技能管理器？

现有方案通常加一层软件（守护进程 / 服务 / 托盘应用）来保持文件夹同步。`skills-central` 走的是另一条路：

| | skills-central | 典型技能管理器 |
|---|---|---|
| **运行时** | **零** — 不需要任何进程 | 守护进程 / 后台服务 |
| **同步延迟** | **即时** — 同一次文件系统写入 | 轮询或事件监听 |
| **故障模式** | **没有** — 操作系统原生机制 | 守护进程崩溃 = 不同步 |
| **开机持久化** | **永久** — 重启不丢 | 必须注册为自启动服务 |
| **回滚** | 删 Junction + 改名备份 | 停服务 + 清理 |
| **安装** | 一条命令，永远生效 | 安装 + 配置 + 自启动 |

核心思路：**与其"加软件来同步文件夹"，不如让"文件系统自己统一它们"**。Junction 是 NTFS 内核级特性——不依赖任何进程，没有延迟，不会崩溃。

## 工作原理

每个 AI 工具都有自己的技能目录（比如 `~/.trae-cn/skills`、`~/.kiro/skills`）。默认情况下这些目录相互隔离，在 A 工具装的技能 B 工具看不到。

`skills-central` 把每个工具的技能目录替换为一个 NTFS **Junction**（目录符号链接），全部指向同一个中央文件夹。配置完之后所有工具共享同一份技能——装一次，处处可用。

```
~/.trae-cn/skills   ──┐
~/.kiro/skills      ──┤
~/.codex/skills     ──┼──►  你的中央文件夹\  （所有技能都在这）
~/.doubao/skills    ──┤
~/.agents/skills    ──┤
~/.workbuddy/skills ──┘
```

## 环境要求

- Windows 10 / 11
- PowerShell 5+
- 无需管理员权限（NTFS Junction 不需要提权）

## 快速开始

```powershell
# 1. 克隆仓库
git clone https://github.com/mackey2077/skills-central.git
cd skills-central

# 2. 执行安装（合并现有技能 + 创建 Junction）
.\scripts\setup.ps1 -Dest "D:\my-skills"
```

重启你的 AI 工具——它们都能看到统一的技能列表。

## 脚本说明

| 脚本 | 作用 |
|---|---|
| `scripts\merge.ps1` | 扫描所有工具的技能目录，把去重后的唯一技能复制到中央文件夹 |
| `scripts\link.ps1` | 把每个工具的技能目录替换成指向中央文件夹的 Junction |
| `scripts\setup.ps1` | 一步完成合并 + 链接 |

## 支持的工具

自动检测 `$env:USERPROFILE` 下的目录：

| 工具 | 路径 |
|---|---|
| Trae / Trae CN | `.trae-cn\skills` |
| Kiro | `.kiro\skills` |
| Codex | `.codex\skills` |
| Doubao | `.doubao\skills` |
| CC Switch | `.cc-switch\skills` |
| WorkBuddy | `.workbuddy\skills` |
| Agents（npx skills） | `.agents\skills` |

要新增工具，编辑 `scripts\link.ps1` 里的 `$TOOLS` 数组。

## 安全性

替换之前会把原目录改名为 `skills_backup`——不会删除任何文件。

回滚单个工具：
```powershell
Remove-Item "$env:USERPROFILE\.kiro\skills"
Rename-Item "$env:USERPROFILE\.kiro\skills_backup" "skills"
```

## 安装后

任何工具里新装的技能都会直接写到中央文件夹，并立刻对其他工具生效（工具重启后）。

查看最近装了哪些技能：
```powershell
Get-ChildItem "D:\my-skills" | Sort-Object LastWriteTime -Descending | Select-Object -First 5 Name, LastWriteTime
```

## 许可证

MIT
