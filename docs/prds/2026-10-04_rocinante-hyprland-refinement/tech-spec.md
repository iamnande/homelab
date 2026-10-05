# Tech Spec: refine the rocinante hyprland build

## Overview + Design Principles

this stream finishes the rocinante conversion across two public repos, one new
private repo and the box itself. dotfiles get the lua cutover, the
`~/src/<owner>/<repo>` layout and the missing desktop pieces. homelab is
emptied of the old nixos fleet and rebuilt around a book, a per-host manifest
and three small scripts. opord is renamed to senzu and becomes a git repo. the
order is set by one deadline (hyprland 0.57 drops `.conf`), so the lua cutover
goes first and alone.

1. **one home per fact.** dotfiles own what is the same on every host. a
   host's manifest owns what is host-local. the book explains. nothing is
   written in two places.
2. **thin and replaceable.** plain bash, no framework. what nixos would own
   later is kept as a list or a file, never as logic.
3. **read-only by default.** `drift` and every check run without root. what
   needs root is one command nick runs, and it never deletes.
4. **a check and a way back before it lands.** every stage in the rollout
   plan names both.
5. **the repo is public.** nothing names the deploy product behind sector7 and
   nothing lists a host's open gaps (R24).

## Data Model

no database. the model is files on disk.

**homelab after this stream**

```
AGENTS.md  CLAUDE.md  README.md  book.toml  .gitignore
bin/       apply  drift  pkglist  mkrepo  inventory
docs/      the book (mdbook source)
  SUMMARY.md  README.md  network.md  deployment.md  roadmap.md
  hosts/README.md
  hosts/rocinante/  README.md  build.md  operate.md  record.md
  hosts/sector7/    README.md
  prds/2026-10-04_rocinante-hyprland-refinement/  prd.md  tech-spec.md
hosts/
  rocinante/
    pkg/     10-base.txt  20-gaming.txt  40-hypr.txt  50-dev.txt  aur.txt
    root/    mirrors /
    home/    mirrors ~
    units.txt  user-units.txt  gsettings.txt
vendor/    untracked and ignored: repo/ (offline [mhq]), yay/, 1password/
```

**a package list line** is a name and what asks for it:

```
hypridle     # idle lock and screen off (dotfiles: hypridle.conf)
grim         # screenshots (dotfiles: bin/screenshot)
```

**`hosts/rocinante/root/`** holds whole files, not patches:

```
etc/hostname  etc/locale.conf  etc/locale.gen  etc/vconsole.conf
etc/environment  etc/fstab  etc/pacman.conf
etc/mkinitcpio.conf  etc/mkinitcpio.d/linux.preset  etc/kernel/cmdline
etc/grub.d/15_uki
etc/systemd/zram-generator.conf  etc/systemd/network/20-wired.network
etc/ssh/sshd_config.d/10-keys-only.conf
etc/pacman.d/hooks/00-snapshot-root.hook
usr/local/bin/snapshot-root
```

**`hosts/rocinante/home/`**

```
.config/uwsm/env
.config/pacman/makepkg.conf
.config/systemd/user/protonplus.service  protonplus.timer
.config/mimeapps.list
.ssh/authorized_keys
```

**`units.txt` and `user-units.txt`** are one unit per line. **`gsettings.txt`**
is `schema key value` per line.

**snapshot store.** a top-level btrfs subvolume `@snapshots`, mounted at
`/.snapshots`. each upgrade adds a pair:

```
/.snapshots/2026-10-05T03-12-44Z        read-only snapshot of @
/.snapshots/2026-10-05T03-12-44Z.efi    the unified kernel image at that moment
```

the image is kept because `/boot` is vfat and outside the snapshot. a root
rolled back without its kernel image boots a kernel whose modules are gone.

**dotfiles.** two fixed paths, the same on every host:
`~/src/iamnande/senzu/beans` for state and
`~/src/iamnande/senzu/references/screenshots` for screenshots.

**plan page.** one artifact per stream. `view.html` is the page; `prd.md` and
`tech-spec.md` are published beside it. the link sits on the state file's
`plan:` line.

## Interfaces

**homelab scripts**

```
bin/pkglist <host> [--aur]   print package names from the host's lists, comments stripped
bin/drift   [host]           read-only. exit 0 clean, 1 drift, 2 usage or error
bin/apply   [host] [-n]      make the host match. -n prints the plan and changes nothing
bin/mkrepo  [dest]           snapshot installed packages into the offline repo
bin/inventory                print a host inventory. read-only, no root
```

`host` defaults to the contents of `/etc/hostname`. `HOMELAB_VENDOR` defaults
to `$HOME/src/iamnande/homelab/vendor`, a fixed path, so a worktree writes to
the one real `vendor/`.

**`drift` output**, one finding per line, `kind: what: subject`:

```
pkg: missing: hypridle
pkg: unlisted: lutris
aur: missing: protonplus
file: differs: /etc/pacman.conf
file: missing: /etc/pacman.d/hooks/00-snapshot-root.hook
file: unchecked: /etc/example (permission denied)
file: pacnew: /etc/pacman.conf.pacnew
unit: disabled: sshd.service
user-unit: disabled: protonplus.timer
setting: differs: org.gnome.desktop.interface color-scheme
```

**pacman hook**, `etc/pacman.d/hooks/00-snapshot-root.hook`:

```ini
[Trigger]
Operation = Upgrade
Type = Package
Target = *

[Action]
Description = snapshot @ before the upgrade
When = PreTransaction
Exec = /usr/local/bin/snapshot-root
AbortOnFail
```

**sshd drop-in**, `etc/ssh/sshd_config.d/10-keys-only.conf`. it sorts ahead of
`99-archlinux.conf`, and the first value sshd reads wins:

```
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
AuthenticationMethods publickey
```

**ssh client config**, dotfiles `src/ssh/.ssh/config`. the include comes first
so it is not scoped into the `Host` block:

```
Include ~/.ssh/config.local
Host *
    IdentityAgent ~/.1password/agent.sock
```

**dotfiles make**: `make all` stows every component. `make a b` stows both.

**dotfiles scripts**, in `src/bin/.local/bin/`:

```
screenshot region|output   grim (with slurp for region) to a file, then wl-copy
powermenu                  wofi --dmenu: lock, sleep, log out, reboot, shut down
```

**binds added in `hyprland.lua`** (the 30 existing binds are unchanged):

| keys | action |
|---|---|
| `SUPER+SHIFT+S` | `screenshot region` |
| `Print` | `screenshot output` |
| `SUPER+M` | `powermenu` (was: exit the session) |
| `XF86AudioRaiseVolume`, `XF86AudioLowerVolume` | `wpctl set-volume`, 5% steps, capped at 100% |
| `XF86AudioMute`, `XF86AudioMicMute` | `wpctl set-mute ... toggle` |
| `XF86AudioPlay`, `XF86AudioPause`, `XF86AudioNext`, `XF86AudioPrev` | `playerctl` |

## Validation

- **package lists.** every non-comment line is one package name. a name is in
  exactly one list. `pkg/*.txt` holds repo packages only, `aur.txt` foreign
  ones only. `drift` reports a breach as a finding.
- **`apply`.** refuses to run as root; it runs as nick and calls sudo itself,
  because home files and yay must not be root's. refuses a host with no
  manifest. runs `sshd -t` before reloading sshd when a file under `etc/ssh`
  changed. never removes a package or a file. stops at the first failed step
  and is safe to rerun.
- **`drift`.** writes nothing and never calls sudo. an unreadable file is a
  finding, not a pass.
- **`snapshot-root`.** exits nonzero, which aborts the upgrade, when
  `/.snapshots` is not the mounted `@snapshots`, or when the snapshot or the
  image copy fails. it prunes only after a good snapshot, and only names that
  match its own timestamp pattern.
- **`screenshot`.** creates the directory. a missing tool is a notification
  and a nonzero exit, not silence.
- **lua config.** `Hyprland --verify-config -c hyprland.lua` is clean,
  `hyprctl configerrors` is empty, and the set of bound keys equals the
  baseline taken before the cutover.
- **public repo.** a pattern file kept in the senzu repo, not here, lists what must
  never appear. `grep -rniE -f <that file>` over the tree finds nothing. open
  gaps are caught in review, not by a pattern.
- **book.** `book.toml` sets `create-missing = false`, so a page named in
  `SUMMARY.md` that does not exist fails the build. `mdbook build` exits zero
  and `lychee --offline docs` finds no broken link.

## Core

### 1. the lua cutover (R1)

`hyprland.conf` is 53 lines and uses no settings blocks, so the port is binds,
three autostarts and one monitor rule. `hyprland.lua` replaces it in the same
commit.

| `.conf` | `.lua` |
|---|---|
| `monitor = , highrr, auto, 1` | `hl.monitor({ output = "", mode = "highrr", position = "auto", scale = 1 })` |
| `exec-once = hyprpaper` (and 1password, waybar) | `hl.on("hyprland.start", function() hl.exec_cmd("hyprpaper") ... end)` |
| `bind = $mainMod, Q, exec, $terminal` | `hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))` |
| `killactive` | `hl.dsp.window.close()` |
| `fullscreen` | `hl.dsp.window.fullscreen()` |
| `togglefloating` | `hl.dsp.window.float({ action = "toggle" })` |
| `movefocus, l` | `hl.dsp.focus({ direction = "left" })` |
| `workspace, N` and `movetoworkspace, N` | a loop over 1 to 6: `hl.dsp.focus({ workspace = i })`, `hl.dsp.window.move({ workspace = i })` |
| `binde ... resizeactive, 30 0` | `hl.dsp.window.resize(...)` with `{ repeating = true }` |
| `bindm ... mouse:272, movewindow` | `hl.dsp.window.drag()` with `{ mouse = true }` |
| `hyprctl dispatch exit` | `hyprctl dispatch 'hl.dsp.exit()'` |

the forms above come from `/usr/share/hypr/hyprland.lua`, the example shipped
with 0.56.2. the stubs in `/usr/share/hypr/stubs/hl.meta.lua` name `fullscreen`
and `resize` but not their arguments, so those two are settled with
`--verify-config` at execute.

`~/.config/hypr` is a symlink into the main dotfiles clone, which stays on
`main`. to test before merge, point that symlink at the worktree, have nick
log out and back in, and point it back if anything is off.

### 2. dotfiles layout, purge, stow-all (R2, R3, R4)

- every `~/dotfiles`, `~/iamnande`, `~/homelab`, `~/rawr` becomes
  `~/src/iamnande/<repo>`: `mhq.kdl`, `README.md`, `docs/agents.md`.
- `~/opord/senzu` becomes `~/src/iamnande/senzu/beans`: the `senzu` script,
  seven `SKILL.md` files, `docs/agents.md`.
- `plan/<date>_<slug>/` becomes `docs/prds/<date>_<slug>/` in `iam-plan` and
  `docs/agents.md`, and `git add -f` becomes `git add`.
- gone: the `way` tab in `mhq.kdl`, `tardis.kdl`, the `tardis` alias and the
  `~/way` test in `config.fish`. `mhq` always uses the layout.
- `guardrails/settings.json` still denies `~/dotfiles/...`. agents may not
  edit it, so the diff goes to nick (R26).
- the readme's "probably brew" line goes. arch native is the decision.

**stow-all.** today every component target sets a target-specific `COMPONENT`
and depends on one shared `install` target. make runs a prerequisite once per
invocation, so `make a b` installs only `a`. the fix gives each component its
own recipe and keeps the `##` help lines:

```make
COMPONENTS := agents backgrounds bin fish ghostty git helix hypr mako ssh waybar wofi zellij

.PHONY: $(COMPONENTS) all
$(COMPONENTS):
	@echo $(log) "installing $@"
	$(call _install_component,$@)

all: $(COMPONENTS) ## setup: every component
hypr: ## setup: hyprland (twm)
```

`_install_component` takes the component as an argument. `fisher` and
`guardrails` keep their own recipes.

### 3. desktop pieces (R5 to R10, R21, R29)

- **screenshots.** `screenshot region` runs `grim -g "$(slurp)"`; `screenshot
  output` runs `grim`. both write
  `~/src/iamnande/senzu/references/screenshots/<timestamp>.png`, after
  `mkdir -p`, then `wl-copy < file`. no `jq`, because sector7 lacks it.
- **idle.** `hypridle.conf`, started from the lua autostart so no host needs a
  unit:

  ```
  general {
      lock_cmd         = pidof hyprlock || hyprlock
      before_sleep_cmd = loginctl lock-session
      after_sleep_cmd  = <screen on>
  }
  listener {
      timeout    = 600
      on-timeout = loginctl lock-session
  }
  listener {
      timeout    = 900
      on-timeout = <screen off>
      on-resume  = <screen on>
  }
  ```

  screen on and off go through `hyprctl dispatch`, which takes a lua
  expression once the config is lua. the exact dpms form is confirmed on the
  box at execute. there is no suspend listener.
- **power menu.** `powermenu` pipes five lines to `wofi --dmenu` and runs
  `loginctl lock-session`, `systemctl suspend`, today's exit expression,
  `systemctl reboot` or `systemctl poweroff`. `before_sleep_cmd` is what makes
  wake land on the lock screen.
- **volume and media.** the ten `XF86Audio*` binds from the shipped example,
  with `{ locked = true }` so they work on the lock screen.
- **mako.** everforest background, text and border, red border for critical.
  the two timeout lines stay.
- **gtk dark.** `gsettings.txt` sets `color-scheme` to `prefer-dark` and
  `gtk-theme` to `Adwaita-dark`, the second for gtk3 apps like thunar.
- **ssh client.** a new `ssh` component. `~/.ssh` is a real directory, so stow
  links only `config`.
- **top bar.** `everforest.css` is renamed to real everforest names and
  `style.css` follows. the pango spans with catppuccin literals leave
  `config.jsonc`; color comes from css. right side becomes `tray`,
  `idle_inhibitor`, `group/dashboard`, `clock`, `custom/power` (runs
  `powermenu`). the unused `battery` block and `#custom-vpn` rule go. the look
  is tuned live with nick.
- **vrr.** the monitor reports `vrr: false` today on hdmi. the test: set
  `misc.vrr` to 1, run a game, read `hyprctl monitors` and the monitor's own
  refresh readout. if hdmi cannot do it, the result is recorded, `vrr` stays
  off and "move to displayport" goes on the roadmap.
- **mangohud and gamemode.** with their `lib32-` twins for 32-bit games. the
  launch option is `gamemoderun mangohud %command%`. nick joins the `gamemode`
  group the package creates.

### 4. homelab cleanup, book, agent instructions (R11, R12, R13, R27)

**deleted:** `infra/`, `platform/`, `services/`, `storage/`, `network/`,
`ARCHITECTURE.md`, and the old `CLAUDE.md` body. `network/README.md` is not
lost: it becomes `docs/network.md` with the proxmox wording fixed.

**book.** `book.toml` at the root with `src = "docs"`, so the same files read
on github and render with `mdbook serve`. the build directory is ignored.
`mdbook-mermaid` renders the network diagram. `SUMMARY.md`:

```
[homelab](README.md)
- [network](network.md)
- [hosts](hosts/README.md)
  - [rocinante](hosts/rocinante/README.md)
    - [build](hosts/rocinante/build.md)
    - [operate](hosts/rocinante/operate.md)
    - [record](hosts/rocinante/record.md)
  - [sector7](hosts/sector7/README.md)
- [deployment](deployment.md)
- [roadmap](roadmap.md)
- [plans]()
  - [rocinante refinement: prd](prds/2026-10-04_rocinante-hyprland-refinement/prd.md)
  - [rocinante refinement: tech spec](prds/2026-10-04_rocinante-hyprland-refinement/tech-spec.md)
```

| page | holds |
|---|---|
| `hosts/README.md` | the fleet: rocinante, sector7. retired: the proxmox vms, the pi 5, the pi zero |
| `hosts/<host>/README.md` | spec (what it needs and why, os-agnostic), then a name section with three headed slots for nick |
| `rocinante/build.md` | iso to desktop, in order, commands that run in bash and fish |
| `rocinante/operate.md` | `apply`, `drift`, upgrading, snapshots and rollback, `mkrepo` |
| `rocinante/record.md` | the dated build log, 27 rows today, append-only |
| `roadmap.md` | nixos for rocinante (gated on gaming), the old nix at `homelab@3ceb91d` and dotfiles before `d5edeec`, bluetooth, displayport for vrr, hosting the book, sector7's build record |

`README.md` shrinks to the intro and a pointer at `docs/`.

**agent instructions.** `AGENTS.md` is the real file; `CLAUDE.md` is one line,
`@AGENTS.md`. the list:

```
- this repo is public. never name the deploy product behind sector7, and never
  write down a host's open security gaps. those live in the private senzu repo.
- docs/ is the book and the only prose. don't add readmes elsewhere.
- a host changes through its manifest: edit hosts/<host>/, then nick runs
  bin/apply. agents run bin/drift and never sudo.
- every change to a host gets a dated row in its record.
- packages are arch native, one list per host, and each line says what asks
  for it.
- keep automation thin: plain bash, no framework. rocinante may move to nixos.
- commands in the book run in both bash and fish.
- terms: host, book, spec, record, manifest, apply, drift, roadmap.

## maintaining these instructions
keep only rules that change behavior in this repo. prune before appending.
```

### 5. the manifest (R14, R19, R22)

| from `~/src/mhq/src/svc/infra` | to homelab |
|---|---|
| `pkg/*.txt` | `hosts/rocinante/pkg/`, each line gaining its note |
| `etc/` | `hosts/rocinante/root/etc/` |
| `bin/mkrepo` | `bin/mkrepo`, vendor path from `HOMELAB_VENDOR` |
| `README.md` build log | `docs/hosts/rocinante/record.md` |
| `README.md` runbooks | `docs/hosts/rocinante/build.md` and `operate.md`, rewritten |
| `vendor/` and `../secrets/vendor/1password` | `~/src/iamnande/homelab/vendor/`, a `mv` on one filesystem |

then the drift list is captured from the live box into `root/` and `home/`,
and the lists gain the R19 packages: 22 from the repos, plus
`lib32-mangohud`, `lib32-gamemode`, `mdbook-mermaid`, `lychee` and
`shellcheck` (see resolved questions), and three in `aur.txt`: `protonplus`,
`1password-cli`, `golangci-lint-langserver-bin`. `pkg/flatpak.txt` is deleted.

removals are one-time commands in the record, because `apply` never removes:
`lutris`, the protonplus flatpak, `flatpak`, `yay-debug`, and the R22
leftovers. `protonplus.service` is rewritten to call the native binary.
`makepkg.conf` in `home/` turns off debug packages, which is where
`yay-debug` came from.

### 6. `apply` and `drift` (R16, R17)

both walk the same five kinds in the same order. `drift` reports; `apply`
fixes what `drift` would report as missing, differing or disabled.

```
packages   pkglist vs `pacman -Qqen` (repo) and `pacman -Qqem` (foreign)
             apply: sudo pacman -S --needed <missing>; yay -S --needed <missing aur>
             unlisted packages are reported, never removed
files      every file under root/ and home/ vs its target, by `cmp`
             apply: install -D with the source's mode (sudo for root/)
             also reports any *.pacnew beside a managed file
units      units.txt vs `systemctl is-enabled`; user-units.txt with --user
             apply: enable --now
settings   gsettings.txt vs `gsettings get`
             apply: gsettings set
```

`apply -n` runs the same walk and prints the commands instead of running
them. a clean host prints nothing in either mode.

### 7. snapshots (R18)

one-time setup, nick, by hand: create `@snapshots` at the top level and make
`/.snapshots`. the fstab line and the hook arrive through `apply`.

`snapshot-root`, about 25 lines:

```
name = date -u +%Y-%m-%dT%H-%M-%SZ
mountpoint -q /.snapshots                     or exit 1
btrfs subvolume snapshot -r / /.snapshots/$name
cp /boot/EFI/Linux/arch-linux.efi /.snapshots/$name.efi
print the name
prune: keep the newest 5 pairs that match the timestamp pattern
```

**rollback**, written out in `operate.md`. from the arch iso, or from the
running system if it still boots:

```
mount -o subvolid=5 /dev/nvme0n1p2 /mnt
mv /mnt/@ /mnt/@broken
btrfs subvolume snapshot /mnt/@snapshots/<name> /mnt/@
cp /mnt/@snapshots/<name>.efi <esp>/EFI/Linux/arch-linux.efi
reboot, check, then delete /mnt/@broken
```

`/home`, `/var/log` and the package cache are separate subvolumes and are not
rolled back.

### 8. key-only ssh (R20)

two commits, so the lock cannot land before the key is proven:

1. `home/.ssh/authorized_keys` (nick's public key, already public in the
   dotfiles). nick runs `apply`, then proves a key login from a second host.
2. `10-keys-only.conf`. nick runs `apply`, which checks `sshd -t` and reloads.
   from the second host, a forced password login is refused.

### 9. sector7 (R23)

`bin/inventory` is rewritten from the sections of the 10-03 output; the
original script was in a scratchpad that did not survive a reboot. it prints
host, hardware, network, boot and disk, packages, desktop, services, repos.
the raw output is never committed.

`hosts/sector7/README.md` is written by hand from that output: hardware, os,
package counts, what it runs. `deployment.md` is one short page: a push
builds an image, the image goes to a registry, the cluster pulls it and rolls
it out, and public traffic arrives through an outbound tunnel with no open
ports. it says "gitops, self-hosted, k3s" and names no product. nick reviews
the page before it is committed.

### 10. the plan page (R28)

`view.html` moves from this session's scratchpad into
`src/agents/.claude/skills/iam-plan/templates/`. `iam-plan` gains one step
after each doc is written or changed: publish `view.html` with the stream's
`prd.md` and `tech-spec.md` beside it, to the link on the state file's `plan:`
line if there is one, and record the link if not. the template has no
`<title>`; the publish call names the stream.

### 11. the senzu repo and the guard hook (R25, R26)

- rename `~/src/iamnande/opord` to `~/src/iamnande/senzu`, and `senzu/` inside
  it to `beans/`. then `git init` and one commit of the state files. the
  same step fixes what points at the old path: this stream's state file, the
  hardening stream's, and the agent memory notes. nick creates the private
  remote `iamnande/senzu`; the push is then allowed from rocinante.
- until order 5 lands the skills still look in `~/opord/senzu`, as they do
  today, so nothing on rocinante gets worse in between.
- nick applies the two-line path diff to `guardrails/settings.json`, then
  runs `make guardrails`.
- **pushes follow the host.** the hook's push check, today "only
  `github.com/ngrok-private`", picks its rule by hostname. on `rocinante` and
  `sector7`: allow `github.com/iamnande/*`, allow another remote only when it
  is public, and block any url that names ngrok. everywhere else: the rule as
  it is. the hook is nick's to edit, from a diff.
- the last bullet of the global `AGENTS.md` is split so the text and the hook
  agree. *proposed* wording:

  ```
  - never set NGROK_ENV to prod or stage, delete branches, run nd ctl or nd db
    (except lint), publish, force-remove worktrees, or use sudo. hand me the
    command instead.
  - pushes follow the host. on work hosts, push only to
    github.com/ngrok-private. on my own hosts (rocinante, sector7), push only
    to github.com/iamnande or another public repo, and never to anything
    ngrok, public included. anything else: hand me the command. in claude
    code, the claude-guard hook enforces this.
  ```

## Query Layer

N/A: there is no datastore. the only reads are the `pacman`, `systemctl`,
`cmp` and `gsettings` calls listed under `apply` and `drift`.

## API Layer

command-line entry points only.

| command | flow | errors |
|---|---|---|
| `bin/drift [host]` | resolve host, walk the five kinds, print findings | exit 1 on any finding. exit 2 on an unknown host or a missing tool |
| `bin/apply [host] [-n]` | refuse root, resolve host, walk the five kinds, fix each | exit 2 as root or on an unknown host. exits at the first failed step with that step's status. rerun to continue |
| `bin/pkglist <host> [--aur]` | strip comments and blanks, print names | exit 2 on an unknown host |
| `bin/mkrepo [dest]` | unchanged logic, new default path | unchanged: reports each package with no file and exits nonzero |
| `snapshot-root` | called by pacman before an upgrade | nonzero aborts the transaction |
| `screenshot`, `powermenu` | called by a bind or the bar | a notification on failure |

## Files Changed

**dotfiles**

| file | change |
|---|---|
| `src/hypr/.config/hypr/hyprland.lua` | new. the port, then the new binds and the hypridle autostart |
| `src/hypr/.config/hypr/hyprland.conf` | deleted |
| `src/hypr/.config/hypr/hypridle.conf` | new |
| `src/bin/.local/bin/screenshot`, `powermenu` | new |
| `src/bin/.local/bin/senzu` | state path |
| `src/mako/.config/mako/config` | everforest colors |
| `src/waybar/.config/waybar/config.jsonc`, `style.css`, `everforest.css` | everforest names, tray, idle-inhibit, power button |
| `src/ssh/.ssh/config` | new component |
| `src/zellij/.config/zellij/layouts/mhq.kdl` | paths, `way` tab removed |
| `src/zellij/.config/zellij/layouts/tardis.kdl` | deleted |
| `src/fish/.config/fish/config.fish` | `tardis` alias and `~/way` test removed |
| `src/agents/.claude/skills/*/SKILL.md` (7) | state path. `iam-plan`: `docs/prds`, the page step |
| `src/agents/.claude/skills/iam-plan/templates/view.html` | new |
| `mk/setup.mk` | per-component recipes, `all`, `ssh` |
| `docs/agents.md`, `README.md` | paths, plan docs, brew line |
| `guardrails/settings.json` | deny paths. nick's edit, from a diff |
| `src/agents/.claude/hooks/claude-guard` | push rule by host. nick's edit, from a diff |
| `src/agents/.config/AGENTS.md` | the push rule, split out and made per host |

**homelab**

| file | change |
|---|---|
| `infra/`, `platform/`, `services/`, `storage/`, `network/`, `ARCHITECTURE.md` | deleted |
| `AGENTS.md` | new |
| `CLAUDE.md` | replaced by a one-line import |
| `README.md` | intro and a pointer at the book |
| `book.toml`, `.gitignore` | new |
| `docs/**` | new: the book |
| `bin/apply`, `drift`, `pkglist`, `inventory` | new |
| `bin/mkrepo` | moved in, vendor path changed |
| `hosts/rocinante/**` | new: the manifest |

**the senzu repo** (today's opord): renamed, `git init`, first commit. **outside any repo**: `vendor/` moved;
`~/src/mhq/src/svc/infra` emptied.

## Services & Ordering

one worktree per repo. branches after the first are stacked in the same
worktree. a push needs nick's go-ahead and, on rocinante, may then be run by
the agent. merges are nick's.

| order | repo / service | branch | base | contents |
|---|---|---|---|---|
| 1 | dotfiles | `nick/rocinante-hyprland-refinement` | `main` | R1: the lua cutover, alone |
| 2 | senzu (today's opord) | `main`, local | none | R25: the rename, `git init`, state files. no PR |
| 3 | homelab | `nick/rocinante-hyprland-refinement` | `main` | plan docs, R11, R12, R24, R27 |
| 4 | homelab | `nick/rocinante-hyprland-refinement-host` | 3 | R13 to R22: manifest, scripts, rocinante pages, snapshot hook, ssh |
| 5 | dotfiles | `nick/rocinante-hyprland-refinement-layout` | 1 | R2, R3, R4, R28, and the R26 diff for nick |
| 6 | dotfiles | `nick/rocinante-hyprland-refinement-desktop` | 5 | R5 to R10, R29, and the `vrr` value from R21 |
| 7 | homelab | `nick/rocinante-hyprland-refinement-sector7` | 4 | R23 |

6 needs the packages that 4 installs. nothing else crosses repos.

## Integration Tests

there is no test harness for a desktop, so most of these are manual and named
by who runs them.

| # | test | who | covers |
|---|---|---|---|
| T1 | `Hyprland --verify-config -c hyprland.lua` is clean | agent | R1 |
| T2 | after a fresh login: `hyprctl configerrors` empty, no deprecation notice, bound keys equal the baseline, `hyprctl monitors` shows 239.96 | agent, after nick logs in | R1 |
| T3 | the bind checklist: terminal, menu, files, lock, close, fullscreen, float, focus, workspaces, moves, resizes, mouse | nick | R1 |
| T4 | a grep over the dotfiles for the old paths (`~/` or `$HOME/` followed by `dotfiles`, `iamnande`, `homelab`, `rawr`, `opord`, `way` or `tardis`) finds nothing. `guardrails/` is excluded until nick applies its diff | agent | R2, R3 |
| T5 | `/senzu` in a new session lists both streams | nick | R2 |
| T6 | `make -n all` names every component; `make -n hypr mako` names both | agent | R4 |
| T7 | each new bind does its job: two screenshots land in the directory and the clipboard; volume, mute and media keys act | nick | R5, R8 |
| T8 | `hypridle` is running; the session locks at 10 min and the screen is off at 15; a playing video prevents both | nick | R6 |
| T9 | the power menu opens from `SUPER+M` and the bar. sleep, then wake to the lock screen | nick | R7, R29 |
| T10 | a notification shows in everforest and is gone in ten seconds; thunar is dark | nick | R9 |
| T11 | `ssh -G rocinante` shows the 1password agent | agent | R10 |
| T12 | `mdbook build` exits zero; `lychee --offline docs` is clean | agent | R12, R13, R15 |
| T13 | the public-repo grep, with the pattern file from the senzu repo, finds nothing | agent | R24 |
| T14 | `bin/drift` exits 0. `bin/apply` then prints nothing. `bin/apply -n` prints nothing | agent for drift, nick for apply | R14, R16, R17, R19, R22 |
| T15 | `shellcheck bin/*` and the snapshot script are clean | agent | R16, R17, R18 |
| T16 | `pacman -Syu` prints the snapshot line and a pair appears in `/.snapshots`. with `/.snapshots` unmounted, `snapshot-root` exits nonzero | nick | R18 |
| T17 | from a second host: key login works, a forced password login is refused | nick | R20 |
| T18 | one game launched with `gamemoderun mangohud %command%` shows the overlay and `gamemoded -s` says active. the vrr result is in the record | nick | R21 |
| T19 | the offline resolve check from the record passes after `mkrepo` | agent | R14, R15 |
| T20 | in a new agent session on rocinante the hook blocks `sudo true` and a dry-run push to an ngrok url, and lets a dry-run push to `github.com/iamnande` through | nick | R26 |
| T21 | the plan page shows both docs and its link is in state | agent | R28 |
| T22 | waybar shows no catppuccin color: `grep -rniE 'catppuccin\|#f5c2e7\|#a6e3a1\|#f5e0dc' src/waybar` finds nothing | agent | R29 |

## Rollout Plan

no flags. each stage is a merge or a command nick runs on rocinante.

| stage | what | verify | way back |
|---|---|---|---|
| 0 | save `hyprctl binds -j` and `hyprctl monitors` to `references/rocinante/` in today's opord, which the rename in stage 2 carries along | the files exist | none needed |
| 1 | order 1. test from the worktree by pointing `~/.config/hypr` at it; nick logs out and in. then merge, pull, point it back | T1, T2, T3 | before merge: point the symlink back. after: check out the previous commit from tty2 and log in again |
| 2 | order 2. the rename and `git init`. nick creates the private remote and pushes | `git -C ~/src/iamnande/senzu log` shows the commit and both state files are under `beans/` | rename both back and delete `.git` |
| 3 | nick installs `mdbook mdbook-mermaid lychee shellcheck` | the commands run | `pacman -Rns` |
| 4 | order 3 merged | T12, T13 | revert the merge. the old tree is at `3ceb91d` |
| 5 | order 4, in checkpoints: manifest moved and `drift` reports only known drift; `apply -n` reviewed; `apply`; the removals; `@snapshots` and the hook; `authorized_keys`, proof, then the sshd drop-in; `mkrepo` | T14 to T17, T19 | per checkpoint. packages: `pacman -Rns`. files: the previous copy from git or the `.pacnew`. sshd: delete the drop-in at the local console and reload. the hook: delete it. the old record stays in place until T14 passes |
| 6 | order 5 merged. nick runs `make all`, applies the guardrails diff, runs `make guardrails` | T4, T5, T6, T20, T21 | revert the merge and `make all` |
| 7 | order 6 merged. `make all`, log out and in | T7 to T11, T18, T22 | revert the merge and log in again. sleep entry removed if wake fails |
| 8 | order 7 merged after nick reviews `deployment.md` | T12, T13 | revert the merge |
| 9 | sector7, nick: upgrade hyprland to 0.56 or later, move the clones, pull, `make all` | nick confirms the session and the bar | check out its previous commit, `0fa140a` |
| 10 | close: `mkrepo`, `drift` clean, the record rows written, the old guide marked superseded | T14 | none needed |

## Resolved Questions

| question | resolution |
|---|---|
| where does `vendor/` live when worktrees have none? | in the main clone, ignored, reached by a fixed path in `HOMELAB_VENDOR`. scripts never resolve it from their own location |
| where does the book live next to `docs/prds`? | `docs/` is the book's source, and the plan docs are listed in it under "plans". one tree reads on github and in `mdbook serve` |
| does a root snapshot roll back cleanly? | not alone. `/boot` is vfat, so the hook also keeps the unified kernel image and the rollback restores both |
| where do snapshots go? | a top-level `@snapshots` mounted at `/.snapshots`, so a rollback of `@` does not carry the snapshots away with it |
| what is `golangci-lint-langserver` called? | `golangci-lint-langserver-bin` in the aur. there is no package under the plain name |
| do host addresses go in the public ssh config? | no. `~/.ssh/config.local`, untracked, made per host. the book names the step without addresses |
| does sudo policy go in the manifest? | no. it is a hardening-stream question and stays out of the public repo until that stream decides. the record names the step without the detail |
| how does the book render the mermaid diagram? | `mdbook-mermaid`. its two generated js files are ignored, not committed; `mdbook-mermaid install` runs once after a clone, and the build chapter says so |
| what is the state directory called once the repo is senzu? | `beans`. one senzu bean per stream. nick's pick, over `log` and `streams` |
| is `senzu` free as a repo name? | yes. `iamnande/senzu` did not exist on github on 10-04 |
| where does the public-repo pattern live? | in the senzu repo. a pattern that names what must not appear cannot sit in the public repo |
| packages beyond R19? | five, *proposed*: `lib32-mangohud` and `lib32-gamemode` so 32-bit games get both, `mdbook-mermaid` for the network diagram, `lychee` for the link check in R12, `shellcheck` for scripts that run as root |
| where did `yay-debug` come from? | makepkg builds debug packages by default. a user `makepkg.conf` in `home/` turns that off; confirmed by building protonplus and seeing no `-debug` package |
| what replaces the hourly flatpak update? | the same timer, with the service calling the native `protonplus update all`. the binary's exact name is confirmed after install |
| how is the dotfiles change tested when `~/.config/*` points at the main clone? | by pointing the one symlink at the worktree for the test, then back |
| does `hyprctl dispatch` change under lua? | yes. the shipped example calls `hyprctl dispatch 'hl.dsp.exit()'`. every shell-side dispatch (exit, dpms) uses that form |
| mkinitcpio's hooks differ from what mkinitcpio 42 ships. change them? | no. the file is captured as it is. changing the boot path is not in the PRD |
| what happens to `~/src/mhq`? | it is left with empty directories. nick removes them |
| the guide artifact has no local source. how are the build chapters written? | from the record and from the artifact, read back at execute |
| is wofi themed? | yes, already everforest. hyprlock is not, and is not in scope |
| how does the hook tell a home host from a work host, and a public repo from a private one? | *proposed*: by hostname, from a short list in the hook. `github.com/iamnande/*` is always allowed there; any other remote must answer an unauthenticated `git ls-remote` over https, which only a public repo does. nick decides when he edits the hook |
| is the gamemode group needed? | the package creates it and its polkit rules use it. nick joins it once; the command is in the record |

## Requirements Coverage

| requirement | covered by |
|---|---|
| R1: lua config | § Core 1, T1 to T3, stage 1 |
| R2: repo layout | § Core 2, T4, T5, stage 6 |
| R3: defunct repos | § Core 2, T4 |
| R4: stow all | § Core 2, T6 |
| R5: screenshots | § Core 3, § Interfaces, T7 |
| R6: idle | § Core 3, T8 |
| R7: power menu | § Core 3, T9 |
| R8: volume and media keys | § Core 3, § Interfaces, T7 |
| R9: look | § Core 3, T10 |
| R10: ssh client | § Core 3, § Interfaces, T11 |
| R11: dead content | § Core 4, § Files Changed, stage 4 |
| R12: book | § Core 4, § Validation, T12 |
| R13: host pages | § Core 4, T12 |
| R14: manifest | § Data Model, § Core 5, T14, T19 |
| R15: rebuild chapters | § Core 4, § Core 5, T12, T19 |
| R16: apply | § Core 6, § API Layer, T14, T15 |
| R17: drift | § Core 6, § Interfaces, T14, T15 |
| R18: snapshots | § Data Model, § Core 7, T16 |
| R19: packages | § Core 5, § Resolved Questions, T14 |
| R20: key-only ssh | § Core 8, § Interfaces, T17 |
| R21: gaming | § Core 3, T18 |
| R22: leftovers | § Core 5, T14 |
| R23: sector7 | § Core 9, stage 8 |
| R24: public repo | § Validation, T13, § Resolved Questions |
| R25: senzu repo | § Core 11, stage 2 |
| R26: guard hook | § Core 2, § Core 11, T20 |
| R27: agent instructions | § Core 4 |
| R28: plan docs page | § Core 10, T21 |
| R29: top bar | § Core 3, T9, T22 |
