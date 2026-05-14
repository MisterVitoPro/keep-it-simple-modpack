# Keep It Simple — GitHub & Modrinth Release Setup

**Date:** 2026-05-13
**Status:** Approved

## Goal

Make the Keep It Simple modpack repo public-ready: professional README, contributor docs, legal files, a logo, dynamic mod-count badges, and a GitHub Actions workflow that publishes changed pack versions to Modrinth on every semver tag.

---

## Decisions

- **Loader:** Fabric only
- **MC versions:** 1.20.1, 1.21.1, 1.21.4, 1.21.11, 26.1.2
- **Version:** v0.1.0 (already set in all `pack.toml` files)
- **License:** MIT (`Copyright (c) 2026 MisterVitoPro`)
- **Modrinth project:** brand new — user creates it on modrinth.com, then sets `MODRINTH_PROJECT_ID` repo variable and `MODRINTH_TOKEN` secret in GitHub Settings before first release
- **CI scope:** publish workflow only; no PR test workflow
- **GHA runner:** `ubuntu-latest`
- **Change detection:** per-version diff against previous tag; only changed versions are built and published
- **Contribution docs:** describe manual packwiz CLI workflow — no Claude tooling referenced

---

## Repository Structure

```
keep-it-simple-modpack/
├── .github/
│   ├── workflows/
│   │   ├── publish.yml           # tag-triggered: build + release + Modrinth upload
│   │   └── badges.yml            # push-to-main: regenerate mod-count badge JSONs
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   └── mod_request.yml
│   ├── pull_request_template.md
│   └── badges/                   # auto-generated, committed by badges.yml
│       ├── 1.20.1.json
│       ├── 1.21.1.json
│       ├── 1.21.4.json
│       ├── 1.21.11.json
│       └── 26.1.2.json
├── assets/
│   └── kis_modpack_sq.png        # pack logo
├── Packwiz/                      # (existing source of truth, unchanged)
│   ├── 1.20.1/
│   ├── 1.21.1/
│   ├── 1.21.4/
│   ├── 1.21.11/
│   └── 26.1.2/
├── scripts/                      # (existing, unchanged)
├── tests/                        # (existing, unchanged)
├── CHANGELOG.md                  # new — Keep a Changelog format
├── CONTRIBUTING.md               # new — packwiz CLI workflow, no Claude tooling
├── DISCLAIMERS.md                # new — attribution, anticheat, no warranty, forking
├── LICENSE                       # new — MIT
├── MODS-LIST.md                  # (existing, unchanged)
└── README.md                     # rewritten — logo, badges, install, contributing
```

---

## README

### Content

1. Hero image: `assets/kis_modpack_sq.png` (centered)
2. Badges row:
   - Pack version (static: `v0.1.0`)
   - License (static: MIT)
   - Per-version mod-count (dynamic Shields.io endpoint from `.github/badges/*.json`)
3. One-paragraph description
4. Supported versions table (MC version + Fabric Loader version)
5. Install section: Modrinth (recommended) · CurseForge — both point to GitHub Releases
6. Link to MODS-LIST.md
7. Contributing blurb linking to CONTRIBUTING.md
8. Development / Testing section (condensed from current README)
9. Footer: links to DISCLAIMERS.md and LICENSE

### Dynamic badges

Each `.github/badges/<version>.json` is a Shields.io endpoint payload:

```json
{
  "schemaVersion": 1,
  "label": "1.21.4",
  "message": "30 mods",
  "color": "blue"
}
```

Badge URL pattern:
```
https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/MisterVitoPro/keep-it-simple-modpack/main/.github/badges/1.21.4.json
```

The `badges.yml` workflow counts `*.pw.toml` files in `Packwiz/<v>/mods/` on every push to `main` and commits updated JSONs if any count changed.

---

## GHA: `publish.yml`

### Trigger

```yaml
on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'
```

### Steps

1. **Checkout** with `fetch-depth: 0` (full history for tag diffs)
2. **Find previous tag** — `git describe --tags --abbrev=0 HEAD^`; if no previous tag exists, all versions are treated as changed
3. **Detect changed versions** — for each of the 5 MC versions, run `git diff --quiet <prev-tag>..HEAD -- Packwiz/<v>/`; build a `CHANGED_VERSIONS` list
4. **Exit early** if `CHANGED_VERSIONS` is empty (nothing to release)
5. **Install packwiz** — download pinned binary from GitHub releases (e.g. `v0.6.1`) using `curl`
6. **Build mrpacks** — for each changed version: `packwiz modrinth export -o ./dist/keep-it-simple-<v>-<tag>.mrpack`
7. **Create GitHub Release** — via `softprops/action-gh-release`; assets are the generated `.mrpack` files; body is the content between the first `## [x.y.z]` heading and the next `## [` heading in `CHANGELOG.md` (extracted with `sed` or a shell heredoc)
8. **Upload to Modrinth** — via `Kir-Antipov/mc-publish`; one call per changed version; reads `MODRINTH_PROJECT_ID` repo variable and `MODRINTH_TOKEN` secret

### Required GitHub configuration (user sets up before first release)

| Type | Name | Value |
|------|------|-------|
| Secret | `MODRINTH_TOKEN` | API token from modrinth.com/settings/pats |
| Variable | `MODRINTH_PROJECT_ID` | Slug or ID of the Modrinth project |

---

## GHA: `badges.yml`

### Trigger

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'Packwiz/*/mods/*.pw.toml'
```

### Steps

1. Checkout
2. For each MC version, count `*.pw.toml` files in `Packwiz/<v>/mods/`
3. Write/overwrite `.github/badges/<v>.json` with updated counts
4. Commit and push if any file changed (using `GITHUB_TOKEN`)

---

## New Files

### `LICENSE`
MIT license. Year: 2026. Copyright holder: MisterVitoPro.

### `CHANGELOG.md`
[Keep a Changelog](https://keepachangelog.com) format. Initial entry: `## [0.1.0] — 2026-05-13` with initial mod list summary. The `publish.yml` workflow extracts the latest section as the GitHub Release body.

### `CONTRIBUTING.md`
Sections:
- Prerequisites (packwiz CLI, PowerShell 5.1, Java, Pester 5)
- Adding a mod (fork → `packwiz pack add <modrinth-url>` in the correct `Packwiz/<v>/` dir → run unit tests → open PR)
- Branch naming convention: `add/<mod-slug>`, `fix/<description>`
- PR checklist (matches `pull_request_template.md`)
- Running unit tests: `.\tests\Pester.Run.ps1 -ExcludeIntegration`
- Link to DISCLAIMERS.md

### `DISCLAIMERS.md`
Sections:
1. Not an official Minecraft product (MOJANG disclaimer)
2. Mod attribution — all mods belong to their respective authors; KIS only packages them; see MODS-LIST.md for credits
3. Server/anticheat compatibility — visual and performance mods (Entity Culling, Iris, etc.) may be flagged by some server anticheats; verify with server operators before use
4. No warranty — provided as-is under MIT; no liability for gameplay or server issues
5. Forking — MIT permits forks; do not represent derivatives as "Keep It Simple" without making clear it is a fork

### `.github/ISSUE_TEMPLATE/bug_report.yml`
Structured form: MC version (dropdown), Fabric Loader version, description of issue, steps to reproduce, expected vs actual behavior.

### `.github/ISSUE_TEMPLATE/mod_request.yml`
Structured form: mod name + Modrinth URL, which MC versions it should target, why it fits the pack's goals (performance/visual/utility/functional), confirmation it's Fabric-compatible.

### `.github/pull_request_template.md`
Checklist: server tested (or N/A), `MODS-LIST.md` updated, `CHANGELOG.md` entry added, no new errors in boot log.

---

## Pack Icons

Copy `assets/kis_modpack_sq.png` as `pack.png` into each `Packwiz/<v>/` directory. packwiz includes `pack.png` in mrpack exports automatically if present.

---

## Versioning Convention

Semantic versioning on git tags: `v<MAJOR>.<MINOR>.<PATCH>`

- PATCH bump: mod version updates, no mod additions/removals
- MINOR bump: mods added or removed, or new MC version support added
- MAJOR bump: breaking change or complete overhaul

Document this in `CONTRIBUTING.md`.

---

## Out of Scope

- CurseForge publishing (user only mentioned Modrinth)
- PR test CI workflow
- Automated CHANGELOG generation
- Modrinth project creation (done manually by user before first release)
