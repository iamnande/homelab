# compute

everything that runs workloads. currently nixos vms on proxmox, with bare-metal
nodes on the horizon (nuc incoming, gaming rig someday 🤞🏼).

configuration is managed via a nix flake with composable modules — the goal is
lego-style assembly where 90% of hosts share a common base and the remaining 10%
is mixed in as needed.

---

## structure

```
flake.nix               flake inputs, mhq module registry, nixosConfigurations
modules/
  base.nix              base packages, services, nix settings — every host gets this
  dev.nix               dev toolchain (lsps, runtimes, infra tools, ai tools)
  vm/
    proxmox.nix         proxmox vm hardware (virtio kernel modules, qemu guest agent)
  users/
    nick.nix            nick's user, shell, ssh keys, personal packages
  disk/
    btrfs.nix           btrfs disk layout (gpt, uefi, subvolumes: @, @nix, @var, @home)
  hosts/
    devbox-nick/        host-specific config — imports modules, sets hostname
```

---

## module system

modules are registered under `nixosModules` in `flake.nix` using `<class>.<type>` namespacing:

```nix
nixosModules = {
  base       = ./modules/base.nix;
  dev        = ./modules/dev.nix;
  vm.proxmox = ./modules/vm/proxmox.nix;
  users.nick = ./modules/users/nick.nix;
  disk.btrfs = ./modules/disk/btrfs.nix;
  k3s.server = ./modules/k3s/server.nix;
};
```

a host composes what it needs:

```nix
imports = [
  inputs.disko.nixosModules.disko
  self.nixosModules.base
  self.nixosModules.vm.proxmox
  self.nixosModules.dev
  self.nixosModules.users.nick
  self.nixosModules.disk.btrfs
];
```

as the lab grows, new module classes slot in naturally — `vm.proxmox` sits
alongside future `bare-metal.nuc`, `bare-metal.pi5`, or whatever comes next.

---

## hosts

| hostname                | profile                      | vcpu | memory | status      |
| ----------------------- | ---------------------------- | ---- | ------ | ----------- |
| devbox-nick             | base + dev + nick            | 4    | 8GB    | active      |
| lab-endurance-core-01   | base + k3s.server + nick     | 6    | 8GB    | provisioning |

---

## vm provisioning

### 1. create vm in proxmox

| setting         | value                                                      |
| --------------- | ---------------------------------------------------------- |
| os              | nixos minimal iso, local-btrfs storage                     |
| machine         | q35 (required for uefi/ovmf + virtio scsi)                 |
| bios            | ovmf (uefi), efi disk on local-btrfs, no pre-enrolled keys |
| scsi controller | virtio scsi single                                         |
| qemu agent      | enabled                                                    |
| cpu type        | host                                                       |
| cpu             | 1 socket × N cores (per host spec)                        |
| memory          | 4096 MB minimum; 8192 MB for k3s/devbox nodes             |
| disk            | 50GB scsi0, local-btrfs, write-back cache                  |
| network         | vmbr0, virtio (paravirtualized), vlan tag per host         |

boot order on creation: `ide2 (iso) → scsi0 → net0`

### 2. prep the iso

boot the vm, then in the noVNC console set a root password:

```bash
sudo passwd root
```

grab the ip from `ip addr show` or the unifi client list.

### 3. install

from `~/homelab/compute/`:

```fish
nix run github:nix-community/nixos-anywhere -- --flake .#<hostname> root@<ip>
```

nixos-anywhere runs disko to partition, installs the flake config, and reboots automatically.

### 4. finalize

in proxmox: disable `ide2`, leaving `scsi0 → net0`.

reboot, then ssh in:

```fish
ssh nick@<hostname>
```

---

## adding a new host

1. add `modules/hosts/<hostname>/default.nix` — import the modules you need, set `networking.hostName`
2. wire it into `nixosConfigurations` in `flake.nix`
3. provision the vm (see above)

---

## rebuilding an existing host

local (on the target machine itself):

```fish
nh os switch .
```

remote (from any machine with access):

```fish
nixos-rebuild switch --flake .#<hostname> --target-host nick@<hostname> --sudo
```
