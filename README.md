# homelab

hey there 👋🏻 this is my home lab. there are many like it, but this one is mine.

[peace be the journey](https://youtu.be/fu_6DXHut-Y?si=fUSLJ6zVKgsiiDO_) 🥂

* [overview](#overview)
* [architecture](#architecture)
    * [network](#network)
    * [compute](#compute)
    * [hypervisor](#hypervisor)
    * [dns](#dns)
    * [ingress](#ingress)
    * [services](#services)
    * [storage](#storage)

## overview

homelab is here to support a few key items:

1. 🧪 **experimentation & learning**: i love tinkering - especially
with networking, platform services, and distributed systems; deployed and
managed securely with automation at every step.

1. 🏠 **service enablement**: my ultimate goal is to remove any dependency on
faang at both hardware and software levels. i want freedom, privacy,
control over our digital footprint - all while staying within the realm of
legit, sustainable tech.

1. 🏗️ **enterprise simulation**: ever tried homemade chicken wings after going
to [fire on the mountain](https://www.portlandwings.com/)? it's "okay" - sure -
but it is absolutely not the same. this setup lets me practice enterprise-style
patterns at home that would otherwise be atypical in a home environment.

anywho. it's a mix of learning, building useful stuff, practicing for the real
world, and reclaiming digital independence - all while keeping it fun
(🤞🏼).

---

## architecture

the lab is designed for safe experimentation with enterprise patterns.
everything flows through the gateway — a single point to enforce segmentation,
policies, and observability.

### network

segmentation-first. 7 vlans across 6 trust zones, default-deny between zones.
split-horizon dns via controld (doh). all outbound traffic through proton vpn.
the proxmox tower is plugged directly into the gateway on a dedicated lab port.

→ [network/README.md](network/README.md)

### compute

nixos vms on proxmox, managed via a nix flake with composable modules.
active nodes: `devbox-nick` (devbox), `lab-endurance-core-01` (k3s control plane).

→ [compute/README.md](compute/README.md)

### hypervisor

proxmox ve on a tower. hosts all lab vms.

→ [hypervisor/README.md](hypervisor/README.md)

### dns

controld via doh for all vlans. split-horizon for internal resolution.

→ [dns/README.md](dns/README.md)

### ingress

tbd.

→ [ingress/README.md](ingress/README.md)

### services

tbd.

→ [services/README.md](services/README.md)

### storage

tbd.

→ [storage/README.md](storage/README.md)

---

## naming convention

nodes follow `<env>-<class>[-<descriptor>]-<n>`.

**env** — network environment:

| value | vlan | description |
|---|---|---|
| `lab` | 30 | experimentation, non-production workloads |
| `svc` | 70 | production services |
| `home` | — | trusted personal devices (NUC, etc.) |
| `mgmt` | — | management plane |
| `iot` | — | IoT and sensor devices |

**class** — Interstellar-themed node archetype:

| class | reference | role |
|---|---|---|
| `endurance` | the mothership | control plane / cluster server |
| `ranger` | mission shuttle | worker / agent nodes |
| `lander` | surface craft | standalone / isolated nodes |
| `tars` | all-purpose robot | storage |
| `case` | specialized robot | edge / RPi / IoT |

**descriptor** — expected, optional. required when two nodes of the same class serve different stacks or purposes (e.g. `lab-ranger-core-01` vs `lab-ranger-media-01`).

**n** — zero-padded integer (`01`, `02`, ...).

examples: `lab-endurance-core-01`, `lab-ranger-core-01`, `iot-case-garden-01`, `home-lander-origin-01`
