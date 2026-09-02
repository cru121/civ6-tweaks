# Natural Wonder Type Catalog

Purpose: many natural wonders visually/thematically *are* a terrain type (mountain,
marsh, reef, geyser…) but are coded as their own `FEATURE_*` on ordinary base
terrain, so effects that key on the "real" type skip them. This catalog maps each
Terra Mirabilis wonder to the type(s) it *should* interact as, so we can drive a
mapping-table fix (à la the Terrace mod's `NatWonderAdjacencies.sql`).

## What is and isn't fixable (terrain constraint)

- **Adjacency (something *next to* the wonder benefits)** — FIXABLE via SQL:
  add the wonder's `FeatureType` to the relevant `Adjacency_YieldChanges`
  (`AdjacentFeature = FEATURE_X`) and attach to the consumer district/improvement.
  Works on existing saves, no terrain change. This is the Terrace pattern.
- **On-tile (the wonder *tile itself* counts as the type)** — effectively NOT
  fixable. Terrain type is set at map-generation via `TerrainBuilder`; changing it
  mid-game is unsupported (multiplayer desync, gen-only ops), and "true mountain"
  terrain is impassable with special handling. Worse, the generator runs
  `ResetTerrain`, which **flattens** hills/mountain under a wonder to flat terrain.
  So Inca literally farming/working a mountain-wonder tile, or a marsh wonder's tile
  giving marsh movement, is off the table (best case: gen-time-only tweaks to new maps).

**Therefore this catalog targets adjacency interactions.** On-tile gaps are noted but flagged not-fixable.

## Legend

- **Pass?** — `impass` = impassable (mostly the mountain/peak wonders), `pass` = walkable.
- **Flatten** — does placement `ResetTerrain` flatten its tile? (`mtn→flat`, `if hills`, `no-op`, or custom).
- **Fresh** — grants fresh water. **Cold** — sits on / themed tundra-snow.

## Master table

| Wonder | FeatureType | Real-world type | Pass? | Base terrain | Fresh | Cold | Suggested interaction class(es) | Notable current gap |
|---|---|---|---|---|---|---|---|---|
| Everest | FEATURE_EVEREST | Mountain | impass | *_MOUNTAIN | – | ✓(snow ok) | **Mountain** | mtn-adjacency consumers |
| Kilimanjaro | FEATURE_KILIMANJARO | Volcano/mtn | impass | *_MOUNTAIN | – | – | **Mountain**, Volcano | " |
| Matterhorn | FEATURE_MATTERHORN | Mountain | impass | *_MOUNTAIN | – | – | **Mountain** | " |
| Cerro de Potosí | FEATURE_CERRO_DE_POTOSI | Mountain | impass | *_MOUNTAIN | – | – | **Mountain** | " |
| Kailash | FEATURE_KAILASH | Sacred mtn | impass | *_MOUNTAIN | – | ✓(snow ok) | **Mountain** | " |
| Sinai | FEATURE_SINAI | Mountain | impass | *_MOUNTAIN(desert/plains) | – | – | **Mountain**, Desert | " |
| Sri Pada | FEATURE_SRI_PADA | Mountain peak | impass | *_MOUNTAIN | – | – | **Mountain** | " |
| Vesuvius | FEATURE_VESUVIUS | Volcano | impass | many incl *_MOUNTAIN | – | ✓(ok) | **Mountain**, Volcano | " |
| Krakatoa | FEATURE_KRAKATOA | Volcano | impass | *_MOUNTAIN | – | – | **Mountain**, Volcano | " |
| Zhangye Danxia | FEATURE_ZHANGYE_DANXIA | Rainbow rock mtns | impass | *_MOUNTAIN | – | – | **Mountain**, Rock | " |
| Roraima | FEATURE_RORAIMA | Tepui (flat-top mtn) | impass | GRASS_MOUNTAIN/HILLS/flat | – | – | **Mountain** | " |
| Torres del Paine | FEATURE_TORRES_DEL_PAINE | Granite peaks | impass | grass/plains/tundra+hills | – | ✓ | **Mountain**, Cold | on hills terrain, not mtn |
| Grand Mesa | FEATURE_GRAND_MESA | Flat-topped mesa | impass | plains/grass+hills | – | – | **Mountain/Mesa**, (Forest-adj) | flattened; not mtn terrain |
| Eyjafjallajökull | FEATURE_EYJAFJALLAJOKULL | Glacier volcano | impass | snow/tundra+hills | – | ✓ | **Volcano/Mountain**, **Cold** | not mtn terrain |
| — borderline "mountain-like" (rock/monolith/pinnacle) — | | | | | | | | |
| Gibraltar | FEATURE_GIBRALTAR | Coastal monolith rock | impass | grass+hills, coastal | – | – | Rock/Monolith (coastal) | coastal, not a peak |
| Mato Tipila (Devils Tower) | FEATURE_DEVILSTOWER | Butte/rock tower | impass | many+hills | – | ✓(ok) | Rock/Monolith | not a mountain terrain |
| Uluru | FEATURE_ULURU | Sandstone monolith | impass | desert+hills | – | – | Rock/Monolith, Desert | **absent from Terrace list** |
| Tsingy | FEATURE_TSINGY | Karst stone pinnacles | impass | grass/plains/tundra+hills | – | ✓(ok) | Rock/Karst | not a mountain |
| Wulingyuan | FEATURE_WULINGYUAN | Sandstone pillars | impass | grass/plains+hills | – | – | Rock/Peaks, Jungle-adj | not mtn terrain |
| Yosemite | FEATURE_YOSEMITE | Granite valley/cliffs | impass | plains/tundra+hills | – | ✓ | Rock/Cliffs, Forest-adj | not mtn terrain |
| — NOT mountains (Terrace list should reconsider) — | | | | | | | | |
| Paititi | FEATURE_PAITITI | Legendary jungle city | impass | grass/plains/desert+hills | – | – | **Jungle/Ruins** (not mtn) | miscategorised as mtn |
| Motlatse Canyon | FEATURE_MOTLATSE_CANYON | River canyon/gorge | impass | grass/plains+hills | ✓ | – | **Canyon**, Fresh water, River | miscategorised as mtn |
| Piopiotahi (Milford Sound) | FEATURE_PIOPIOTAHI | Fjord | impass | grass/plains+hills | – | – | **Fjord/Cliffs** (not mtn) | miscategorised as mtn |
| Lysefjorden | FEATURE_LYSEFJORDEN | Fjord (Pulpit Rock) | impass | grass/plains/tundra+hills | – | ✓ | Fjord/Cliffs, Cold | — |
| — Marsh / wetland — | | | | | | | | |
| Pantanal | FEATURE_PANTANAL | World's largest wetland | pass | grass/plains (flat) | – | – | **Marsh/Wetland** | doesn't count as marsh; has marsh-like Move+1/Def−2 |
| Ubsunur Hollow | FEATURE_UBSUNUR_HOLLOW | Tundra basin/wetland | pass | tundra+hills | – | ✓ | **Marsh/Wetland**, **Cold** | marsh-like Move+1/Def−2, not marsh |
| — Lake / fresh water — | | | | | | | | |
| Lake Victoria | FEATURE_LAKE_VICTORIA | Great lake | pass | grass/plains+hills | ✓ | – | **Lake/Fresh water** | see I5 (tiles read as coast) |
| Crater Lake | FEATURE_CRATER_LAKE | Volcanic crater lake | pass | grass/plains+hills | ✓ | – | **Lake/Fresh water**, Volcano-origin | — |
| Ounianga | FEATURE_OUNIANGA | Desert oasis lakes | pass | desert+hills | ✓ | – | **Oasis/Fresh water**, Desert | — |
| Ik-Kil | FEATURE_IKKIL | Cenote (sinkhole) | impass | grass/plains+hills | ✓ | – | **Fresh water/Cenote** | — |
| Mosi-oa-Tunya (Victoria Falls) | FEATURE_MOSI_OA_TUNYA | Waterfall on river | impass | grass+hills | ✓ | – | **River/Waterfall**, Fresh water | — |
| Fountain of Youth | FEATURE_FOUNTAIN_OF_YOUTH | Spring | pass | grass/plains/desert+hills | ✓ | – | Fresh water spring, Jungle-adj | — |
| Dead Sea | FEATURE_DEAD_SEA | Salt lake | pass | desert+hills | – (salt) | – | Lake(salt), Desert | correctly no fresh water |
| Lake Retba | FEATURE_LAKE_RETBA | Pink salt lake | pass | desert/grass/plains | – (salt) | – | Lake(salt) | — |
| — Reef / coastal water — | | | | | | | | |
| Great Barrier Reef | FEATURE_BARRIER_REEF | Coral reef | pass | COAST | – | – | **Reef/Coastal** | not FEATURE_REEF → reef-adjacency skips it |
| Galápagos | FEATURE_GALAPAGOS | Volcanic islands | impass | COAST | – | – | Coastal/Islands | — |
| Bioluminescent Bay | FEATURE_BIOLUMINESCENT_BAY | Coastal bay | pass | COAST | – | – | Coastal water | — |
| Ha Long Bay | FEATURE_HA_LONG_BAY | Karst sea bay | pass | COAST | – | – | Coastal/Karst | — |
| Giant's Causeway | FEATURE_GIANTS_CAUSEWAY | Basalt columns (coast) | impass | coast/plains/grass | – | – | Coastal rock | not a mountain |
| Bermuda Triangle | FEATURE_BERMUDA_TRIANGLE | Ocean anomaly | pass | OCEAN/COAST | – | – | Ocean (special) | — |
| — Desert / arid rock — | | | | | | | | |
| Namib | FEATURE_NAMIB | Ancient desert dunes | pass | desert+hills | – | – | **Desert** | — |
| Salar de Uyuni | FEATURE_SALAR_DE_UYUNI | Salt flat | pass | grass/plains+hills | – | – | Salt flat (desert-like) | on grass/plains, not desert |
| Lençóis Maranhenses | FEATURE_LENCOIS_MARANHENSES | Dunes + lagoons | pass | desert+hills | ✓ | – | Desert + fresh water | see I1 |
| Dallol | FEATURE_DALLOL | Hydrothermal salt field | pass | desert+hills | – | – | **Geothermal** + Desert | — |
| Delicate Arch | FEATURE_DELICATE_ARCH | Sandstone arch | impass | desert+hills | – | – | Rock arch, Desert | — |
| Eye of the Sahara | FEATURE_EYE_OF_THE_SAHARA | Geologic dome (Richat) | pass | desert+hills | – | – | Desert rock | — |
| Sahara el Beyda | FEATURE_WHITEDESERT | Chalk desert formations | pass | desert hills/mtn | – | – | **Desert**, Rock | — |
| Barringer Crater | FEATURE_BARRINGER_CRATER | Impact crater | pass | plains/desert+hills | – | – | Crater/Rock, Desert | — |
| Vredefort Dome | FEATURE_VREDEFORT_DOME | Eroded impact dome | pass | grass/plains+hills | – | – | Crater/Hills | passable, not a peak |
| — Hills-like — | | | | | | | | |
| Chocolate Hills | FEATURE_CHOCOLATEHILLS | Cone-shaped hills | pass | grass/plains hills/mtn | – | – | **Hills** (not mountain) | — |
| Gobustan | FEATURE_GOBUSTAN | Rocky hills + mud volcanoes | pass | plains hills/mtn | – | – | Hills/Rock, (mud volcano) | — |
| — Geothermal — | | | | | | | | |
| Old Faithful | FEATURE_OLD_FAITHFUL | Geyser | pass | grass/plains+hills | – | – | **Geothermal (geyser)**, Forest-adj | not FEATURE_GEOTHERMAL_FISSURE |
| Pamukkale | FEATURE_PAMUKKALE | Travertine thermal terraces | impass | grass/plains/desert+hills | ✓ | – | **Geothermal**, Fresh water | " |
| — Cliffs — | | | | | | | | |
| Cliffs of Dover | FEATURE_CLIFFS_DOVER | Coastal chalk cliffs | pass | grass/plains HILLS → flattened | – | – | Cliffs/Hills (coastal) | I9: flattened to grass, counts as nothing |

## Review of the Terrace mod's `MountainLikeWonders` list

**Keep — genuine mountains/volcanoes:** Everest, Kilimanjaro, Matterhorn, Cerro de
Potosí, Kailash, Sinai, Sri Pada, Vesuvius, Krakatoa, Zhangye Danxia, Roraima,
Torres del Paine, Grand Mesa, Eyjafjallajökull.

**Defensible but borderline (rock/monolith/pinnacle, not true peaks)** — fine to keep
if the intent is "big rocky highland," but they're a different flavour: Gibraltar,
Devils Tower, Tsingy, Wulingyuan, Yosemite.

**Challenge — not mountains:**
- **Paititi** — a legendary *jungle city*, not a mountain. Drop or move to a Jungle class.
- **Motlatse Canyon** — a *canyon/gorge* (a depression), the opposite of a peak. Drop or Canyon class.
- **Piopiotahi** — *Milford Sound*, a **fjord** (water inlet with cliffs). Not a mountain.

**Consistency gap — consider adding:** **Uluru** (sandstone monolith) is the same
kind of thing as Devils Tower/Gibraltar, which you included — currently absent.
Also **Chocolate Hills** / **Gobustan** are hills, not mountains — candidates for a
separate *Hills* class rather than the mountain one.

## Highest-value gaps (all adjacency-fixable)

1. **Marsh:** Pantanal & Ubsunur Hollow are wetlands but not `FEATURE_MARSH` — marsh-adjacency and marsh-themed effects skip them. (Pantanal is the textbook case you raised.)
2. **Reef:** Great Barrier Reef is not `FEATURE_REEF` — reef adjacency (e.g. Campus/commercial) skips the actual reef.
3. **Geothermal:** Old Faithful (a *geyser*), Pamukkale, Gobustan, Dallol are not geothermal fissures — geothermal adjacency / power (XP2) skips them.
4. **Mountain consumers beyond Terrace Farm:** Holy Site / Campus / Pingala-style mountain adjacency could recognise the mountain group (your Terrace mod already covers Terrace Farm).
5. **Cliffs of Dover (I9):** flattened, interacts with nothing; feature-adjacency would fix it.

## Not a gap: Tundra / Snow

Cold wonders (Eyjafjallajökull, Ubsunur Hollow, and the tundra-capable mountains
Everest/Kailash/Vesuvius/Torres del Paine/Tsingy/Yosemite/Lysefjorden) need **no**
fix. Tundra/Snow are base *terrain*, not features, and placement's `ResetTerrain`
preserves the base terrain family (`TUNDRA_HILLS → TUNDRA`). Tundra effects are
terrain-keyed and feature-agnostic (e.g. St. Basil's uses `REQUIRES_PLOT_HAS_TUNDRA`
/ `_TUNDRA_HILLS`; Russia's tundra yields likewise), so they already apply to the
wonder tiles. Moreover only **Ubsunur Hollow** is passable/workable among them, and
it already benefits; the rest are impassable, so tile-yields are moot. (Contrast
with Marsh, which needed widening because the wonder *replaces* the marsh feature.)

## How this maps to implementation

Reuse the Terrace pattern: one mapping table per class (`MountainLikeWonders`,
`MarshLikeWonders`, `ReefLikeWonders`, `GeothermalLikeWonders`, `HillsLikeWonders`…),
then generate `Adjacency_YieldChanges` (`AdjacentFeature = FeatureType`) and attach to
the relevant consumer(s). Decide per class: which consumers, what yield/amount.
