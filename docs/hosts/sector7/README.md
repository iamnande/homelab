# sector7

the nuc. it is the devbox, and it runs the small k3s cluster that serves my
site.

| | |
| --- | --- |
| machine | gmktec nucbox g10 pro |
| cpu | ryzen 5 3500u, 8 threads, radeon vega graphics |
| memory | 13G |
| disk | 477G nvme |
| network | wifi, on the home vlan. the 2.5GbE port is unused |

this page is an inventory, taken on 2026-10-03 with `bin/inventory`. sector7
does not have a manifest or a record yet. giving it the same treatment as
[rocinante](../rocinante/README.md) is on the [roadmap](../../roadmap.md).

## spec

what the host needs and why, with no operating system or package named.

- **the same desktop as rocinante.** one set of dotfiles drives both hosts,
  and this host is the reference setup for them.
- **a dev environment.** the editor, the shell and the language servers for
  the code i write on it. it has no discrete graphics card, so nothing here is
  for games.
- **a cluster that stays up.** the site runs on it, so the host is a desktop
  and a small production server at once. that is why a change only reaches it
  when i pull it there by hand.
- **one identity, held in the password manager,** as on rocinante.
- **containers,** to build and run images locally.

## inventory

| | |
| --- | --- |
| os | arch linux, kernel 7.0.11 on the day |
| filesystem | btrfs with `@`, `@home`, and subvolumes for the logs, the package cache and snapshots. a 1G efi partition at `/efi` |
| swap | 4G of zram |
| network | NetworkManager |
| login | tty1, fish, uwsm, hyprland. no display manager |
| desktop | hyprland 0.55.2, waybar, wofi, mako, ghostty |
| packages | 77 installed by hand, 649 in all. 9 from the aur |
| cluster | k3s v1.36.4, installed from the upstream script and not from a package |

what the hand-installed packages are for, by group:

| group | packages |
| --- | --- |
| desktop | hyprland, hyprlock, hyprpaper, hyprpolkitagent, uwsm, waybar, wofi, mako, ghostty, kitty, thunar, grim, slurp, wl-clipboard |
| editors | helix, neovim, zed |
| language servers | marksman, markdown-oxide, typescript-language-server, vue-language-server |
| languages | zig, fnm for node, luarocks |
| containers | podman, podman-compose, podman-docker |
| tools | git, github-cli, lazygit, zellij, fzf, ripgrep, fd, eza, tree, stow |
| apps | 1password and its cli, zen browser, zoom |

hyprland there is one release behind rocinante. it has to reach 0.56 before it
pulls the dotfiles again: the config is lua from then on, which 0.56 loads.

how a commit gets to the cluster is on the [deployment](../../deployment.md)
page.

## name

### where it comes from

_not written yet._

### my history with it

_not written yet._

### why i picked it

_not written yet._
