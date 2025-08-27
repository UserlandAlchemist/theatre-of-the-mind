# Adventure Module Data Specification

Adventures in *Theatre of the Mind* are encoded in JSON using three separate layers:

* **Structure** → the skeleton: rooms, connections, items, actors, quests, triggers, challenge bands.  
* **Lore** → the words: names, descriptions, boxed text, GM notes. Multiple variants are possible (canonical text, paraphrased safe text, reskinned settings).  
* **Stats** → ruleset-specific numbers: monster stat blocks, trap DCs, treasure values. Multiple rulesets are supported side-by-side.

These layers are kept separate so they can be recombined at runtime. For example, the *Beacon at Enon Tor* structure can be run with canonical lore + OSE stats, or with sci-fi lore + 2e stats, without modifying the base files.

## Layer responsibilities (normative)

- **Structure** = geometry and object graph only. It declares:
  - spaces (rooms/corridors), connections (exits), and relative placement;
  - durable features/furniture, containers, light sources;
  - minimal state flags that change access or perception (`locked`, `hidden`, `lit`);
  - grouping relationships (e.g., encounter contains actors).
  - **Structure never encodes numeric mechanics, prices, XP, or descriptive prose.**
- **Lore** = names and text (boxed text, GM notes) for anything declared in structure.
- **Stats** = system mechanics for actors/items/traps and any rules effects; may map an item to a mechanical archetype (e.g., “meat cleaver counts as hand axe”).

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
* **Canonical ordering requirement** (normative): authors MUST keep keys in deterministic order to ensure stable diffs and reproducible builds.
  - In `structure/<region>.json`, entities are sorted by ID (e.g., `g1`, `g2`, …), then by `structure.type`.
  - Within a `structure.room.exits` array, exits are sorted by wall order `north, east, south, west, up, down`, then by `offset_squares` (ascending).
  - In `lore/<variant>/*.json` and `stats/<ruleset>/*.json`, object keys are serialized in lexical order.
  The loader may re-order on import; authors should still follow this rule.
* **ID & key recipe** (normative):
  - Region prefixes: `g` (ground), `t` (tower), `c` (cellar).
  - Rooms use the printed map numbers: `g1`, `g2`, …; `t6–t9`, `c10–c13`, etc.
  - Features: `feature.<noun>.<room-id>.<index>` (e.g., `feature.bench.g1.1`).
  - Items: `item.<noun>.<room-id>.<index>`.
  - Encounters: `enc.<room-id>.<slug>` (e.g., `enc.g3.bugbear-guards`).
  - Lore keys are type-prefixed mirrors, e.g., `room.g1`, `actor.bugbear-guard`.
  - Stats keys mirror lore keys; types may be added for clarity, e.g., `trap.loose-stair`.
* **Empty keyed rooms** (normative): if a space is keyed on the map, it MUST be represented as a `room` entity even if initially empty of encounters or items.
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
* Optional `subtype` refines the entity (e.g. `type=exit`, `subtype=door`; `type=feature`, `subtype=bed`).  
* Any entity may carry a `position` field.  
* Minimal `state` flags are allowed (`locked`, `hidden`, `lit`, `filled`).  
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

### 📐 Geometry & Positioning

Rooms are defined relative to their own **local grid**, with the **south-west (SW) corner as origin (0,0)**.  
No absolute world coordinates are used — geometry is always local to the room.

**Rectangular rooms**

```json
{ "grid": { "width": 3, "length": 2, "height": 1 } }
```

**Irregular footprints**

```json
{ "grid": { "width": 3, "length": 3,
  "footprint": [
    [1,1,1],
    [1,0,0],
    [1,1,1]
  ] } }
```

**Positioning (universal)**

Any entity may declare a position on its room grid:

```json
"position": { "mode": "grid", "x": 2, "y": 1, "facing": "north" }
```

**Wall shorthand (rectangles only)**

```json
"position": { "mode": "wall", "wall": "north", "offset_squares": 1 }
```

Loader rule: wall mode must be converted internally to canonical grid form.  
**Exit placement rules (normative)**

* For rectangles, `offset_squares` counts from the **western corner** of the named wall.
* An exit is valid iff all edge cells it occupies are on the **perimeter** and **contiguous**.
* `width_squares` defaults to `1` if omitted.
* Vertical exits (`up`/`down`) may omit `x,y`. If provided, they must lie on the footprint but **need not** touch perimeter.
* Wall mode MUST NOT be used on irregular rooms; use explicit `grid` placement.

---

### Structural entity subtypes

- `type: "feature"` → `subtype: bed|table|bench|shelf|fireplace|tapestry|light|altar|desk|chest`
- `type: "item"` → movable object, no mechanics here.
- `type: "encounter"` → groups actors and sets an initial situation.

Example encounter:

```json
{ "id":"enc.orc-pair", "structure":{
    "type":"encounter",
    "actors":["actor.orc-a","actor.orc-b"],
    "initial_behavior":"distracted-arguing"
}}
```

### Containers & state

```json
{ "id":"item.iron-box", "structure":{
    "type":"item", "subtype":"container",
    "parent_id":"feature.bed",
    "state": { "hidden":true, "locked":true },
    "container": { "contains":["item.silver-dagger","coin.gp.57"] }
}}
```

- `state` keys allowed: `locked`, `hidden`, `lit`, `filled`.
- `parent_id` links to a containing/covering feature (e.g., under a bed).
- Numerical DCs/values are stats-only.
- **Containment rules (normative):**
  - `parent_id` MUST reference an entity **in the same room**.
  - `container.contains` IDs MUST resolve within the same adventure.
  - Cycles across `parent_id` / `container.contains` are **invalid**.

### Room attributes (structure-only)

Rooms may include structure flags that aid rules and rendering without adding lore/mechanics:

```json
"room_attrs": { "floor_index": 0, "exterior": false }
```

* `floor_index` orders stacked floors (e.g., tower levels), counted from lowest = 0.
* `exterior` = `true` for open-air spaces (e.g., beacon top).

### Light sources

- `feature: light` with `state.lit`.  
- Optional `overlay` of subtype `light` for ambient room light.

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

Stats may also map item IDs to mechanical archetypes:

```json
{ "item.meat-cleaver": { "counts_as": "weapon.hand-axe" } }
```

Structure must never include `counts_as`.

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

### Position & containment
* `position` may be present on any entity. If present, it must be inside the room footprint.
* `parent_id` targets must exist in the same room unless loader allows cross-room references.
* `container.contains` IDs must exist and resolve within the adventure.
* Allowed structural `state` keys: `locked`, `hidden`, `lit`, `filled`.

### Lore/Stats
* All `lore_key` exist in chosen lore pack.  
* All `stats_key` exist in chosen stats pack (for actors/items).  

---

## Authoring Guidance for Irregular Rooms (normative)

When a printed room is irregular:

1. Choose the minimal bounding `width × length`.
2. Provide a binary `footprint` array with `1` = traversable square, `0` = void.
3. Place exits only where a `1` cell touches the room exterior.
4. Do not use wall mode; specify exit positions with exact `grid` coordinates.

This ensures consistent geometry across tools and prevents ambiguous “inset” doors.

---

## Vocab & Enums (normative)

**structure.type**
- `room`, `exit`, `feature`, `item`, `encounter`, `overlay`

**exit.subtype**
- `door`, `secret-door`, `portcullis`, `stairs`, `ladder`, `trapdoor`, `tunnel`

**feature.subtype**
- `bed`, `table`, `bench`, `shelf`, `fireplace`, `tapestry`, `light`, `altar`, `desk`, `chest`

**overlay.subtype**
- `light`, `fog`, `sound`, `scent`

**position.facing**
- `north`, `east`, `south`, `west`

---

## Loader Canonicalization (normative)

On import, the loader MUST:
1. Convert all wall-mode positions to explicit grid positions.
2. Enforce ordering rules (entities, exits, map/object keys).
3. Emit consistent serialization (no `null`; absent fields are omitted).

---

## Lint Codes

**Errors**
- `E001` duplicate id
- `E020` exit not on perimeter (rectangles)
- `E021` wall mode used on irregular room
- `E031` vertical target missing / invalid
- `E041` containment cycle detected
- `E051` invalid footprint dimensions

**Warnings**
- `W101` missing `lore_key`
- `W102` missing `stats_key`
- `W111` non-canonical ordering fixed by loader

---

## JSON Schemas (abridged, normative)

> These schemas are machine-readable constraints the linter enforces. Full files may live under `docs/adventure-format/schema/`.

```json
{
  "$id": "structure.entity.json",
  "type": "object",
  "required": ["id", "structure"],
  "additionalProperties": false,
  "properties": {
    "id": { "type": "string", "pattern": "^[A-Za-z0-9._-]+$" },
    "lore_key": { "type": "string" },
    "stats_key": { "type": "string" },
    "structure": {
      "type": "object",
      "required": ["type"],
      "additionalProperties": false,
      "properties": {
        "type": { "enum": ["room","exit","feature","item","encounter","overlay"] },
        "subtype": { "type": "string" },
        "shape": { "enum": ["rectangle","irregular"] },
        "grid": {
          "type": "object",
          "required": ["width","length"],
          "additionalProperties": false,
          "properties": {
            "width": { "type": "integer", "minimum": 1 },
            "length": { "type": "integer", "minimum": 1 },
            "height": { "type": "integer", "minimum": 1 },
            "footprint": {
              "type": "array",
              "items": { "type": "array", "items": { "enum": [0,1] } }
            }
          }
        },
        "room_attrs": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "floor_index": { "type": "integer" },
            "exterior": { "type": "boolean" }
          }
        },
        "exits": {
          "type": "array",
          "items": { "$ref": "#/$defs/exit" }
        },
        "position": { "$ref": "#/$defs/position" },
        "state": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "locked": { "type": "boolean" },
            "hidden": { "type": "boolean" },
            "lit": { "type": "boolean" },
            "filled": { "type": "boolean" }
          }
        }
      }
    }
  },
  "$defs": {
    "position": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "mode": { "enum": ["grid","wall"] },
        "x": { "type": "integer", "minimum": 0 },
        "y": { "type": "integer", "minimum": 0 },
        "facing": { "enum": ["north","east","south","west"] },
        "wall": { "enum": ["north","east","south","west","up","down"] },
        "offset_squares": { "type": "integer", "minimum": 0 },
        "width_squares": { "type": "integer", "minimum": 1 }
      },
      "required": ["mode"]
    },
    "exit": {
      "type": "object",
      "required": ["to","type","subtype"],
      "additionalProperties": false,
      "properties": {
        "to": { "type": "string" },
        "type": { "const": "exit" },
        "subtype": {
          "enum": ["door","secret-door","portcullis","stairs","ladder","trapdoor","tunnel"]
        },
        "position": { "$ref": "#/$defs/position" },
        "state": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "locked": { "type": "boolean" },
            "hidden": { "type": "boolean" }
          }
        },
        "width_squares": { "type": "integer", "minimum": 1 }
      }
    }
  }
}
```

## Advantages of Layering

* **Reusability**: one structure supports multiple lore or stats overlays.  
* **Licensing safety**: paraphrased lore can be published without infringing original text.  
* **System neutrality**: same structure runs under OSE or 5e stats packs.  
* **Scalability**: small JSON files per region are easy to author, diff, and validate.  

---

✅ With this convention, *The Beacon at Enon Tor* can be encoded in ~3 region files, with lore and stats layered on top.  
✅ Larger adventures (like *B1*) can split into many region files without the JSON ever becoming unwieldy.
