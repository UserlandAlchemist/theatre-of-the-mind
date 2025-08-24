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
        { "to": "g2", "type": "exit", "subtype": "door", "position": { "mode":"wall","wall":"east","offset_squares":1 } },
        { "to": "t6", "type": "exit", "subtype": "stairs", "position": { "mode":"wall","wall":"up" } }
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

That’s it — start small (one room, one monster, one quest) and expand.  
