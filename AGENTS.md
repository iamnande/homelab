# homelab agent instructions

- this repo is public. never name the deploy product behind sector7, and never
  write down a host's open security gaps. those live in the private senzu repo.
- `docs/` is the book and the only prose. don't add readmes elsewhere.
- a host changes through its manifest: edit `hosts/<host>/`, then nick runs
  `bin/apply`. agents run `bin/drift` and never sudo.
- every change to a host gets a dated row in its record.
- packages are arch native, one list per host, and each line says what asks
  for it.
- keep automation thin: plain bash, no framework. rocinante may move to nixos.
- commands in the book run in both bash and fish.
- terms: host, book, spec, record, manifest, apply, drift, roadmap. they are
  defined in `docs/README.md`.

## maintaining these instructions

keep only rules that change behavior in this repo. prune before appending.
