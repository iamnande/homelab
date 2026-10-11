# rocinante

the tower. it plays games, and it is where i write code when i am at the desk.

| | |
| --- | --- |
| board | asus prime b550-plus |
| cpu | ryzen 9 5900x, 12 cores |
| gpu | rtx 4070 super |
| memory | 32G |
| disk | samsung 990 evo, 2T nvme |
| display | aoc 27g2g8, 1080p at 240hz, on hdmi |
| network | wired, switch port 8, vlan 30 (lab). no wifi and no bluetooth radio |

it runs arch linux with hyprland. before that it was the proxmox hypervisor
listed under [retired](../README.md#retired).

| page | holds |
| --- | --- |
| [build](build.md) | from the arch iso to the desktop, in order |
| [operate](operate.md) | changing it, upgrading it, rolling it back |
| [record](record.md) | the dated log of everything done to it |

## spec

what the host needs and why. nothing in this section names an operating system
or a package, so it survives a move to another one. the manifest below is how
arch meets it today.

- **one set of dotfiles, shared with sector7.** they drive the compositor, the
  bar, the launcher and the terminal here, and the shell and the editor on
  both hosts. moving between them should cost nothing, so this host carries
  only what the two cannot share.
- **a session that knows about the graphics card.** the card needs its
  vendor's driver, and the session needs a few environment variables to render
  and decode video on it. sector7 has no such card, which is why this lives
  here and not in the dotfiles.
- **games at the panel's full refresh rate.** a game store and its windows
  compatibility layer, the 32-bit graphics libraries older games still load,
  something that keeps the compatibility builds current, and a per-game
  overlay and performance mode.
- **audio every client can use.** one sound server that speaks to games, the
  browser and anything older, with realtime scheduling.
- **the toolchains my repos call for.** go, rust, node, kubernetes clients and
  containers, plus the language servers the editor is configured for.
- **one identity, held in the password manager.** it is the only ssh agent: it
  signs commits and answers for ssh keys. no private key sits on disk.
- **remote logins by key only.**
- **an upgrade that can be undone.** the os is rolling, and the kernel and the
  graphics driver often move together. the root is snapshotted before every
  upgrade, along with the kernel image that matches it.
- **a rebuild that needs no network and spares the data.** every installed
  package is kept in an offline repo. home, the logs, the package cache and
  the snapshots live apart from the root, so a rebuild replaces only the root
  and the game library is never downloaded twice.
- **a wired address on the lab vlan.** no wireless.

## manifest

`hosts/rocinante/` in this repo. it is what `apply` applies and what `drift`
checks; both are covered in [operate](operate.md).

| path | holds |
| --- | --- |
| `pkg/10-base.txt` | the system as installed, and the tools to look after it |
| `pkg/20-gaming.txt` | steam, the 32-bit graphics libraries, audio, the overlay and the performance mode |
| `pkg/40-hypr.txt` | the desktop. its config is in the dotfiles |
| `pkg/50-dev.txt` | the shell, the editor and the toolchains |
| `pkg/aur.txt` | foreign packages, built with yay |
| `root/` | whole files, laid out as they sit under `/` |
| `home/` | whole files, laid out as they sit under `~` |
| `units.txt`, `user-units.txt` | the units a fresh install does not enable on its own |
| `gsettings.txt` | desktop settings, one `schema key value` per line |

every package line is a name and what asks for it. that note is the part that
survives a move to another os.

the offline repo is not in git. it sits in `vendor/` in the main clone, ignored,
and `bin/mkrepo` rebuilds it.

## name

### where it comes from

_not written yet._

### my history with it

_not written yet._

### why i picked it

_not written yet._
