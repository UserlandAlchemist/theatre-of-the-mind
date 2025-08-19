# 📦 Internal Archives (Private Content Overlay)

This project supports two bundles:

- **Public**: safe to distribute; contains only tracked repo files.
- **Internal**: includes a private overlay (`private/`), for research and AI-assisted work; *not for redistribution*.

## Structure & Naming

Internal bundles are named:

```
theatre-of-the-mind-internal-YYYYMMDD-HHMM-<gitshort>.zip
```

Inside the zip, private content is staged under:

```
docs/private/**
# e.g., docs/private/b1/b1-clean.md
```

## Building

Use the script:

```
./scripts/make-archive.sh public
./scripts/make-archive.sh internal
```

Example outputs:

```
dist/theatre-of-the-mind-public-20250817-1902-a1b2c3d.zip
dist/theatre-of-the-mind-internal-20250817-1902-a1b2c3d.zip
```

Notes:

- Each run wipes `dist/` and rebuilds.
- The internal build overlays `private/` into `docs/private/` and excludes VCS junk (`.git`, `.gitignore`, `.gitattributes`, `.DS_Store`, `Thumbs.db`).
- The staging directory is removed unless `KEEP_STAGING=1` is set.

## Safety

- `private/` is ignored by the public repo; it won’t be pushed.
- Internal bundles are for personal research only. Do **not** publish or attach to public releases.
