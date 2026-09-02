# Terra Mirabilis — Issue Tracker

User-reported issues (mostly Steam Workshop, reported since ~June 2022) plus
personal observations. The mod is abandoned upstream, so we're triaging and
fixing these in the private fork.

**Not everything here is a bug** — some may be user error, working-as-designed,
mod incompatibilities, or out-of-scope requests. Each is categorized below.

## Legend

**Category:**
`BUG` confirmed/suspected defect ·
`FIXED-UPSTREAM` already fixed in the final 2.21.3 code we baseline from ·
`PRIOR-TWEAK` overlaps a change already made in the "My prior tweaks" commit ·
`MAYBE-UE` possibly user error / working-as-designed — verify before touching ·
`COMPAT` interaction with another mod ·
`REQUEST` enhancement / art, out of scope for bug-fixing ·
`BY-DESIGN` reported as a bug but is working as intended (documented, not changed).

**Status:** `new` → `investigating` → `cause-found` → `fixed` → `verified` (in-game) · or `wontfix` / `needs-repro`.

## Summary

| ID | Issue | Category | Status | Fix commit |
|----|-------|----------|--------|-----------|
| [I1](#i1) | Lençóis Maranhenses: no yields / not counted as a natural wonder | BUG + PRIOR-TWEAK | yields fixed; NW-status = not a bug | 7af4bb2 |
| [I2](#i2) | Mt Kailash: culture over-accumulates (save/reload stacking) | BUG + PRIOR-TWEAK | fixed (verify) | 4481639 |
| [I3](#i3) | Krakatoa: no Great Admiral inspiration/eureka | BUG | fixed (verify) | d0a654d |
| [I4](#i4) | Mosi-oa-Tunya (Victoria Falls): won't spawn | BUG + PRIOR-TWEAK | fixed (confirmed in-game) | 7af4bb2 |
| [I5](#i5) | Lake Victoria: tiles count as coast, not lake | part engine-limited | Huey yields fixed; rest not fixable | df68b40 |
| [I6](#i6) | Mount Sinai: can't place adjacent Aqueduct | engine-limited | investigated (not fixable) | — |
| [I7](#i7) | Matterhorn: hill movement penalty not removed | BUG | fixed (verify) | 026f14e |
| [I8](#i8) | Specialty district buildings give +1 when not NW-adjacent | BUG | new | — |
| [I9](#i9) | Cliffs of Dover: Harbor adjacency "broken" / phantom tooltip | BY-DESIGN | documented | (kept as-is) |
| [I10](#i10) | Wulingyuan: only +1 tourism, no culture; Khmer-gated? | MAYBE-UE | code verified OK; needs in-game repro | — |
| [I11](#i11) | Grand Mesa: better 3D model wanted | REQUEST | wontfix | — |
| [I12](#i12) | Mount Roraima: "Onwed" typo in owner text | BUG | fixed | 5ece715 |
| [I13](#i13) | NW_ADJACENCY setting ignored (AND/OR precedence) | FIXED-UPSTREAM | verified | e5f2c60 (upstream) |
| [I14](#i14) | Pamukkale still gives adjacency to Campus/Theater/Commercial Hub | BUG / MAYBE-UE | new | — |
| [I15](#i15) | Resourceful 2 compatibility (LoadOrder) | COMPAT | new | — |
| [I16](#i16) | Ubsunur Hollow: Great General Inspiration never fires | BUG (found) | won't-fix unless redesigned | — |

---

## Details

<a id="i1"></a>
### I1 — Lençóis Maranhenses: no yields / not treated as a natural wonder
**Category:** BUG + PRIOR-TWEAK · **Status:** investigating
**Files:** `Core/Framework/TM_Master.sql`, likely also feature/NW definition files.

**Symptoms (reports):**
- Yields from the wonder are 0 without the Gathering Storm (XP2) DLC.
- Reporter traced it to the `Required` column being `'XP2'` for the two
  `FEATURE_LENCOIS_MARANHENSES` rows under `TM_FeatureYields`; changing to
  `'BASE'` restores yields.
- Also reported: does **not** count as a natural wonder for the **Astrology**
  science boost, and possibly not for **adjacency** bonuses (untested).

**Resolution — two halves:**
- **Yields (fixed, prior-tweak #1, commit 7af4bb2):** `Required` column `XP2` → `BASE`
  in `TM_Master`, so yields apply without Gathering Storm.
- **"Not a Natural Wonder for Astrology / adjacency" — NOT a bug.** Lençóis is
  generated with **`NaturalWonder = 1`** (`TM_Features.sql` hardcodes it for every
  `New = 1` wonder), so the game treats it as a natural wonder for all NW-keyed
  systems. Astrology's eureka is `BOOST_TRIGGER_FIND_NATURAL_WONDER` (`TECH_ASTROLOGY`,
  Technologies.xml) — a **one-time** "find *any* NW" boost. So it not firing on Lençóis
  means it had **already triggered** (another NW found earlier) or Astrology was already
  researched — user error, not a defect. The NW flag also gives it TM's NW adjacency, so
  the "untested adjacency" worry is moot.

---

<a id="i2"></a>
### I2 — Mt Kailash: owner gets far more culture than intended
**Category:** BUG + PRIOR-TWEAK · **Status:** fixed (needs in-game verification) · **Fix:** 4481639
**Files:** `Core/Natural Wonders/Terra Mirabilis/TM_Kailash.sql`

**Symptoms (reports):**
- Culture from Kailash's ownership effect **stacks on every save/reload** — one
  player with 21 same-religion foreign cities gained +21 culture per reload,
  reaching ~1,000/turn by 500 AD.
- Others independently report it "gives triple the culture it should," at least
  when a foreign religion was the player's majority.

**Assessment:**
- **Prior-tweak #2** changed `PerXItems` 1 → 3 (i.e. +1 culture per **3**
  foreign cities instead of per 1) — a nerf, likely an attempt to counter the
  "too much culture" symptom.
- ⚠️ That nerf is probably a **mis-fix**: the core problem the reports describe
  is **re-application on save/reload** (a known Civ6 pattern when an ownership
  modifier is attached in a way that re-runs on load), not a x3 multiplier.
  Dividing the per-city amount doesn't stop unbounded stacking — it just slows
  it. Need to look at how the modifier is attached/whether it's cumulative.

**Resolution (commit 4481639):** Root cause was the wrong effect *variant* —
`MODIFIER_PLAYER_RELIGION_ADD_PLAYER_BELIEF_YIELD` (additive/permanent) delivered
via a re-attaching `ALL_PLAYERS_ATTACH_MODIFIER`, so it re-applied every
save/reload. Swapped to `MODIFIER_PLAYER_RELIGION_ADD_RELIGIOUS_BELIEF_YIELD`
(idempotent; mirrors base-game Pilgrimage/World Church, which use the same
attach + this variant) and reverted `PerXItems` 3 → 1. Established from base-game
gameplay data — the stacking itself needs no in-game test.

**Behavioral change:** now scoped to the owner's *founded* religion rather than
their *majority* religion (matches every base-game analog).

**Cheap verification (optional):** one session — own Kailash with a founded
religion that has foreign followers; confirm culture appears and no longer grows
on save/reload.

---

<a id="i3"></a>
### I3 — Krakatoa: no inspiration on earning a Great Admiral
**Category:** BUG · **Status:** fixed (needs in-game verification)
**Files:** `Core/Natural Wonders/Terra Mirabilis/TM_Krakatoa_XP2.sql`

**Symptom:** Krakatoa should grant a free Eureka when the owner earns a Great
Admiral; reporter got a Great Admiral and no boost fired.

**Root cause:** the `MODTYPE_TM_GP_BOOST` effect args `TechBoost` and
`OtherPlayers` are **booleans**, but were written as integers (`TechBoost=1`,
`OtherPlayers=0`). Civ6 reads integer `1` as false, so no Eureka was ever granted
(same integer-as-boolean bug as I7). Base-game reference: `GREATLIBRARY_BOOST_SCIENTIST`
uses `TechBoost=true` / `OtherPlayers=true`.

**Fix:** `TechBoost` 1 → `true`, `OtherPlayers` 0 → `false` (preserving the author's
intent: give a Eureka, not restricted to other players' techs).

**Related discovered bug — Ubsunur Hollow (not yet fixed):** it uses the same
`MODTYPE_TM_GP_BOOST` and is meant to grant a free **Inspiration** on a Great
General, but its args are `TechBoost=0` with **no** `CivicBoost` — so it grants
nothing. Fixing it needs a `CivicBoost=true` arg *if* the effect supports one
(unconfirmed — no base-game usage of `CivicBoost` with this effect was found), else
a different mechanism. Tracked as [I16](#i16).

---

<a id="i4"></a>
### I4 — Mosi-oa-Tunya (Victoria Falls): won't spawn
**Category:** BUG + PRIOR-TWEAK · **Status:** fixed (confirmed in-game) · **Fix:** 7af4bb2
**Files:** `Core/Utilities/Maps/NaturalWonderGenerator.lua`

**Symptom:** Player could not get Victoria Falls to spawn on any map.

**Resolution:** **prior-tweak #3** loosened the `PLACEMENT_MOSI_OA_TUNYA` rule
(original multi-tile river config commented out; now just requires flat land + a
river on a north edge). **Owner confirmed in-game that it now spawns.**

**Optional cleanup (not done):** the tweak left the original placement logic
commented out inline plus tab→space indentation noise — cosmetic tidy only, no
functional effect.

---

<a id="i5"></a>
### I5 — Lake Victoria: tiles count as coast, not lake
**Category:** part engine-limited · **Status:** Huey yields fixed (df68b40); rest not fixable
**Files:** `Core/Natural Wonders/TM_WonderTypeInteractions.sql` (LAKE class)

**Symptoms:** Lake Victoria displays as a lake but Huey Teocalli (which boosts
Lake tiles) did not affect it; player asks why its tiles count as coast.

**Findings:**
- Lake Victoria's water tiles come out **Coast** (engine `IsLake()` = false), so
  effects that key on `REQUIRES_PLOT_IS_LAKE` (Huey Teocalli) skip them. The
  feature's `Lake` flag does NOT drive `IsLake()` — the base game's Dead Sea and
  Lake Retba carry `Lake="true"` too yet are also coast. `IsLake()` is a gen-time
  water-body classification, **not changeable via data**.
- So "why do the tiles count as coast" is an engine reality we can't flip.

**Partial fix (commit df68b40, LAKE class):** Huey Teocalli's Food/Production lake
boost is requirement-gated (`FOODHUEY`/`PRODUCTIONHUEY_PLOT_IS_LAKE_REQUIREMENTS`),
so those sets were widened to accept Lake Victoria (plus Dead Sea, Lake Retba) by
feature — Huey's yield boost now applies to their tiles without touching `IsLake()`.
**Not addressed (by choice / not feasible):** Huey's +Amenity-per-adjacent-lake
(skipped), and the underlying coast classification (gen-time, unchangeable).

---

<a id="i6"></a>
### I6 — Mount Sinai: can't place an adjacent Aqueduct
**Category:** MAYBE-UE → engine-limited · **Status:** investigated (not fixable via data)
**Files:** `Core/Natural Wonders/Terra Mirabilis/TM_Sinai.sql`

**Symptom:** Player unable to place an Aqueduct adjacent to Mount Sinai.

**Findings:**
- Aqueduct placement is **engine-gated**: the district carries `Aqueduct="true"`,
  and its "adjacent to Mountain / Oasis / Lake / River" rule is hardcoded in the
  DLL. There is **no data table** of valid aqueduct-adjacency sources to add
  wonders to.
- Mount Sinai (like all "mountain" wonders) is placed on a mountain terrain that
  the generator then **flattens** (`ResetTerrain`), leaving a non-mountain tile
  with an impassable feature. The engine's mountain check reads *terrain*, so it
  never matches the wonder. Same root cause as the general terrain constraint
  (see WONDER_TYPES.md).
- Only speculative lever: `AddsFreshWater="true"` on the feature (base game uses
  it only for Oasis and Crater Lake). Unverified whether the aqueduct check honors
  arbitrary fresh-water features or hardcodes Oasis; even if it worked it would add
  city housing (balance side effect) and needs in-game testing.

**Conclusion:** Not a mod bug and not cleanly fixable via SQL — an engine
limitation. Left as-is. (Would only be revisited to experiment with the
`AddsFreshWater` lever, at low confidence.)

---

<a id="i7"></a>
### I7 — Matterhorn: hill movement penalty not removed
**Category:** BUG · **Status:** fixed (needs in-game verification) · **Fix:** 026f14e
**Files:** `Core/Natural Wonders/XP1/TM_Matterhorn.sql`

**Symptom:** Tooltip says the owner's units ignore the hill movement penalty,
but neither existing nor newly-built units (from that city or elsewhere) get it.
Reporter calls it "100% broken."

**Context:** Matterhorn is a base-game (Rise & Fall) wonder; with `NW_EFFECTS = 1`
TM removes the base combat effect and replaces it with "all units of the owning
civ ignore the Hills movement penalty" (+2 culture adjacent).

**Resolution (commit 026f14e):** The effect argument was `Ignore = 1`. Civ6 reads
the `Ignore` arg of `EFFECT_ADJUST_UNIT_IGNORE_TERRAIN_COST` as a **boolean**, and
only the string `true` registers — integer `1` is read as false, so the modifier
attached but did nothing. Fixed to `Ignore = true` (matches base-game
`ALPINE_IGNORE_HILLS_MOVEMENT_PENALTY`). The collection `COLLECTION_PLAYER_UNITS`
is correct (base game uses it for player-wide `IGNORE_RIVERS`/`IGNORE_SHORES`).

**Cheap verification (optional):** one session — own Matterhorn, move a unit onto
a Hill, confirm no extra movement cost.

---

<a id="i8"></a>
### I8 — Specialty-district buildings add +1 base yield when NOT NW-adjacent
**Category:** BUG · **Status:** new
**Files:** `Core/Natural Wonders/TM_Globals.sql` (adjacency system) — TBD.

**Symptom:** Buildings in Specialty Districts increase the district's base yield
by +1 even when the district is **not** adjacent to any Natural Wonder.

**Assessment:** Likely related to the NW adjacency system. May be the **same
root** as [I13](#i13) (the AND/OR precedence bug granting standard adjacency
unconditionally) — but the "even when not adjacent" wording could indicate a
distinct defect. Since I13 is already fixed upstream in our baseline, re-test
this before assuming it's outstanding.

**Next step:** reproduce with the current (fixed-I13) baseline; if still present,
trace separately.

---

<a id="i9"></a>
### I9 — Cliffs of Dover: Harbor adjacency broken / phantom tooltip
**Category:** BY-DESIGN · **Status:** documented (kept as-is by owner decision)
**Files:** `Core/Natural Wonders/Base/TM_CliffsDover.sql` (documented inline)

**Symptoms (2 reports):**
- The ownership effect granting Harbor an adjacency bonus for cliffs doesn't
  happen.
- Conversely, a tooltip advertised the bonus at a Harbor where there were **no
  cliffs** at all.

**Findings:**
- **Probable design intent:** a civ owning Cliffs of Dover gets a minor Gold
  adjacency on its Harbors from all cliff tiles.
- **Actual implementation:** adjacency to **hill tiles** — Civ6 has no
  "adjacent to a cliff" adjacency source (cliffs are plot edges, not a
  Feature/Terrain; the `Adjacency_YieldChanges` schema offers terrain, feature,
  natural-wonder, river, etc., but not cliffs), so hills are used as a proxy.
- The effect is built **per hills terrain type**, each granting +1 Gold per **2
  adjacent tiles of that same type** (`EFFECT_TERRAIN_ADJACENCY`,
  `TilesRequired = 2`), applied to all the owner's Harbors.
- **Consequence 1 (the "phantom"):** because it keys off hills, not cliffs, any
  Harbor next to 2 same-type hills gets the bonus even with no cliffs present.
- **Consequence 2 (the "doesn't work"):** two adjacent hills of **different**
  types (e.g. Plains Hills + Desert Hills) never reach the 2-tile threshold of
  either per-type rule, so no bonus — most likely what the reporter observed.
- The wonder itself sits on Plains/Grass Hills, so its tiles *do* count toward
  the total when adjacent hills share a type.

**Decision:** the broad "all cliffs/hills boost Harbors" behavior is desirable
and intentionally **kept as-is**. Documented inline in the source and here
rather than changed. (A stricter "from the Cliffs of Dover wonder only" version
is possible via `MODTYPE_TM_FEATURE_ADJACENCY` on `FEATURE_CLIFFS_DOVER` — the
Ounianga pattern — but was deliberately not adopted.)

---

<a id="i10"></a>
### I10 — Wulingyuan: only +1 tourism, no culture; gated on Khmer?
**Category:** MAYBE-UE · **Status:** code verified correct; needs in-game repro
**Files:** `Core/Natural Wonders/Terra Mirabilis/TM_Wulingyuan_DLC6.sql`

**Symptom (2020 report):** Wulingyuan gives only +1 tourism to Great Works of
Writing and no culture; reporter suspected a Khmer-civ condition.

**Findings:**
- Intended effect: Writing Great Works get **+2 Culture** (`GW_YIELD`,
  `EFFECT_ADJUST_CITY_GREATWORK_YIELD`, YieldChange=2) and **+50% Tourism**
  (`GW_TOURISM`, `EFFECT_ADJUST_CITY_TOURISM`, ScalingFactor=150).
- **Both modifiers are validly authored** — verified against the Modding Companion
  and a dozen base-game `TRAIT_GREAT_WORK_*` traits that use the identical
  `GreatWorkObjectType + YieldType + YieldChange` flat-yield pattern (no
  `ScalingFactor` needed for a flat yield).
- **The Khmer theory is disproven:** the `EXISTS … CIVILIZATION_KHMER` gate is
  **redundant, not broken**. TM marks Wulingyuan `Required = DLC6`
  (`TM_Master.sql:677`), so the wonder only exists with DLC6, and with DLC6 present
  `CIVILIZATION_KHMER` always exists → the gate always passes for anyone who has the
  wonder. It also gates *both* effects equally, so it can't produce "tourism yes,
  culture no."

**Conclusion:** no identifiable defect in the mod's SQL. Report is likely stale or a
misobservation (the +2 Culture on a Writing Great Work is easy to miss). Cannot be
confirmed as a bug from static analysis — **needs in-game repro** (own Wulingyuan,
place a Writing Great Work, check for +2 Culture and +50% Tourism). Optional cosmetic
cleanup: drop the redundant Khmer gate (harmless; not done — no functional gain).

---

<a id="i11"></a>
### I11 — Grand Mesa: request for a better 3D model
**Category:** REQUEST · **Status:** wontfix (out of scope)
**Notes:** Purely an art/model enhancement request (suggested to resemble the Mt
Roraima flat-topped model). Out of scope for SQL bug-fixing and for the
"no new content" goal. Logged for completeness only.

**Unrelated effect bug found & fixed (commit c55ba07):** while fixing I7, noticed
Grand Mesa's "ignore Forest movement" effect had the identical `Ignore = 1` dead-
boolean bug (same custom `MODTYPE_TM_ADJUST_UNIT_IGNORE_TERRAIN`). Fixed to
`Ignore = true`. Two secondary observations left for later: the text says "Forest
or Jungle" but `Type` is only `FOREST`; and it says "Units trained in the City"
though the modifier applies to all player units (`COLLECTION_PLAYER_UNITS`).

---

<a id="i12"></a>
### I12 — Mount Roraima: "Onwer" typo in owner text
**Category:** BUG (trivial) · **Status:** fixed
**Files:** `Core/Localisation/TM_Localisation.sql`

**Symptom:** Roraima effect text (`LOC_TM_FEATURE_RORAIMA_EFFECT`) read
"**Onwed** Jungle tiles..." (the actual typo was "Onwed", not "Onwer").

**Resolution:** corrected to "Owned Jungle tiles...".

---

<a id="i13"></a>
### I13 — NW_ADJACENCY setting ignored (AND/OR operator precedence)
**Category:** FIXED-UPSTREAM · **Status:** verified (already in baseline)
**Files:** `Core/Natural Wonders/TM_Globals.sql`
**Fix commit:** upstream `e5f2c60` (wlyles PR #3), included in our baseline.

**Symptom:** With `NW_ADJACENCY` disabled in `TM_UserSettings.sql`, specialty
districts still received a standard adjacency bonus from natural wonders; for
the Holy Site it stacked with the base-game major adjacency (+3 total).

**Root cause & fix:** In the `INSERT ... INTO District_Adjacencies` statements,
`AND` bound tighter than `OR`, so the base district always matched and only the
unique-district branch respected the setting. Fix wraps the `OR` operands in
parentheses so the `AND EXISTS(... NW_ADJACENCY = 1 ...)` guard applies to the
whole condition. **This is already present in the final 2.21.3 code we baseline
from — no action needed.** (Confirms the reporter = the upstream PR author.)

---

<a id="i14"></a>
### I14 — Pamukkale still gives adjacency to Campus/Theater/Commercial Hub
**Category:** BUG / MAYBE-UE · **Status:** new
**Files:** `Core/Natural Wonders/XP2/TM_Pamukkale.sql`, `TM_Globals.sql`

**Symptom:** Reporter believes Pamukkale continues to grant its adjacency bonus
to Campuses, Theater Squares, and Commercial Hubs, possibly unintentionally.
Suspected fix is a `DELETE FROM District_Adjacencies` for the relevant
Pamukkale `YieldChangeId`(s), but reporter didn't know the ids.

**Next step:** determine intended Pamukkale adjacency behavior and which
`YieldChangeId`s apply; decide if a removal is warranted.

---

<a id="i15"></a>
### I15 — Resourceful 2 compatibility (LoadOrder conflict)
**Category:** COMPAT · **Status:** new
**Files:** `NaturalWondersMod.modinfo`

**Reported workaround (by @snackerfork):** In the modinfo, change the
`<LoadOrder>` for the `TM_Common` UpdateDatabase actions (TM_Common.sql,
TM_Common_XP1.sql, TM_Common_XP2.sql) from `11` to `56` to fix a conflict with
the *Resourceful 2* mod.

**Assessment:** This is a mod-vs-mod load-order interaction, not a standalone
bug. Bumping LoadOrder could have side effects on other load-order-sensitive
logic — needs thought before adopting. Consider whether to include, and whether
it belongs in the base mod vs. a separate compatibility note.

**Next step:** understand what TM_Common does at LoadOrder 11 and what breaks
under Resourceful 2 before changing it.

<a id="i16"></a>
### I16 — Ubsunur Hollow: Great General Inspiration never fires
**Category:** BUG (discovered while fixing I3) · **Status:** cause-found
**Files:** `Core/Natural Wonders/XP1/TM_Ubsunur_Hollow.sql`

**Symptom (found, not user-reported):** Ubsunur Hollow's advertised effect — "a free
Inspiration upon earning a Great General" — never fires.

**Cause:** same `MODTYPE_TM_GP_BOOST` (`EFFECT_GRANT_BOOST_WITH_GREAT_PERSON`) as
Krakatoa. Its args are `GreatPersonClass=GENERAL`, `OtherPlayers=0`, `TechBoost=0`.
For an *Inspiration* (civic boost) it needs a civic-boost flag set true; with
`TechBoost=0` and no civic flag, nothing is granted.

**Investigation (via Omar Khayyam, the base-game GP who grants both):** inspirations
are granted by a **separate effect family** — `EFFECT_GRANT_RANDOM_CIVIC_BOOST_BY_ERA`
(era-triggered on activation), NOT by the GP-*earned* boost effect. There is **no**
base-game "grant a civic boost when a Great Person is earned" effect; every GP-earned
boost effect is tech-only. So Ubsunur's advertised "Inspiration on Great General" has
no drop-in base effect.

**Confirmed not data-fixable (Civ VI Modding Companion 2.0 — full arg reference).**
`EFFECT_GRANT_BOOST_WITH_GREAT_PERSON` has exactly three args: `GreatPersonClass`
(String), `OtherPlayers` (Boolean), `TechBoost` (Boolean). **There is no `CivicBoost`
argument** — the effect is Eureka-only, so Ubsunur cannot grant an Inspiration through
it (a `CivicBoost=true` attempt would be silently ignored). The civic-boost effects that
do exist (`EFFECT_GRANT_RANDOM_CIVIC_BOOST_BY_ERA` / `_ON_NEW_ERA`) are era-triggered,
never "on Great Person earned." So there is **no data-driven way** to grant an Inspiration
when a Great Person is earned.

**Remaining options (all deliberate design calls, none a clean fix):**
1. Leave as a documented limitation (it was never user-reported).
2. Redesign Ubsunur to grant a **Eureka** instead (`TechBoost=true`) and reword its text.
3. Grant the Inspiration via a **Lua** script hooked to the Great-General-earned event.

**Status: won't-fix unless redesigned** — parked pending an owner decision.
