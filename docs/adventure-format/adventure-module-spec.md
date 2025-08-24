# Adventure Module Data Specification

Adventures in *Theatre of the Mind* are encoded in JSON using three separate layers:

* **Structure** → the skeleton: rooms, connections, items, actors, quests, triggers, challenge bands.  
* **Lore** → the words: names, descriptions, boxed text, GM notes. Multiple variants are possible (canonical text, paraphrased safe text, reskinned settings).  
* **Stats** → ruleset-specific numbers: monster stat blocks, trap DCs, treasure values. Multiple rulesets are supported side-by-side.

These layers are kept separate so they can be recombined at runtime. For example, the *Beacon at Enon Tor* structure can be run with canonical lore + OSE stats, or with sci-fi lore + 2e stats, without modifying the base files.

---

## Directory Layout

Each adventure has its own folder under `adventures/`. Inside are three subfolders plus metadata and assets:

```text
adventures/
  <adventure-id>/
    metadata.json
    structure/
      <region>.json
      ...
    lore/
      <variant>/
        <region>.json
        ...
    stats/
      <ruleset>/
        actors.json
        items.json
        traps.json
    assets/
      map.webp
      illustrations.png
```

* **metadata.json** → top-level identity and configuration.  
* **structure/** → split by region (floor, level, area). Each file is an array of structured entities.  
* **lore/** → one subfolder per lore variant, with region files mirroring structure.  
* **stats/** → one subfolder per ruleset, with entity stats split by type.  
* **assets/** → optional maps, images, handouts.  

---

## File Specifications

### 1. `metadata.json`

Declares the adventure ID, title, default lore/stats packs, and map scale.

```json
{
  "id": "beacon-enon-tor",
  "title": "The Beacon at Enon Tor",
  "summary": "A small coastal tower adventure.",
  "map_scale": { "square_size_ft": 10 },

  "author": "Terry K. Author",
  "source": {
    "publication": "Imagine Magazine #1",
    "publisher": "TSR UK",
    "year": 1983,
    "pages": "4–9"
  },

  "recommended_level": { "min": 1, "max": 2 },
  "recommended_party_size": { "min": 4, "max": 6 },
  "recommended_party_composition": [
    {
      "requirement": "at_least_one",
      "role": "arcane",
      "examples": ["elf", "magic-user"]
    },
    {
      "requirement": "optional",
      "role": "healer",
      "examples": ["cleric"]
    }
  ],

  "expected_play_time": {
    "sessions": { "min": 1, "max": 2 },
    "hours_per_session": 3
  },

  "default_lore": "canonical",
  "default_stats": "ose-basic",
  "regions": ["ground-floor"]
}
```

**Field notes:**

* `author`: The module’s credited author(s).  
* `source`: Details about the original publication (title, publisher, year, and page range).  
  * Use this to preserve bibliographic info, not as a license statement.  
* `recommended_party_composition`: Structured guidance on what mix of roles is expected.  
  * `requirement` may be `at_least_one`, `recommended`, or `optional`.  
  * `role` should be a generic tag (`arcane`, `healer`, `frontline`, `scout`, etc.) so it can map across systems.  
  * `examples` list system-specific classes or archetypes.  
* `expected_play_time`: If the original module specifies how long the adventure should take, capture it here.  
  * Expressed as sessions (with min/max) and estimated `hours_per_session`.  
  * Useful for analytics — we can compare “paper” expectations vs actual runtime.

### 2. `structure/<region>.json`

* A list of structural entities: rooms, corridors, stairs, actors, items, quests.  
* Each entry contains only geometry, abstract properties, and references to lore/stats keys.  
* Every entity must declare a `type`.  
* Optional `subtype` refines the entity (e.g. `type=exit`, `subtype=door`).  
* If `lore_key` or `stats_key` is omitted, the entity has no attached lore/stats.

Example room:

```json
{
  "id": "g1",
  "structure": {
    "type": "room",
    "shape": "rectangle",
    "grid": { "width": 3, "length": 2, "height": 1 },
    "exits": [
      {
        "to": "g2",
        "type": "exit",
        "subtype": "door",
        "position": { "mode":"wall","wall":"east","offset_squares":1 },
        "state": { "locked": false }
      },
      {
        "to": "t6",
        "type": "exit",
        "subtype": "stairs",
        "position": { "mode":"wall","wall":"up" }
      }
    ]
  },
  "lore_key": "room.g1",
  "stats_key": "room.g1"
}
```

### 📐 Room Geometry & Exits

Rooms are defined relative to their own **local grid**, with the **south-west (SW) corner as origin (0,0)**.  
No absolute world coordinates are used — geometry is always local to the room.

#### Geometry

* **Rectangular rooms**

```json
{
  "grid": {
    "width": 3,
    "length": 2,
    "height": 1
  }
}
```

* **Irregular footprints**  
Add an optional `footprint` mask if the room isn’t a clean rectangle:  

```json
{
  "grid": {
    "width": 3,
    "length": 3,
    "footprint": [
      [1,1,1],
      [1,0,0],
      [1,1,1]
    ]
  }
}
```

#### 📐 Exit Positioning

Every exit links one room to another and must specify where it sits on the local grid.  

There are **two positioning modes**:

##### 1. Grid Mode (canonical, works everywhere)

```json
{
  "to": "antechamber",
  "type": "exit",
  "subtype": "door",
  "position": {
    "mode": "grid",
    "x": 2,
    "y": 0,
    "facing": "north"
  }
}
```

##### 2. Wall Mode (shorthand for rectangles only)

```json
{
  "to": "antechamber",
  "type": "exit",
  "subtype": "door",
  "position": {
    "mode": "wall",
    "wall": "north",
    "offset_squares": 1,
    "width_squares": 2
  }
}
```

**Loader rule:** Wall mode must be internally converted to the equivalent `grid` form. Facing is implied by wall mode (north wall → facing north, etc.).

##### Examples

###### Door on north wall, second square from west corner

```json
"position": { "mode": "wall", "wall": "north", "offset_squares": 1 }
```

→ canonical equivalent:

```json
"position": { "mode": "grid", "x": 1, "y": 2, "facing": "north" }
```

###### Wide tunnel mouth in cavern

```json
"position": { "mode": "grid", "x": 18, "y": 6, "facing": "east" },
"width_squares": 3
```

###### Vertical stairs using grid mode

```json
{ "to": "tower", "type": "exit", "subtype": "stairs",
  "position": { "mode": "grid", "x": 1, "y": 2, "facing": "up" } }
```

### 3. `lore/<variant>/<region>.json`

Maps `lore_key` → textual descriptions.  
Multiple variants may exist; runtime selects one.

```json
{
  "room.g1": {
    "name": "Entrance Hall",
    "desc": "A heavy wooden door opens into a cold stone hall. Drafts tug at old banners.",
    "gm_notes": "Noise here can alert g3."
  }
}
```

### 4. `stats/<ruleset>/*.json`

Maps `stats_key` → ruleset-specific numbers.  
Split into files (actors, items, traps) for easier editing.

```json
{
  "actor.bugbear-guard": {
    "hp": 16,
    "ac": 15,
    "attack": "1d8",
    "morale": 8
  }
}
```

---

## ID and Key Conventions

* **IDs**: unique within an adventure. Prefix with region (`g1`, `t6`, `c10`).  
* **Lore keys**: hierarchical, prefixed by type (`room.g1`, `actor.bugbear-guard`).  
* **Stats keys**: mirror lore keys where practical; add type prefixes for clarity (`trap.loose-stair`).  

---

## Loader Rules

When an adventure is loaded:

1. Read `metadata.json`.  
2. Load all files under `structure/` and merge into one internal model. Validate unique IDs.  
3. Choose a lore pack (default or specified) and merge region files by `lore_key`. Missing entries issue warnings.  
4. Choose a stats pack (default or specified) and merge by `stats_key`. Missing entries issue warnings.  
5. Attach lore + stats to structure entities → full runtime representation.  

---

## Validation

### General
* Unique IDs across structure.  
* Every entity has `type`; `subtype` required if `type = exit`, `overlay`, or `feature`.  
* Grid dimensions ≥ 1.  

### Exits
* All `exits[].to` target valid IDs.  
* Wall mode may only be used on rectangular rooms.  
* `offset_squares + width_squares` must not exceed wall length.  
* Facing is implied in wall mode.  

### Grid placement
* Grid coordinates must lie on the room footprint and touch an exterior boundary.  
* Vertical exits (`up`/`down`) don’t require `x,y`, but may specify them if useful.  
* Multi-square exits must use `width_squares`.  

### Lore/Stats
* All `lore_key` exist in chosen lore pack.  
* All `stats_key` exist in chosen stats pack (for actors/items).  

---

## Advantages of Layering

* **Reusability**: one structure supports multiple lore or stats overlays.  
* **Licensing safety**: paraphrased lore can be published without infringing original text.  
* **System neutrality**: same structure runs under OSE or 5e stats packs.  
* **Scalability**: small JSON files per region are easy to author, diff, and validate.  

---

✅ With this convention, *The Beacon at Enon Tor* can be encoded in ~3 region files, with lore and stats layered on top.  
✅ Larger adventures (like *B1*) can split into many region files without the JSON ever becoming unwieldy.  
