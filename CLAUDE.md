# CLAUDE.md - iamnande/homelab

this file tells Claude Code how to work in this repository. read it fully before
making any changes. for an overview of what this repo is and how it's structured,
see [README.md](README.md).

---

## repo structure

```
compute/    nixos flake — all workload-running infrastructure
dns/        dns config and strategy
hypervisor/ proxmox configuration
ingress/    ingress/reverse proxy
network/    network config, vlans, segmentation
services/   internal and public services
storage/    storage strategy and config
```

each directory has its own README. when working in a specific area, read that
README first.

---

## compute flake conventions

the compute flake uses a custom `mhq` output (not `nixosModules`) for all shared modules.
modules follow `<class>.<type>` namespacing:

```
mhq.base           — every host
mhq.dev            — dev toolchain
mhq.vm.proxmox     — proxmox vm hardware
mhq.users.nick     — nick's user config
mhq.disk.btrfs     — btrfs disk layout
```

when adding modules, follow the existing pattern:
- new vm hardware type → `modules/vm/<type>.nix` → `mhq.vm.<type>`
- new bare-metal target → `modules/bare-metal/<type>.nix` → `mhq.bare-metal.<type>`
- new user → `modules/users/<name>.nix` → `mhq.users.<name>`

hosts live in `modules/hosts/<hostname>/default.nix` and compose modules via `imports`.

---

## nix-first

everything is managed via nix. don't suggest:
- imperative package installs (apt, pacman, brew, manual scripts)
- configuration outside of nix modules
- workarounds that bypass the flake

if something needs to be added to a host, it belongs in the appropriate module or
a new host-specific module.

---

## platform

- all compute nodes are nixos
- proxmox is the hypervisor for vms
- bare-metal nodes (nuc, future) will follow the same flake pattern with different
  hardware modules

---

## future (uncertain)

- **k3s cluster** — next after validation node. node profiles will likely be
  `k3s.server` and `k3s.agent` modules.
- **home-manager** — decided. being introduced iteratively. trajectory:
  1. home-manager as a nixos module in this flake, per-user config in `modules/users/`
  2. dotfiles repo evolves into a standalone home-manager flake (source of truth for "nick on any unix")
  3. homelab imports dotfiles flake: `inputs.dotfiles.homeManagerModules.nick`
  migrate one component at a time — validate each before moving the next. stow goes
  away when `home.file` covers it. don't get ahead of what's been migrated.
- **bare-metal.nuc** — graphical nixos with hyprland. hardware module pattern is
  already established, just needs the new class.

---

## what to avoid

- don't suggest non-nix solutions for anything managed by this flake
- don't add packages directly to host configs — they belong in shared modules
- don't assume all hosts are vms — bare-metal is coming
- don't hardcode hostnames or ips in modules — keep modules reusable
