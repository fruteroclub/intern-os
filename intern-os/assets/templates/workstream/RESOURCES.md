# RESOURCES — [Workstream Name]

Artifact registry for this workstream. Two sections: the canonical resource table, and a heavy-asset pointer table.

## Resources

| Resource | Type | Location | Live URL | Owner | Status | Notes |
|----------|------|----------|----------|-------|--------|-------|

## Heavy assets (binary / non-text)

> **Pointer-only.** Heavy assets — images, audio, video, large PDFs (>~5MB), datasets, ML model weights, raw data exports — are *referenced* from this table, not embedded in `docs/`. They live either in `docs/assets/` of this workstream (preferred source-of-truth) or in external storage (Drive, S3, Git LFS, content-addressable store).
>
> **TM-export behavior:** When this workstream is exported as a Transfer Module:
> - Pointer rows in this table **travel** with the TM (text payload).
> - The **bytes** of heavy assets **do not travel** — they remain at the pointer location.
> - The receiver agent follows pointers if/when it needs an asset.
>
> Rationale: keeps TMs small + portable, avoids byte-duplication across exports, and matches how human collaborators already think about linked vs. embedded content.

| Asset | Kind | Location (in source) | External URL | Size | Notes |
|-------|------|----------------------|--------------|------|-------|

### Asset-Kind values

- `image` — PNG, JPG, SVG, WebP, etc.
- `audio` — MP3, WAV, OGG, podcast episodes.
- `video` — MP4, MOV, WebM, marketing reels, walkthroughs.
- `pdf-heavy` — PDFs > ~5MB; small textual PDFs may go in the main Resources table.
- `data` — CSV/Parquet/JSON datasets, fixtures.
- `model` — weights, checkpoints, embeddings.
- `archive` — ZIP/TAR bundles.
