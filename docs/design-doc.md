# 🎭 Theatre of the Mind - Design Document

*A text-based online game engine for exploring classic and remixed TTRPG adventures with interchangeable rulesets.*

---

## Design Tenets

* **Natural language first** — players type as if speaking to a DM.
* **Ruleset modularity** — adjudication logic is pluggable and swappable.
* **Content reskinnable** — structure, lore, and stats are cleanly separated.
* **Deterministic rules** — adjudication is reproducible and auditable, even if natural-language parsing isn’t.
* **Cost-aware LLM use** — models are used lightly, with caching and templates to stay affordable.
* **Scalable foundations** — clean separation keeps migration paths open (e.g., microservices).

---

## Vision

Theatre of the Mind is a multiplayer, largely text-driven online game where players interact with adventures in **natural language**, as though speaking to a Dungeon Master.

* **LLM-powered interpreter** converts free text into structured actions.
* **Rules engine** adjudicates those actions according to the currently active ruleset (e.g., B/X, PF2e, homebrew).
* **Adventure content** defines modules like *B1: In Search of the Unknown*, which can be played faithfully, reskinned, or transplanted into new settings.

This creates both:
    **Classic play**: authentic adventures under their original ruleset.
    **Toolbox play**: experimentation with “what if?” scenarios — new rulesets, settings, or remixed modules.

---

## Architecture Overview

Theatre of the Mind is layered to keep game logic portable and avoid lock-in. The system is built around three cooperating layers:

### Theatre Core

Theatre Core is the conceptual center of the project. It defines the common structures for content, rules, and orchestration. At this stage it does not need to be a standalone Python package or a separate service. Instead, it is a logical boundary within the codebase that keeps core ideas (how adventures, rules, and state transitions work) distinct from any particular runtime implementation.

Theatre Core responsibilities:

* Define the content model (rooms, exits, objects, scripts/behaviours).
* Define the rules model (adjudication, resolution of actions, dice mechanics, etc.).
* Provide clear interfaces that can be called from any runtime (Evennia today, possibly microservices or other engines later).
* Optionally host orchestration logic (for example, the LLM Orchestrator, which converts natural language to an IR (JSON)), whether as in-process code or something that could be spun out separately in the future.

### Runtime Adapter (Evennia)

Evennia is the initial runtime environment. It provides:

* A MUD server with accounts, sessions, commands, persistence.
* Core abstractions (Rooms, Exits, Objects, Scripts) that map naturally onto adventure content.
* Standard player commands (look, movement, interaction) with minimal changes needed. The LLM Orchestrator will map intents onto these commands.

The adapter layer bridges Theatre Core concepts into Evennia entities. For example:

* A Core “room” becomes an Evennia Room object with attributes and description.
* A Core “exit” becomes an Evennia Exit with locks and dynamic state.
* A Core “interaction” becomes an Evennia Script or Object method.

By keeping the mapping explicit, the system avoids burying game logic inside Evennia-specific code, preserving the option to replace Evennia later.

### Adventure Content

Adventure modules (like B1) are maintained in human-readable source files (currently Markdown). That text is gradually transformed into structured data which the runtime adapter can build into Evennia entities.

The goals for adventure content are:

* Keep a canonical source of truth (easy to read, edit, and diff).
* Define a reproducible build process from source → structured data → runtime world.
* Ensure that content is not locked to Evennia, even though it is imported as native Evennia objects during play.

---

## Adventure Content Layering

Adventures are designed with **three conceptual layers**, kept distinct so they can be recombined:

* **Structure** — the skeleton: maps, rooms, connections, triggers, and challenge bands (e.g., “easy check” vs “hard check”), without ruleset-specific numbers.
* **Lore** — the words, names, and story flavor. Multiple variants can exist (e.g., original module text, paraphrased safe text, alternate settings).
* **Stats** — the ruleset-specific numbers (monster stat blocks, trap DCs, treasure values), expressed per ruleset.

This separation allows:

* Running the same adventure under multiple rulesets without duplication.
* Reskinning modules into different settings while keeping mechanics intact.
* Preserving authenticity (original lore + original stats) while enabling remix play (alternate lore + different ruleset).

---

## Rulesets & Flexibility

A core goal of *Theatre of the Mind* is to **experience how rulesets shape play**.

* Implementing different rulesets (e.g., B/X, 3.5e, PF2e) shows how mechanics evolved over time.
* Running a classic module in its original ruleset captures historical authenticity.
* Swapping in a modern ruleset reveals how later design choices change pacing, challenge, and narrative.
* Reskinning a module into a different setting shows how **lore and mechanics interact**.

This isn’t about rigid “modes of play.” Instead, it’s a **toolbox**:

* Choose a module.
* Choose a ruleset.
* Choose a lore/setting skin.
* …and see how those choices transform the experience.

---

## Persistence & Player Interaction

The system supports:

* **Solo play** (one player controlling multiple characters).
* **Small-party multiplayer.**
* **Optional DM presence** (via reserved commands or narrative input).

Adventures can run as **per-party instances** (replayable, fair), with optional future support for **shared or persistent spaces** (where multiple parties’ actions affect the same world).

---

## LLM Usage & Cost Strategy

As a hobby project, LLM usage must remain **affordable and efficient**.

* **Interpretation only:**
    * LLMs parse natural language into IR.
    * Rules engine and templates handle adjudication and narration.

* **Lightweight models by default:**
    * Smaller/cheaper models (or local ones) handle routine parsing.
    * Larger models only for richer narrative, if needed.

* **Cache and reuse:**
    * Store `(utterance → IR)` mappings to avoid repeated LLM calls.
    * Template narration where possible.
  
* **Tight context windows:**
    * Only relevant state is passed to the LLM.
    * Retrieval supplies precise lore/stats instead of whole modules.

* **Predictable costs:**
    * One action ≈ 200–300 tokens.
    * Multi-hour sessions should cost only pennies with small models.
    * Token usage per session is logged for visibility.

---

## Scaling Philosophy

* **Now:** One Evennia server with adventure bundles.
* **Later:** Keep `theatre_core` pure and portable, define JSON contracts, and design around stable IDs.
* This ensures migration to custom servers or microservices is possible without rewriting adventures or rules.

---

## Legal & Content Strategy

* **For private/testing:** classic modules and rulesets may be used.
* **For public/shareable:** provide paraphrased lore, open-content SRD mechanics, or original settings.
* Grey content is kept in isolated lore/stats files so it can be swapped out cleanly.

---

## Near-Term Goal

The first milestone is modest but foundational:

* Play through one module (*B1: In Search of the Unknown*)
* Using its original ruleset (B/X)
* With content converted into machine-readable form (structure + lore + stats).

This validates the **utterance → IR → adjudication → narration** pipeline and proves that Evennia + Theatre Core can deliver a complete playable adventure loop.

---

## Summary

Theatre of the Mind is:

* A **learning project** and **personal play space.**
* An **engine/toolbox** for experimenting with modules and rulesets.
* Built for both **nostalgia** (classic adventures) and **experimentation** (remixes, ruleset swaps).
* Designed to keep **LLM usage affordable** and rules deterministic.
* Architected so it can grow from “one server, one dungeon” to larger worlds without painful rewrites.
