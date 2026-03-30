# architecture

high-level design of the lab. each layer builds on the one below it.
directory READMEs go deep on their specific area — this doc owns the big picture.

---

## layers

```
                    ┌─────────────────────────────┐
                    │          services/           │  k8s workloads (argocd-managed)
                    ├─────────────────────────────┤
                    │          platform/           │  argocd — deployment engine
                    ├─────────────────────────────┤
                    │        infra/nixos/          │  host OS (nixos flake)
                    ├─────────────────────────────┤
                    │        infra/hyperv/         │  hypervisor (proxmox)
                    ├─────────────────────────────┤
                    │         infra/iac/           │  external resources (terraform)
                    ├─────────────────────────────┤
                    │          network/            │  physical + logical network
                    └─────────────────────────────┘
```

---

## public access

all public-facing services are fronted by ngrok at `*.morethq.com`.
no ports are opened on the home network — ngrok tunnels carry all inbound traffic.

| domain | service |
|---|---|
| `nick.morethq.com` | personal site |
| `lab.morethq.com` | mhq dashboard |
| `deploy.morethq.com` | argocd |
| `auth.morethq.com` | authentik |

---

## gitops flow

```
PR merged → argocd detects change in services/<name>/ → deploys to k3s
```

`platform/appsets/` defines the applicationsets. each applicationset watches a
path in `services/` and manages its own sync. platform and app configs are
intentionally separate — a change to a service can't affect how argocd routes it.

---

## iac scope

terraform manages external/account-level resources only. in-cluster resources
are managed by argocd.

| directory | tool | manages |
|---|---|---|
| `infra/iac/dns/` | terraform | porkbun zones + records |
| `infra/iac/network/` | terraform | unifi vlans, firewall, wireless |
| `infra/iac/edge/` | terraform | ngrok domains, credentials, policies |
| `infra/iac/hosts/` | terraform | vm + bare-metal provisioning |

---

## hardware

| host | role | vlan |
|---|---|---|
| proxmox tower | hypervisor | mgmt (vlan 1) |
| `devbox-nick` | personal devbox | lab (vlan 30) |
| `lab-endurance-core-01` | k3s control plane | lab (vlan 30) |

planned: +64GB RAM, +4TB SSD, NUC, Raspberry Pi 5, Raspberry Pi Zero 2W.
