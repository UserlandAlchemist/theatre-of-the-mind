# 📦 Internal Archives (Private Content Overlay)

This project supports two bundles:

- **Public**: safe to distribute; contains only tracked repo files.
- **Internal**: includes a private overlay (`private/`), for research and AI-assisted work; *not for redistribution*.

## Archive Process

* Archives are produced using the `./scripts/make-archive.sh` script.
* By default, archives are placed in `~/dist` (moved out of the project folder).
* If no flag is supplied, the script defaults to creating an internal archive.
* Each archive now includes a short git log of the last 10 commits in the root of the zip file.

## Building

Use the script:

```
./scripts/make-archive.sh
./scripts/make-archive.sh public
```


Example outputs:

```
theatre-of-the-mind-public-20250817-1902-a1b2c3d.zip
theatre-of-the-mind-internal-20250817-1902-a1b2c3d.zip
```

Notes:

* archive_excludes.txt governs which files are excluded from builds.

## Safety

- `private/` is ignored by the public repo; it won’t be pushed.
- Internal bundles are for personal research only. Do **not** publish or attach to public releases.
