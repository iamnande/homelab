# CLAUDE.md - iamnande/homelab

this file tells Claude Code how to work in this repository. read it fully before
making any changes. for an overview of what this repo is and how it's structured,
see [README.md](README.md) and [ARCHITECTURE.md](ARCHITECTURE.md).

---

## repo structure

```
infra/
  nixos/      nixos flake — all managed hosts (vms + bare-metal)
  hyperv/     proxmox configuration and vm inventory
  iac/
    dns/      porkbun — zones and records
    network/  unifi — vlans, firewall, wireless
    edge/     ngrok — domains, credentials, traffic policies
    hosts/    vm + bare-metal provisioning

platform/
  appsets/    argocd applicationsets
  templates/  shared applicationset templates and components

services/     k8s workloads — each service owns their stack
  argocd/
  authentik/
  dashboard/
  personal-site/
  forgejo/
  secrets/

network/      network config, vlans, segmentation
storage/      storage strategy and config (future)
```

each directory has its own README. when working in a specific area, read that
README first.

---

## nixos flake conventions

the nixos flake (`infra/nixos/`) uses `nixosModules` for all shared modules.
modules follow `<class>.<type>` namespacing:

```
nixosModules.base           — every host
nixosModules.dev            — dev toolchain
nixosModules.vm.proxmox     — proxmox vm hardware
nixosModules.users.nick     — nick's user config
nixosModules.disk.btrfs     — btrfs disk layout
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

- all managed hosts run nixos
- proxmox is the hypervisor for vms
- bare-metal nodes (nuc, pis, future) follow the same flake pattern with different hardware modules
- k3s runs on `lab-endurance-core-01` — workloads deploy via argocd watching `platform/` and `services/`

---

## what to avoid

- don't suggest non-nix solutions for anything managed by the flake
- don't add packages directly to host configs — they belong in shared modules
- don't assume all hosts are vms — bare-metal is in active use
- don't hardcode hostnames or ips in modules — keep modules reusable
- don't co-locate argocd applicationsets with service configs — platform/ and services/ are separate layers
