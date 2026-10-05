# homelab

this book documents the lab: the network, the hosts on it, and what is
planned. it is the only prose in the repo.

the lab is designed for safe experimentation with enterprise patterns.
everything flows through the gateway — a single point to enforce segmentation,
policies, and observability.

| page | covers |
| --- | --- |
| [network](network.md) | the gear, the vlans, and how they are kept apart |
| [hosts](hosts/README.md) | the machines and what each one is for |
| [roadmap](roadmap.md) | what does not exist yet |
| plans | the plan docs behind each change, under `prds/` |

## terms

| term | means |
| --- | --- |
| host | a physical machine with a name |
| book | this. the only prose docs; the repo readme points at it |
| spec | what a host needs and why, os-agnostic |
| record | a host's dated build log. history, append-only |
| manifest | a host's package lists, files and units. what `apply` applies |
| apply | make the host match its manifest |
| drift | report where a host and its manifest differ |
| roadmap | one page for things that do not exist yet |

## reading it

the pages read fine on github. for the rendered book, from the repo root:

```
mdbook-mermaid install .
mdbook serve --open
```

the first command writes the two mermaid scripts the diagrams need. it runs
once after a clone; the scripts are ignored by git.
