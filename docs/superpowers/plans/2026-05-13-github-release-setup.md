# Keep It Simple — GitHub & Modrinth Release Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Keep It Simple modpack repo public-ready with a professional README, contributing docs, legal files, a pack logo, dynamic mod-count badges, and a GHA workflow that publishes changed pack versions to Modrinth on every semver tag.

**Architecture:** Static files (LICENSE, CHANGELOG, CONTRIBUTING, DISCLAIMERS, README) created directly; badge JSONs committed under `.github/badges/` and kept current by a `badges.yml` GHA that runs on pushes to `main`; `publish.yml` GHA fires on `v*.*.*` tags, diffs each `Packwiz/<version>/` directory against the previous tag, builds only the changed `.mrpack` files via the packwiz CLI, creates a GitHub Release, and uploads each changed version to Modrinth via the REST API.

**Tech Stack:** Git, GitHub Actions (ubuntu-latest), packwiz CLI, Shields.io endpoint badges, Modrinth API v2, `softprops/action-gh-release@v2`, `jq`, `curl`

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `assets/kis_modpack_sq.png` | Create | Pack logo (copy from Downloads) |
| `Packwiz/1.20.1/pack.png` | Create | Pack icon included in mrpack export |
| `Packwiz/1.21.1/pack.png` | Create | Pack icon |
| `Packwiz/1.21.4/pack.png` | Create | Pack icon |
| `Packwiz/1.21.11/pack.png` | Create | Pack icon |
| `Packwiz/26.1.2/pack.png` | Create | Pack icon |
| `LICENSE` | Create | MIT license |
| `CHANGELOG.md` | Create | Keep a Changelog format, v0.1.0 initial entry |
| `DISCLAIMERS.md` | Create | Attribution, anticheat warning, no warranty, forking |
| `CONTRIBUTING.md` | Create | packwiz CLI workflow, versioning convention, branch naming |
| `README.md` | Rewrite | Logo, badges, install instructions, contributing blurb |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | Create | Structured bug report form |
| `.github/ISSUE_TEMPLATE/mod_request.yml` | Create | Structured mod request form |
| `.github/pull_request_template.md` | Create | PR checklist |
| `.github/badges/1.20.1.json` | Create | Shields.io endpoint payload — initial count |
| `.github/badges/1.21.1.json` | Create | Shields.io endpoint payload — initial count |
| `.github/badges/1.21.4.json` | Create | Shields.io endpoint payload — initial count |
| `.github/badges/1.21.11.json` | Create | Shields.io endpoint payload — initial count |
| `.github/badges/26.1.2.json` | Create | Shields.io endpoint payload — initial count |
| `.github/workflows/badges.yml` | Create | Auto-update badge JSONs on push to main |
| `.github/workflows/publish.yml` | Create | Build mrpacks + GitHub Release + Modrinth upload on tag |

---

## Task 1: Initialize git repository

**Files:** none (git metadata only)

- [ ] **Step 1: Init and set remote**

```powershell
cd D:\mc_mods\keep-it-simple
git init -b main
git remote add origin git@github.com:MisterVitoPro/keep-it-simple-modpack.git
```

- [ ] **Step 2: Verify**

```powershell
git remote -v
```

Expected output:
```
origin  git@github.com:MisterVitoPro/keep-it-simple-modpack.git (fetch)
origin  git@github.com:MisterVitoPro/keep-it-simple-modpack.git (push)
```

---

## Task 2: Add pack logo and Packwiz pack icons

**Files:**
- Create: `assets/kis_modpack_sq.png`
- Create: `Packwiz/1.20.1/pack.png`, `Packwiz/1.21.1/pack.png`, `Packwiz/1.21.4/pack.png`, `Packwiz/1.21.11/pack.png`, `Packwiz/26.1.2/pack.png`

packwiz automatically includes `pack.png` from the pack root directory in `.mrpack` exports as the pack icon — no `packwiz refresh` needed.

- [ ] **Step 1: Create assets directory and copy logo**

```powershell
New-Item -ItemType Directory -Force -Path assets
Copy-Item "$env:USERPROFILE\Downloads\kis_modpack_sq.png" -Destination "assets\kis_modpack_sq.png"
```

- [ ] **Step 2: Copy as pack icon into each Packwiz version**

```powershell
foreach ($v in @('1.20.1','1.21.1','1.21.4','1.21.11','26.1.2')) {
    Copy-Item "assets\kis_modpack_sq.png" -Destination "Packwiz\$v\pack.png"
}
```

- [ ] **Step 3: Verify all files exist**

```powershell
Get-Item assets\kis_modpack_sq.png
foreach ($v in @('1.20.1','1.21.1','1.21.4','1.21.11','26.1.2')) {
    Get-Item "Packwiz\$v\pack.png"
}
```

Expected: each `Get-Item` returns the file without error.

---

## Task 3: Create LICENSE

**Files:**
- Create: `LICENSE`

- [ ] **Step 1: Write LICENSE**

```
MIT License

Copyright (c) 2026 MisterVitoPro

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

Write as UTF-8 without BOM:
```powershell
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText(
    (Join-Path (Get-Location) 'LICENSE'),
    (Get-Content docs\superpowers\plans\2026-05-13-github-release-setup.md -Raw | Select-String -Pattern 'PLACEHOLDER' | Out-Null; "MIT License`n`nCopyright (c) 2026 MisterVitoPro`n`nPermission is hereby granted, free of charge, to any person obtaining a copy`nof this software and associated documentation files (the `"Software`"), to deal`nin the Software without restriction, including without limitation the rights`nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell`ncopies of the Software, and to permit persons to whom the Software is`nfurnished to do so, subject to the following conditions:`n`nThe above copyright notice and this permission notice shall be included in all`ncopies or substantial portions of the Software.`n`nTHE SOFTWARE IS PROVIDED `"AS IS`", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR`nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,`nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE`nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER`nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,`nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE`nSOFTWARE.`n"),
    $utf8NoBom
)
```

> Alternatively, use the Write tool directly — it handles encoding correctly.

- [ ] **Step 2: Verify**

```powershell
Get-Content LICENSE | Select-Object -First 3
```

Expected:
```
MIT License

Copyright (c) 2026 MisterVitoPro
```

---

## Task 4: Create CHANGELOG.md

**Files:**
- Create: `CHANGELOG.md`

The `publish.yml` workflow extracts the release body by reading lines between the first `## [x.y.z]` heading and the next `## [` heading. Keep this format intact on every update.

- [ ] **Step 1: Write CHANGELOG.md**

Full file content:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] — 2026-05-13

Initial release. Supports Minecraft 1.20.1, 1.21.1, 1.21.4, 1.21.11, and 26.1.2 on Fabric.

### Optimizations

- Distant Horizons — extended render distance without the FPS cost
- Dynamic FPS — throttles rendering when the game is in the background
- Entity Culling — skips rendering entities outside the player's view
- FerriteCore — reduces memory usage of block state and world data
- ImmediatelyFast — speeds up immediate-mode rendering
- Krypton — optimises the Minecraft networking stack
- Language Reload — faster language switching and fallback support
- Lithium — broad game-logic optimisations (AI, ticking, world gen)
- More Culling — additional culling passes for blocks and foliage
- Packet Fixer — fixes oversized packet and NBT issues
- Sodium — rewrites the chunk renderer for dramatically higher FPS
- Sodium Extra — extra Sodium settings that don't belong in Sodium itself

### Visual

- [EMF] Entity Model Features — OptiFine-compatible custom entity model support
- [ETF] Entity Texture Features — emissive, random, and custom entity textures
- AppleSkin — food and hunger HUD improvements
- Iris Shaders — OptiFine-compatible shader pack loader
- LambDynamicLights — dynamic lighting from held and dropped items
- Make Bubbles Pop — realistic bubble particle behaviour
- Not Enough Animations — first-person animations visible in third-person

### Utility

- Boat Item View — held items visible while in a boat
- Enchantment Descriptions — shows descriptions on enchanted books
- Jade — block and entity information overlay (Hwyla/Waila fork)
- Sound Physics Remastered — realistic sound attenuation and reverberation
- Xaero's Minimap — in-world minimap with waypoint support

### Functional

- Clumps — merges XP orbs to reduce entity count and lag

### Libraries

- Bookshelf — open-source library (1.20.1 and 1.21.1 only)
- Cloth Config API — configuration library
- Fabric API — core Fabric hooks and interop
- Fabric Language Kotlin — Kotlin language support for Fabric mods
- Prickle — JSON-based config format (1.21.1+)
- YetAnotherConfigLib (YACL) — builder-based configuration library
```

Write with UTF-8 no-BOM using the Write tool.

- [ ] **Step 2: Verify format**

```powershell
(Get-Content CHANGELOG.md | Select-String '## \[').Line
```

Expected:
```
## [0.1.0] — 2026-05-13
```

---

## Task 5: Create DISCLAIMERS.md

**Files:**
- Create: `DISCLAIMERS.md`

- [ ] **Step 1: Write DISCLAIMERS.md**

Full file content:

```markdown
# Disclaimers

## Not an Official Minecraft Product

Keep It Simple is not affiliated with, endorsed by, or associated with Mojang Studios or Microsoft. "Minecraft" is a trademark of Mojang Studios.

## Mod Attribution

All mods included in this modpack are the property of their respective authors and are distributed under their own licenses. Keep It Simple packages them for convenience and makes no claim over any mod's code, assets, or intellectual property.

A full list of included mods and their authors is available in [MODS-LIST.md](MODS-LIST.md). Links to each mod's Modrinth project page (and original license) are included there.

## Server Compatibility

Some mods in this pack — particularly visual and rendering mods such as Entity Culling, Iris Shaders, Entity Model Features, and Entity Texture Features — may be detected by server-side anti-cheat software as unauthorised clients.

Before using this modpack on a public or private multiplayer server, verify compatibility with the server operators. The authors of Keep It Simple accept no responsibility for bans, restrictions, or penalties resulting from its use on third-party servers.

## No Warranty

This modpack is provided "as is", without warranty of any kind, express or implied, including but not limited to warranties of merchantability, fitness for a particular purpose, or non-infringement. The authors make no guarantees regarding stability, compatibility, or fitness for any particular use. Use at your own risk.

See the [MIT License](LICENSE) for the full terms.

## Forking

You are free to fork and redistribute this modpack under the terms of the [MIT License](LICENSE).

If you publish a derivative, do not represent it as the original Keep It Simple modpack. You may credit it as a fork of Keep It Simple, but the name and logo must not be used in a way that implies it is the official project.
```

- [ ] **Step 2: Verify section headings**

```powershell
(Get-Content DISCLAIMERS.md | Select-String '^## ').Line
```

Expected:
```
## Not an Official Minecraft Product
## Mod Attribution
## Server Compatibility
## No Warranty
## Forking
```

---

## Task 6: Create CONTRIBUTING.md

**Files:**
- Create: `CONTRIBUTING.md`

- [ ] **Step 1: Write CONTRIBUTING.md**

Full file content:

```markdown
# Contributing

## Prerequisites

- [packwiz](https://packwiz.infra.link) — modpack management tool (Go binary)
- PowerShell 5.1 or later
- Java 21+ (Java 25 required for 26.1.2)
- [Pester 5](https://pester.dev/docs/introduction/installation) — for unit tests

## Adding or Updating a Mod

1. Fork this repository and clone your fork.
2. Create a branch:

   ```powershell
   git checkout -b add/<mod-slug>
   ```

3. For each MC version you want to support, add the mod via packwiz:

   ```powershell
   cd Packwiz\1.21.4
   packwiz mr add https://modrinth.com/mod/<slug>
   ```

   Repeat for other versions as applicable.

4. Run the unit tests:

   ```powershell
   .\tests\Pester.Run.ps1 -ExcludeIntegration
   ```

   All tests must pass before opening a PR.

5. Update `MODS-LIST.md` — add the mod in the correct category table and tick each version you added it to.

6. Add a line to `CHANGELOG.md` under a `## [Unreleased]` section at the top.

7. Open a pull request. The PR template will walk you through the checklist.

## Running Unit Tests

No server or client environment required:

```powershell
.\tests\Pester.Run.ps1 -ExcludeIntegration
```

## Integration Tests (optional)

Integration tests boot real Fabric servers to validate mod compatibility. See the **Development** section of [README.md](README.md) for setup instructions.

## Versioning

This project follows [Semantic Versioning](https://semver.org). Git releases are tagged `vMAJOR.MINOR.PATCH`.

| Bump | When |
|------|------|
| PATCH | Mod version updates only, no additions or removals |
| MINOR | Mods added or removed, or new MC version added |
| MAJOR | Breaking change or complete overhaul |

## Branch Naming

| Type | Pattern | Example |
|------|---------|---------|
| Add a mod | `add/<mod-slug>` | `add/starlight` |
| Update a mod | `update/<mod-slug>` | `update/sodium` |
| Fix something | `fix/<description>` | `fix/1.21.4-crash` |
| Add MC version | `version/<mc-version>` | `version/1.22` |

## Disclaimers

See [DISCLAIMERS.md](DISCLAIMERS.md) for information about mod licensing, server compatibility, and forking.
```

- [ ] **Step 2: Verify**

```powershell
(Get-Content CONTRIBUTING.md | Select-String '^## ').Line
```

Expected:
```
## Prerequisites
## Adding or Updating a Mod
## Running Unit Tests
## Integration Tests (optional)
## Versioning
## Branch Naming
## Disclaimers
```

---

## Task 7: Create GitHub issue templates and PR template

**Files:**
- Create: `.github/ISSUE_TEMPLATE/bug_report.yml`
- Create: `.github/ISSUE_TEMPLATE/mod_request.yml`
- Create: `.github/pull_request_template.md`

- [ ] **Step 1: Create template directories**

```powershell
New-Item -ItemType Directory -Force -Path .github\ISSUE_TEMPLATE
```

- [ ] **Step 2: Write bug_report.yml**

```yaml
name: Bug Report
description: Report a problem with the modpack
labels: ["bug"]
body:
  - type: dropdown
    id: mc-version
    attributes:
      label: Minecraft Version
      options:
        - "1.20.1"
        - "1.21.1"
        - "1.21.4"
        - "1.21.11"
        - "26.1.2"
    validations:
      required: true
  - type: input
    id: fabric-loader
    attributes:
      label: Fabric Loader Version
      placeholder: "e.g. 0.19.2"
    validations:
      required: true
  - type: textarea
    id: description
    attributes:
      label: Describe the bug
    validations:
      required: true
  - type: textarea
    id: steps
    attributes:
      label: Steps to reproduce
      placeholder: |
        1. Launch the game
        2. ...
    validations:
      required: true
  - type: textarea
    id: expected
    attributes:
      label: Expected behaviour
    validations:
      required: true
  - type: textarea
    id: actual
    attributes:
      label: Actual behaviour
    validations:
      required: true
  - type: textarea
    id: logs
    attributes:
      label: Crash log or relevant output (if any)
      render: text
```

- [ ] **Step 3: Write mod_request.yml**

```yaml
name: Mod Request
description: Request a mod to be added to the pack
labels: ["mod-request"]
body:
  - type: input
    id: mod-name
    attributes:
      label: Mod name
    validations:
      required: true
  - type: input
    id: modrinth-url
    attributes:
      label: Modrinth URL
      placeholder: "https://modrinth.com/mod/..."
    validations:
      required: true
  - type: checkboxes
    id: mc-versions
    attributes:
      label: Target MC versions
      options:
        - label: "1.20.1"
        - label: "1.21.1"
        - label: "1.21.4"
        - label: "1.21.11"
        - label: "26.1.2"
  - type: dropdown
    id: category
    attributes:
      label: Category
      options:
        - Optimizations
        - Visual
        - Utility
        - Functional
        - Libraries
    validations:
      required: true
  - type: textarea
    id: why
    attributes:
      label: Why does this fit the pack?
      description: >
        Keep It Simple focuses on performance, visual enhancements, and
        vanilla-compatible quality-of-life improvements. Heavy gameplay
        changes are out of scope.
    validations:
      required: true
  - type: checkboxes
    id: checks
    attributes:
      label: Checklist
      options:
        - label: The mod is available on Modrinth
          required: true
        - label: The mod is Fabric-compatible
          required: true
        - label: The mod does not significantly alter vanilla gameplay
          required: true
```

- [ ] **Step 4: Write pull_request_template.md**

```markdown
## Summary

<!-- What does this PR do? -->

## Checklist

- [ ] Tested on a server for the affected MC version(s), or N/A (explain below)
- [ ] `MODS-LIST.md` updated
- [ ] `CHANGELOG.md` entry added under `## [Unreleased]`
- [ ] Unit tests pass (`.\tests\Pester.Run.ps1 -ExcludeIntegration`)
- [ ] No new errors or exceptions in the boot log

**N/A reason** (if applicable):
```

- [ ] **Step 5: Verify files exist**

```powershell
Get-Item .github\ISSUE_TEMPLATE\bug_report.yml
Get-Item .github\ISSUE_TEMPLATE\mod_request.yml
Get-Item .github\pull_request_template.md
```

---

## Task 8: Create initial badge JSONs

**Files:**
- Create: `.github/badges/1.20.1.json` through `26.1.2.json`

Current mod counts (from `Packwiz/*/mods/*.pw.toml` file count):
- 1.20.1 → 30 mods
- 1.21.1 → 31 mods
- 1.21.4 → 30 mods
- 1.21.11 → 30 mods
- 26.1.2 → 30 mods

Each file is a [Shields.io endpoint payload](https://shields.io/endpoint).

- [ ] **Step 1: Create badges directory**

```powershell
New-Item -ItemType Directory -Force -Path .github\badges
```

- [ ] **Step 2: Write badge JSONs**

Write each file with UTF-8 no-BOM. Content for each:

`.github/badges/1.20.1.json`:
```json
{
  "schemaVersion": 1,
  "label": "1.20.1",
  "message": "30 mods",
  "color": "blue"
}
```

`.github/badges/1.21.1.json`:
```json
{
  "schemaVersion": 1,
  "label": "1.21.1",
  "message": "31 mods",
  "color": "blue"
}
```

`.github/badges/1.21.4.json`:
```json
{
  "schemaVersion": 1,
  "label": "1.21.4",
  "message": "30 mods",
  "color": "blue"
}
```

`.github/badges/1.21.11.json`:
```json
{
  "schemaVersion": 1,
  "label": "1.21.11",
  "message": "30 mods",
  "color": "blue"
}
```

`.github/badges/26.1.2.json`:
```json
{
  "schemaVersion": 1,
  "label": "26.1.2",
  "message": "30 mods",
  "color": "blue"
}
```

- [ ] **Step 3: Verify counts match filesystem**

```powershell
foreach ($v in @('1.20.1','1.21.1','1.21.4','1.21.11','26.1.2')) {
    $count = (Get-ChildItem "Packwiz\$v\mods" -Filter '*.pw.toml').Count
    $json  = Get-Content ".github\badges\$v.json" | ConvertFrom-Json
    $msg   = $json.message
    Write-Host "$v : filesystem=$count  badge=$msg"
}
```

Expected: each line shows the filesystem count matching the number in the badge message.

---

## Task 9: Rewrite README.md

**Files:**
- Modify: `README.md`

Before writing, verify the Fabric Loader versions in each `Packwiz/*/pack.toml`:

```powershell
foreach ($v in @('1.20.1','1.21.1','1.21.4','1.21.11','26.1.2')) {
    $fabric = (Get-Content "Packwiz\$v\pack.toml" | Select-String 'fabric = ').ToString().Trim()
    Write-Host "$v : $fabric"
}
```

Use those values in the supported versions table below.

- [ ] **Step 1: Write README.md**

Full file content (replace Fabric Loader versions with values from the command above if they differ):

```markdown
<div align="center">
  <img src="assets/kis_modpack_sq.png" alt="Keep It Simple Modpack" width="256">

  # Keep It Simple

  A lightweight Fabric performance modpack for Minecraft.

  [![Version](https://img.shields.io/badge/version-v0.1.0-blue)](https://github.com/MisterVitoPro/keep-it-simple-modpack/releases)
  [![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
  [![1.20.1](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/MisterVitoPro/keep-it-simple-modpack/main/.github/badges/1.20.1.json&label=1.20.1)](MODS-LIST.md)
  [![1.21.1](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/MisterVitoPro/keep-it-simple-modpack/main/.github/badges/1.21.1.json&label=1.21.1)](MODS-LIST.md)
  [![1.21.4](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/MisterVitoPro/keep-it-simple-modpack/main/.github/badges/1.21.4.json&label=1.21.4)](MODS-LIST.md)
  [![1.21.11](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/MisterVitoPro/keep-it-simple-modpack/main/.github/badges/1.21.11.json&label=1.21.11)](MODS-LIST.md)
  [![26.1.2](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/MisterVitoPro/keep-it-simple-modpack/main/.github/badges/26.1.2.json&label=26.1.2)](MODS-LIST.md)
</div>

[Overview](README.md) · [Mods List](MODS-LIST.md) · [Changelog](CHANGELOG.md)

Ships only well-maintained, conflict-free mods that improve FPS, memory, and network performance — without changing vanilla gameplay. No magic configuration required: import the pack and play.

## Supported Versions

| Minecraft | Fabric Loader |
| --- | --- |
| 1.20.1 | 0.19.2 |
| 1.21.1 | 0.16.14 |
| 1.21.4 | 0.19.2 |
| 1.21.11 | 0.19.2 |
| 26.1.2 | 0.19.2 |

## Install

### Modrinth (recommended)

Find the latest release on [Modrinth](https://modrinth.com/modpack/keep-it-simple) or download the `.mrpack` from the [Releases](../../releases) page and import it into your launcher (Prism Launcher, ATLauncher, MultiMC).

### CurseForge

Download the `.zip` from the [Releases](../../releases) page and import it via the CurseForge App.

## Mods

See [MODS-LIST.md](MODS-LIST.md) for the complete list of included mods, their categories, and which Minecraft versions each one supports.

## Contributing

Contributions are welcome — new mods, version updates, bug reports. See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow.

## Development

**Requirements:** PowerShell 5.1, [packwiz](https://packwiz.infra.link), Java 21+ (Java 25 for 26.1.2), [Pester 5](https://pester.dev/docs/introduction/installation)

```powershell
# Run unit tests (no server required)
.\tests\Pester.Run.ps1 -ExcludeIntegration
```

For integration tests and full setup instructions see [CONTRIBUTING.md](CONTRIBUTING.md).

---

[Disclaimers](DISCLAIMERS.md) · [License](LICENSE)
```

- [ ] **Step 2: Verify badge URLs are well-formed**

```powershell
$content = Get-Content README.md -Raw
$badges = [regex]::Matches($content, 'https://img\.shields\.io/endpoint\?url=[^\)]+')
$badges | ForEach-Object { Write-Host $_.Value }
```

Expected: 5 badge URLs printed, each containing `raw.githubusercontent.com/MisterVitoPro/keep-it-simple-modpack/main/.github/badges/`.

---

## Task 10: Create .github/workflows/badges.yml

**Files:**
- Create: `.github/workflows/badges.yml`

This workflow fires when `.pw.toml` files change on `main`, recomputes the mod count per version, and commits updated badge JSONs.

- [ ] **Step 1: Create workflows directory**

```powershell
New-Item -ItemType Directory -Force -Path .github\workflows
```

- [ ] **Step 2: Write badges.yml**

```yaml
name: Update Mod Count Badges

on:
  push:
    branches: [main]
    paths:
      - 'Packwiz/*/mods/*.pw.toml'

jobs:
  update-badges:
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Generate badge JSONs
        run: |
          mkdir -p .github/badges
          for v in 1.20.1 1.21.1 1.21.4 1.21.11 26.1.2; do
            COUNT=$(find "Packwiz/$v/mods" -name "*.pw.toml" | wc -l | tr -d ' ')
            printf '{\n  "schemaVersion": 1,\n  "label": "%s",\n  "message": "%s mods",\n  "color": "blue"\n}\n' \
              "$v" "$COUNT" > ".github/badges/${v}.json"
            echo "  ${v}: ${COUNT} mods"
          done

      - name: Commit badge updates
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add .github/badges/*.json
          if git diff --cached --quiet; then
            echo "No badge changes"
          else
            git commit -m "chore: update mod count badges"
            git push
          fi
```

- [ ] **Step 3: Verify YAML syntax**

```powershell
# python3 is available on most dev machines; skip if not installed
python3 -c "import yaml, sys; yaml.safe_load(open('.github/workflows/badges.yml'))" 2>&1
```

Expected: no output (no error). If python3 is unavailable, visually check that every `- name:` block under `steps:` has consistent 6-space indentation and every `run: |` block is indented 10 spaces.

---

## Task 11: Create .github/workflows/publish.yml

**Files:**
- Create: `.github/workflows/publish.yml`

This workflow fires on a `v*.*.*` tag push. It diffs each `Packwiz/<version>/` directory against the previous tag, builds `.mrpack` files only for changed versions, creates a GitHub Release, and uploads each changed version to Modrinth via the API.

**Before the first release, configure these in GitHub → Settings → Secrets and variables:**
- Secret `MODRINTH_TOKEN` — create at modrinth.com/settings/pats (scope: `VERSION_CREATE`)
- Variable `MODRINTH_PROJECT_ID` — the slug or numeric ID of your Modrinth project (create the project on modrinth.com first)

The pinned packwiz version is `0.6.1`. Check [github.com/packwiz/packwiz/releases](https://github.com/packwiz/packwiz/releases) for a newer stable release and update `PACKWIZ_VERSION` if needed — the pack uses `pack-format = "packwiz:1.1.0"` which requires packwiz ≥ 0.6.0.

- [ ] **Step 1: Write publish.yml**

```yaml
name: Publish

on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Detect changed versions
        id: detect
        run: |
          PREV=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")
          echo "Previous tag: ${PREV:-none}"

          CHANGED=""
          for v in 1.20.1 1.21.1 1.21.4 1.21.11 26.1.2; do
            if [ -z "$PREV" ] || ! git diff --quiet "$PREV"..HEAD -- "Packwiz/$v/" 2>/dev/null; then
              CHANGED="${CHANGED} ${v}"
            fi
          done
          CHANGED="${CHANGED# }"

          echo "changed=${CHANGED}" >> "$GITHUB_OUTPUT"
          if [ -n "$CHANGED" ]; then
            echo "has_changes=true" >> "$GITHUB_OUTPUT"
          else
            echo "has_changes=false" >> "$GITHUB_OUTPUT"
          fi
          echo "Changed versions: ${CHANGED:-none}"

      - name: Nothing changed — skip release
        if: steps.detect.outputs.has_changes == 'false'
        run: |
          echo "No Packwiz version directories changed since the previous tag. Skipping release."
          exit 0

      - name: Install packwiz
        if: steps.detect.outputs.has_changes == 'true'
        env:
          PACKWIZ_VERSION: '0.6.1'
        run: |
          # Check https://github.com/packwiz/packwiz/releases for the latest stable version
          # and update PACKWIZ_VERSION above. The pack uses pack-format packwiz:1.1.0 which
          # requires packwiz >= 0.6.0. Verify the exact asset filename on the release page
          # before pinning — it is typically "packwiz_linux_amd64" (no extension).
          curl -fsSL \
            "https://github.com/packwiz/packwiz/releases/download/v${PACKWIZ_VERSION}/packwiz_linux_amd64" \
            -o packwiz
          chmod +x packwiz
          sudo mv packwiz /usr/local/bin/packwiz
          packwiz --version

      - name: Build mrpacks
        if: steps.detect.outputs.has_changes == 'true'
        run: |
          mkdir -p dist
          TAG="${GITHUB_REF_NAME}"
          for v in ${{ steps.detect.outputs.changed }}; do
            echo "=== Building ${v} ==="
            (cd "Packwiz/${v}" && packwiz modrinth export \
              -o "../../dist/keep-it-simple-${v}-${TAG}.mrpack" --yes)
            ls -lh "dist/keep-it-simple-${v}-${TAG}.mrpack"
          done

      - name: Extract changelog body
        if: steps.detect.outputs.has_changes == 'true'
        id: changelog
        run: |
          BODY=$(awk '/^## \[/{if(p) exit; p=1; next} p' CHANGELOG.md)
          {
            echo "body<<CHANGELOG_EOF"
            echo "$BODY"
            echo "CHANGELOG_EOF"
          } >> "$GITHUB_OUTPUT"

      - name: Create GitHub Release
        if: steps.detect.outputs.has_changes == 'true'
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ github.ref_name }}
          name: ${{ github.ref_name }}
          body: ${{ steps.changelog.outputs.body }}
          files: dist/*.mrpack

      - name: Publish to Modrinth
        if: steps.detect.outputs.has_changes == 'true'
        env:
          MODRINTH_TOKEN: ${{ secrets.MODRINTH_TOKEN }}
          MODRINTH_PROJECT_ID: ${{ vars.MODRINTH_PROJECT_ID }}
          TAG: ${{ github.ref_name }}
          CHANGED: ${{ steps.detect.outputs.changed }}
          CHANGELOG_BODY: ${{ steps.changelog.outputs.body }}
        run: |
          VERSION="${TAG#v}"
          for v in $CHANGED; do
            MRPACK="dist/keep-it-simple-${v}-${TAG}.mrpack"
            echo "=== Uploading ${v} to Modrinth ==="

            DATA=$(jq -n \
              --arg name "${TAG} — ${v}" \
              --arg version_number "${VERSION}-${v}" \
              --arg changelog "$CHANGELOG_BODY" \
              --arg game_version "$v" \
              --arg project_id "$MODRINTH_PROJECT_ID" \
              '{
                name:           $name,
                version_number: $version_number,
                changelog:      $changelog,
                dependencies:   [],
                game_versions:  [$game_version],
                version_type:   "release",
                loaders:        ["fabric"],
                featured:       true,
                project_id:     $project_id,
                file_parts:     ["file0"],
                primary_file:   "file0"
              }')

            curl -fsSL \
              -H "Authorization: ${MODRINTH_TOKEN}" \
              -F "data=${DATA}" \
              -F "file0=@${MRPACK}" \
              "https://api.modrinth.com/v2/version"

            echo ""
            echo "Uploaded ${v}"
          done
```

- [ ] **Step 2: Verify YAML syntax**

```powershell
python3 -c "import yaml, sys; yaml.safe_load(open('.github/workflows/publish.yml'))" 2>&1
```

Expected: no output. If python3 is unavailable, visually verify that each step's `run: |` body is indented consistently (10 spaces) and all multiline strings are properly closed.

- [ ] **Step 3: Verify the awk changelog extraction locally**

```powershell
# On Linux/WSL or Git Bash:
awk '/^## \[/{if(p) exit; p=1; next} p' CHANGELOG.md | head -5
```

Expected: first 5 lines of the v0.1.0 entry body (e.g. "Initial release. Supports Minecraft...").

---

## Task 12: Initial commit and push

**Files:** all previously created

- [ ] **Step 1: Stage all new and modified files**

```powershell
git add assets\
git add Packwiz\1.20.1\pack.png Packwiz\1.21.1\pack.png Packwiz\1.21.4\pack.png Packwiz\1.21.11\pack.png Packwiz\26.1.2\pack.png
git add LICENSE CHANGELOG.md CONTRIBUTING.md DISCLAIMERS.md README.md MODS-LIST.md .gitignore
git add .github\
git add docs\
git status
```

Review the staged file list. Confirm `.env` is NOT staged (it is gitignored).

- [ ] **Step 2: Create initial commit**

```powershell
git commit -m "feat: initial public release v0.1.0

- MIT license
- README with logo and dynamic mod count badges
- CHANGELOG, CONTRIBUTING, DISCLAIMERS
- GitHub issue templates and PR template
- GHA publish workflow (tag-triggered, per-version diff)
- GHA badge update workflow
- Pack icon (pack.png) in each Packwiz version"
```

- [ ] **Step 3: Tag v0.1.0**

```powershell
git tag -a v0.1.0 -m "v0.1.0 — initial release"
```

- [ ] **Step 4: Push branch and tag**

```powershell
git push -u origin main
git push origin v0.1.0
```

- [ ] **Step 5: Verify on GitHub**

Open `https://github.com/MisterVitoPro/keep-it-simple-modpack` in a browser and confirm:
- Repository is visible
- README renders with the logo image and badge row
- The `v0.1.0` tag appears under Releases (the publish workflow will run — check Actions tab)

---

## Post-setup: Before the publish workflow can succeed

After pushing, do these manually in the GitHub repo Settings:

1. **Create the Modrinth project** at modrinth.com → New project → Modpack. Note the project slug/ID.
2. **GitHub → Settings → Secrets and variables → Actions:**
   - Add secret: `MODRINTH_TOKEN` (modrinth.com/settings/pats, scope `VERSION_CREATE`)
   - Add variable: `MODRINTH_PROJECT_ID` (your Modrinth project slug or numeric ID)
3. **Re-run the publish workflow** for the v0.1.0 tag from the Actions tab (it will have failed on the Modrinth step if the secrets weren't set in time).
