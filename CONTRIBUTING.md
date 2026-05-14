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
