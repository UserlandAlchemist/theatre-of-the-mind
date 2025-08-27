# Author’s Quickstart: Adventure Modules

This is a one-page guide for writing new adventures in *Theatre of the Mind* using the JSON layering system.

---

## 1. Folder Setup

Each adventure lives under `adventures/<id>/`:

```text
adventures/
  beacon-enon-tor/
    metadata.json
    structure/
      ground-floor.json
      tower.json
      cellar.json
    lore/
      canonical/
        ground-floor.json
        tower.json
        cellar.json
    stats/
      ose-basic/
        actors.json
    assets/
      map.webp
```

---

## 2. Metadata

`metadata.json` declares identity, defaults, and map scale:

```json
{
  "id": "beacon-enon-tor",
  "title": "The Beacon at Enon Tor",
  "summary": "Relight a coastal beacon tower.",
  "map_scale": { "square_size_ft": 10 },
  "default_lore": "canonical",
  "default_stats": "ose-basic",
  "regions": ["ground-floor", "tower", "cellar"]
}
```

---

## 3. Structure

* Each region file in `structure/` is a **list of entities**.  
* Every entity declares a `type` (room, exit, actor, item, quest, overlay, feature).  
* Some also declare a `subtype` (e.g. door, stairs, tunnel; pool, webs, pit).

```json
[
  {
    "id": "g1",
    "structure": {
      "type": "room",
      "shape": "rectangle",
      "grid": { "width": 3, "length": 2, "height": 1 },
      "exits": [
        { "to": "g2", "type": "exit", "subtype": "door",
          "position": { "mode":"wall","wall":"east","offset_squares":1 } },
        { "to": "t6", "type": "exit", "subtype": "stairs",
          "position": { "mode":"wall","wall":"up" } }
      ]
    },
    "lore_key": "room.g1",
    "stats_key": "room.g1"
  }
]
```

### Quick Geometry & Exit Example

Here’s how to describe a simple 3×3 rectangular room with a single door to the north.

```json
{
  "id": "hall",
  "structure": {
    "type": "room",
    "shape": "rectangle",
    "grid": { "width": 3, "length": 3 },
    "exits": [
      {
        "to": "antechamber",
        "type": "exit",
        "subtype": "door",
        "position": {
          "mode": "wall",
          "wall": "north",
          "offset_squares": 1
        }
      }
    ]
  },
  "lore_key": "room.hall"
}
```

* The exit is an **exit of subtype “door”** on the north wall, placed one square in from the western corner.  
* Exits default to **1 square wide**; add `width_squares` if wider.  
* Facing is implied by wall mode (north wall → facing north, etc.).  
* All distances are in **grid squares**, not absolute measurements.

---

## 3.1 Canonical authoring rules (do this every time)

**IDs & keys**
- Region prefixes: `g` (ground), `t` (tower), `c` (cellar).
- Rooms use the printed numbers: `g1`, `g2`, …; `t6–t9`; `c10–c13`.
- Features: `feature.<noun>.<room-id>.<index>`; Items: `item.<noun>.<room-id>.<index>`.
- Encounters: `enc.<room-id>.<slug>`.
- Lore/Stats keys mirror IDs with type prefixes (e.g., `room.g1`).

**Ordering (for clean diffs)**
- In each `structure/<region>.json`: sort by ID, then by `structure.type`.
- In `room.exits`: sort by `north, east, south, west, up, down` + `offset_squares`.
- In lore/stats files: keep keys in lexical order.

**Coordinates**
- SW origin `(0,0)`; `x` east, `y` north.  
- Use **wall mode** only on rectangles; irregular rooms require explicit `grid` positions.

**Empty rooms**
- If a space is keyed on the map, include a `room` entity even if empty.

**Towers & exterior**
- For stacked floors, add `room_attrs.floor_index`.  
- For roof/yard/open-air, set `room_attrs.exterior: true`.

---

## 3.2 Micro-checklist (LLM or human)

1) Make the `room` (shape, `grid`, optional `footprint`, optional `room_attrs`).  
2) Add `exits` (validate targets later if needed).  
3) Add `features` → `items` → `encounters`.  
4) Assign `lore_key` / `stats_key` as needed (or omit).  
5) Sort entities and exits per the ordering rules.  

**Common lint codes**: `E020` exit off perimeter, `E031` vertical target missing, `E041` containment cycle, `W101` missing lore, `W102` missing stats.

---

## 4. Lore

Each variant in `lore/` mirrors the regions.  
Maps `lore_key` → text.

```json
{
  "room.g1": {
    "name": "Entrance Hall",
    "desc": "A heavy wooden door opens into a cold stone hall.",
    "gm_notes": "Noise here can alert g3."
  }
}
```

---

## 5. Stats

Each ruleset in `stats/` contains keyed data.  
Split into `actors.json`, `items.json`, `traps.json` for convenience.

```json
{
  "actor.bugbear-guard": { "hp": 16, "ac": 15, "attack": "1d8", "morale": 8 }
}
```

---

## 6. Keys

* **IDs**: short unique codes (`g1`, `t6`, `c10`).  
* **Lore keys**: `room.g1`, `actor.bugbear-guard`.  
* **Stats keys**: mirror lore keys, type-prefixed if needed (`trap.loose-stair`).  
* If a `lore_key` or `stats_key` is omitted, the entity has no attached lore/stats in that pack.

---

## 7. Workflow

1. Write `structure/*.json` for each region.  
2. Add lore packs in `lore/<variant>/`.  
3. Add rulesets in `stats/<ruleset>/`.  
4. Run linter/loader → full adventure = Structure + Lore + Stats.

---

## Appendix A — Irregular footprint recipe

1) Minimal bounding `width × length`.  
2) Binary `footprint` array (1 = traversable).  
3) Exits only where a 1-cell touches exterior.  
4) No wall mode on irregular rooms.

## Appendix B — Where are the schemas?

See `docs/adventure-format/adventure-module-spec.md` (JSON Schema section) for abridged definitions. Full JSON Schemas may live in `docs/adventure-format/schema/` and are enforced by the linter.
