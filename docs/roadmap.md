# roadmap

things that do not exist yet. when one gets built it moves into the book
proper and leaves this page.

## hosts

- **nixos on rocinante.** planned, and gated on gaming working there. until
  then rocinante is arch with a thin layer of bash on top.
- **a build record for sector7.** the same treatment rocinante gets: a spec, a
  manifest and a dated record.
- **bluetooth on rocinante.** there is no radio in the box. a usb dongle, then
  the service gets enabled.
- **variable refresh rate on rocinante.** the monitor reports it off over hdmi
  and the test is still to run. if hdmi cannot do it, the fix is a displayport
  cable.

## the book

- **hosting.** today it renders with `mdbook serve` on the box.

## from the old plan

this repo used to describe a nixos fleet on a proxmox hypervisor, with a
gitops platform on k3s. none of that runs today. what is still wanted, in no
order:

- infrastructure as code for the account-level pieces: dns, the network gear,
  the edge.
- services that each own their stack: single sign-on, a dashboard, a git
  forge, secrets.
- a storage strategy.
- a vpn zone and a dmz, shown as planned in the [network](network.md) page.
- more memory and disk for the tower.

## where the old work lives

- the nixos flake and the old docs:
  [`homelab@3ceb91d`](https://github.com/iamnande/homelab/tree/3ceb91d).
- the home-manager dotfiles:
  [`dotfiles@6882941`](https://github.com/iamnande/dotfiles/tree/6882941), the
  commit before `d5edeec` moved them to stow.
