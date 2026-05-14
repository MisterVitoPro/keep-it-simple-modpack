<div align="center">
  <img src="assets/kis_modpack_sq.png" alt="Keep It Simple Modpack" width="256">

  # Keep It Simple

  A performance and quality-of-life Fabric modpack for Minecraft.

  [![Version](https://img.shields.io/badge/version-v0.1.0-blue)](https://github.com/MisterVitoPro/keep-it-simple-modpack/releases)
  [![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
  [![1.20.1](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/MisterVitoPro/keep-it-simple-modpack/main/.github/badges/1.20.1.json&label=1.20.1)](MODS-LIST.md)
  [![1.21.1](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/MisterVitoPro/keep-it-simple-modpack/main/.github/badges/1.21.1.json&label=1.21.1)](MODS-LIST.md)
  [![1.21.4](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/MisterVitoPro/keep-it-simple-modpack/main/.github/badges/1.21.4.json&label=1.21.4)](MODS-LIST.md)
  [![1.21.11](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/MisterVitoPro/keep-it-simple-modpack/main/.github/badges/1.21.11.json&label=1.21.11)](MODS-LIST.md)
  [![26.1.2](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/MisterVitoPro/keep-it-simple-modpack/main/.github/badges/26.1.2.json&label=26.1.2)](MODS-LIST.md)
</div>

[Overview](README.md) · [Mods List](MODS-LIST.md) · [Changelog](CHANGELOG.md)

Keep It Simple is a Fabric modpack built around one rule: if a mod doesn't make your game run better, look better, or feel better without getting in the way, it doesn't belong here.

Every mod is hand-picked for stability and compatibility across supported Minecraft versions. Sodium rewrites the chunk renderer for dramatically higher FPS. Lithium optimizes game logic across AI, ticking, and world generation. FerriteCore cuts memory usage. Iris brings full shader support. LambDynamicLights, entity texture features, and sound physics add visual and audio depth without touching vanilla mechanics. Jade and Xaero's Minimap surface information that should have always been there.

No quests. No custom dimensions. No overhauls. Just Minecraft, running the way it should.

## Supported Versions

| Minecraft | Fabric Loader |
| --- | --- |
| 1.20.1 | 0.19.2 |
| 1.21.1 | 0.19.2 |
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

Contributions are welcome: new mods, version updates, bug reports. See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow.

## Development

**Requirements:** PowerShell 5.1, [packwiz](https://packwiz.infra.link), Java 21+ (Java 25 for 26.1.2), [Pester 5](https://pester.dev/docs/introduction/installation)

```powershell
# Run unit tests (no server required)
.\tests\Pester.Run.ps1 -ExcludeIntegration
```

For integration tests and full setup instructions see [CONTRIBUTING.md](CONTRIBUTING.md).

---

[Disclaimers](DISCLAIMERS.md) · [License](LICENSE)
