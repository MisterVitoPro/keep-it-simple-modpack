<div align="center">
  <img src="assets/kis_modpack_sq.png" alt="Keep It Simple Modpack" width="256">

  # Keep It Simple

  A Fabric modpack for adventuring, questing, and optimized play.

  [![Version](https://img.shields.io/badge/version-v0.1.0-blue)](https://github.com/MisterVitoPro/keep-it-simple-modpack/releases)
  [![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
  [![26.1.2](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/MisterVitoPro/keep-it-simple-modpack/main/.github/badges/26.1.2.json&label=26.1.2)](MODS-LIST.md)
</div>

[Overview](README.md) · [Mods List](MODS-LIST.md) · [Changelog](CHANGELOG.md)

Keep It Simple adds minor content to promote adventuring and questing, while bringing the client and server optimizations and menus that modded players are accustomed to. This is an alpha release and more content is on the way.

## Supported Versions

| Minecraft | Fabric Loader |
| --- | --- |
| 26.1.2 | 0.19.2 |

## Install

### Modrinth (recommended)

Find the latest release on [Modrinth](https://modrinth.com/modpack/keep-it-simple) or download the `.mrpack` from the [Releases](../../releases) page and import it into your launcher (Prism Launcher, ATLauncher, MultiMC).

### CurseForge

Download the `.zip` from the [Releases](../../releases) page and import it via the CurseForge App.

## Mods

See [MODS-LIST.md](MODS-LIST.md) for the complete list of included mods, their categories, and which Minecraft versions each one supports.

## Recommended Datapacks

These datapacks pair well with Keep It Simple but are not bundled — install them per-world from Modrinth.

| Datapack | Versions | Description |
| --- | --- | --- |
| [BlazeAndCave's Advancements Pack](https://modrinth.com/datapack/blazeandcaves-advancements-pack) | 26.1.2 | Adds 1000+ new advancements covering every corner of vanilla Minecraft |

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
