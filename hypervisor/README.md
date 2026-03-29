# hypervisor

Proxmox VE running on a repurposed gaming tower.

## hardware

| component | spec |
|---|---|
| CPU | AMD Ryzen 9 5900X (12c / 24t) |
| RAM | 32GB DDR4 |
| Storage | 2TB SSD |
| GPU | NVIDIA GeForce RTX 4070 Super |
| Hypervisor | Proxmox VE |

GPU is a passthrough candidate for future workloads (gaming VM, ML).

## vm inventory

| vm | vcpu | ram | disk | vlan | role |
|---|---|---|---|---|---|
| devbox-nick | 4 (2s×2c) | 8GB | — | 30 | personal devbox |
| lab-endurance-core-01 | 6 (1s×6c) | 8GB | 40GB | 30 | k3s control plane |

## capacity

| resource | committed | total | buffer |
|---|---|---|---|
| vCPU | 10 | 24 | 14 |
| RAM | 16GB | 32GB | 16GB |
