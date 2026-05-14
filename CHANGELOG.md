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
