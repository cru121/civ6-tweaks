# Terra Mirabilis (2026 update)

An **unofficial, community bug-fix update** of the Civilization VI mod
**[Terra Mirabilis](https://github.com/deliverator23/TerraMirabilis)**
(NaturalWondersMod component, based on the last public release **2.21.3**).

> **Not affiliated with the original authors.** All natural-wonder designs, art,
> text and the mod framework are the work of **Deliverator** and **ChimpanG**
> (special thanks: **CIVITAS**). This update adds only bug fixes and small
> corrections on top of 2.21.3 — it claims no ownership of the original work.
> See [`NOTICE`](NOTICE) for full attribution and the redistribution stance.
>
> Maintained by **cru121** (Steam: *evzenhouzvicka*).

Terra Mirabilis reworks every Natural Wonder in Civ VI and adds a set of new
ones (including old fan favourites). The original mod was abandoned; this update
picks up long-standing bugs reported on the Workshop and fixes them.

---

## What this 2026 update changes

### Bug fixes
- **Mount Kailash** — culture no longer over-accumulates on every save/reload.
  The ownership bonus was re-applying itself each load (unbounded stacking); it
  now uses the idempotent religious-belief yield the base game uses for
  Pilgrimage / World Church, scoped to your *founded* religion.
- **Krakatoa** — earning a Great Admiral now actually grants the free Eureka
  (a boolean argument was written as an integer, so it silently did nothing).
- **Matterhorn** — your units now genuinely ignore the Hills movement penalty
  (same integer-vs-boolean bug), and the effect is now **visible as an ability**
  on your land units, like Giant's Causeway.
- **Grand Mesa** — the "ignore Forest movement cost" effect now works (same bug)
  and is likewise shown on your land units.
- **Victoria Falls (Mosi-oa-Tunya)** — placement loosened so it reliably spawns.
- **Lençóis Maranhenses** — its yields now apply in the base game, not only with
  the Gathering Storm expansion.
- **Mount Roraima** — fixed an "Onwed" → "Owned" typo in its effect text.

### New: natural-wonder *type* interactions
Many wonders visually **are** a terrain type (a marsh, a reef, a geyser field, a
lake) but the engine doesn't classify their tiles that way, so type-keyed content
skipped them. This update wires them up:

- **Mountain wonders** → adjacent **Terrace Farms** get **+1 Food**.
- **Marsh wonders** (Pantanal, Ubsunur Hollow) → now count for the **Lady of the
  Reeds and Marshes** pantheon, marsh improvements, and the **Zoo**.
- **Reef wonders** (Great Barrier Reef) → now count for the **Aquarium**.
- **Geothermal wonders** (Old Faithful, Pamukkale, Dallol, Gobustan) → now count
  for the **Fire Goddess** pantheon and the **Thermal Bath**.
- **Lake wonders** (Lake Victoria, Dead Sea, Lake Retba) → **Huey Teocalli**'s
  Food/Production lake bonus now applies to their tiles.

### Known limitations (unchanged, by design or engine-locked)
- **Mount Sinai** can't host an adjacent Aqueduct, and **Lake Victoria**'s tiles
  read as Coast — both are hard-coded in the game engine and can't be fixed from
  mod data.
- **Cliffs of Dover**'s Harbor bonus keys off adjacent hills (the engine has no
  "adjacent to a cliff" adjacency) — kept as the original author intended.
- **Ubsunur Hollow**'s advertised "Inspiration on earning a Great General" can't
  be delivered: Civ VI has no effect that grants a civic boost when a Great
  Person is earned. Left as a documented limitation.

A few reports (specialty-district base-yield, Wulingyuan culture, Pamukkale
adjacency) couldn't be reproduced from the code and are pending in-game repro.

---

## Install

This is a drop-in mod folder — **no Steam Workshop subscription**.

1. Download the latest release **ZIP** (it contains the full mod, including art).
2. Extract the folder into your Civ VI **Mods** directory:
   - `Documents\My Games\Sid Meier's Civilization VI\Mods\`
   - (If your Documents are in OneDrive, it's under `OneDrive\Documents\…`.)
   - You should end up with `…\Mods\TerraMirabilis2026\` containing
     `NaturalWondersMod.modinfo`.
3. Launch Civ VI → **Additional Content** → enable **Terra Mirabilis (2026 update)**.

**Do not run this alongside the original Terra Mirabilis** — disable/unsubscribe
the original first. This update ships with a fresh mod id, so the game would
otherwise try to load both.

### Compatibility notes
- Works with any combination of the DLCs/expansions (base, Rise & Fall,
  Gathering Storm) — content gates itself to what you own.
- **CQUI** users may see a harmless `cqui_settings_local.sql` warning in the log;
  it's CQUI's own and unrelated to this mod.
- **Resourceful 2**: a load-order conflict has been reported; a compatibility
  tweak is still being evaluated (see the issue tracker).

---

## For contributors / building from source

This repository tracks only the **editable logic/text** of the mod (SQL + the
Lua wonder generator + art *definitions*). The ~420 MB of **compiled art**
(`Platforms/**`, `*.blp`) is git-ignored — it never changes when fixing SQL, so
it lives only in the packaged release and in the game's Mods folder. Release
ZIPs bundle that art back in so end users get a complete mod.

This folder is a snapshot of the mod at release. Every change here sits on top of
the last public Terra Mirabilis release (**2.21.3**, upstream commit `e5f2c60`), so
diffing it against upstream 2.21.3 shows exactly what the 2026 update changes.
(The full layered development history — pristine 2.21.3 baseline → prior gameplay
tweaks → individual bug-fix commits — is kept in the maintainer's separate working
repo.)

Development loop (Windows / PowerShell):

```powershell
.\deploy.ps1            # copy tracked files into the local Mods folder to test
.\deploy.ps1 -DryRun    # preview what would be copied
```

`deploy.ps1` copies only git-tracked files, so it never disturbs the ignored art.
Restart Civ VI (or reload the mod) after deploying. Issue triage and fix notes
live in [`ISSUES.md`](ISSUES.md).

---

## Credits & license

- **Original mod:** Terra Mirabilis by **Deliverator** and **ChimpanG**; special
  thanks **CIVITAS**. Upstream: <https://github.com/deliverator23/TerraMirabilis>.
- **Unofficial 2026 update:** **cru121** (Steam: *evzenhouzvicka*).

The upstream project ships **no license file**, so there is no explicit
redistribution grant. This update is shared as a good-faith community
continuation of an abandoned mod: free, non-commercial, fully crediting the
original authors, claiming no ownership of their work, and **taken down on
request** by any original author. See [`NOTICE`](NOTICE) for details.

Civilization VI is a trademark of Firaxis Games / 2K. This is a fan mod, not
affiliated with or endorsed by Firaxis or 2K.
