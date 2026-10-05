# PRD: refine the rocinante hyprland build

terms used throughout: **host** (a physical machine with a name), **book** (the
mdbook in this repo), **spec** (what a host needs and why, os-agnostic),
**record** (a host's dated build log, append-only), **manifest** (a host's
package lists, files and units), **apply** (make the host match its manifest),
**drift** (report where they differ), **roadmap** (one page for things that do
not exist yet).

## Problem

rocinante (arch tower, game and dev box) was converted in place from xfce to
hyprland on 2026-10-03. it works. it is not finished, and one part of it has a
deadline.

1. **the desktop breaks on the next hyprland release.** 0.57 removes `.conf`
   support and the 0.56.2 binary on rocinante already warns about it. the
   dotfiles ship only `hyprland.conf`. arch is rolling, so the first
   `pacman -Syu` after 0.57 lands starts a session with no binds.
2. **the build record is unversioned.** it sits in `~/src/mhq/src/svc/infra`,
   which is not a git repo. the guide is a published page with no local source,
   and it is stale: it still says xfce and bash, and says to wait a week.
3. **the box does not match its record.** found on 10-03: four unowned and five
   modified files in `/etc`, user units, `~/.config/uwsm/env` and mime defaults
   that are in no repo. a rebuild from the lists would not produce this box.
   xfce leftovers are still on disk.
4. **nothing is automated.** the rebuild is a runbook run by hand. nothing
   answers "does the host match the record". an upgrade has no way back.
5. **the homelab repo describes a fleet that is gone.** nixos vms on proxmox,
   the `<env>-<class>` names, a flake that imports a dotfiles output removed in
   `d5edeec`. the hosts that exist (rocinante, sector7) are not in it, and its
   `CLAUDE.md` tells agents everything is nix and forbids pacman and scripts.
6. **the dotfiles assume a layout that is not true here.** they hard-code
   `~/dotfiles`, `~/iamnande`, `~/homelab`, `~/rawr` and `~/opord`. repos now
   live at `~/src/<owner>/<repo>`, so senzu and seven skills cannot find state.
   two layouts and an alias point at defunct repos (`way`, `tardis`).
   `make a b` stows only `a`.
7. **daily-driver gaps.** no screenshots, no idle lock, no way to sleep the
   box, no volume or media keys, no man pages, light gtk apps, unthemed
   notifications, no ssh client config. the top bar is half themed (everforest
   values under catppuccin names, catppuccin literals in its config) and has
   no tray, so an app that closes to the tray has nowhere to show. for gaming:
   no overlay, no gamemode, vrr untested, lutris installed and never used,
   protonplus is a flatpak that drags in 3G of runtimes.
8. **the agent guard hook does not run here.** `~/.claude/hooks` is stowed but
   `~/.claude/settings.json` has no hooks.
9. **plan docs are hard to take in.** a PRD is 300 lines of raw markdown read in
   a terminal, and the plan skill writes it to a gitignored `plan/` that has to
   be force-added.

affected: nick, daily, on rocinante. sector7 shares the dotfiles.

## Solution

1. cut the hyprland config over to `hyprland.lua` with no change in behavior,
   and delete `hyprland.conf` in the same change. lands first. (R1)
2. move the dotfiles to the `~/src/<owner>/<repo>` layout and purge `way` and
   `tardis`. (R2, R3)
3. one make command that stows every component. (R4)
4. round out the desktop: screenshots, idle lock, a power menu with sleep,
   volume and media keys, everforest notifications, dark gtk, an ssh client
   config, a refreshed top bar. (R5 to R10, R29)
5. refresh the homelab repo: delete the dead content, build a book from what
   exists (network, hosts, deployment, roadmap), and rewrite the agent
   instructions on the dotfiles model. (R11 to R13, R24, R27)
6. move the build record in as rocinante's manifest and record, capture the
   drift, and rewrite the guide as "how to build it". (R14, R15)
7. add `apply` and `drift`. (R16, R17)
8. snapshot the root before every upgrade. (R18)
9. bring rocinante up to the agreed package and settings list, key-only ssh
   included, and delete the leftovers. (R19 to R22)
10. give sector7 an inventory page and the commit-to-cluster path. (R23)
11. housekeeping: version opord, wire in the guard hook. (R25, R26)
12. plan docs move to `docs/prds` and get a browser view. (R2, R28)

## Configuration

| parameter | where | value |
|---|---|---|
| idle: lock after | dotfiles, hypridle | 10 min |
| idle: screen off after | dotfiles, hypridle | 15 min |
| idle: sleep | dotfiles, hypridle | never |
| screenshot binds | dotfiles, `hyprland.lua` | region `SUPER+SHIFT+S`, whole output `Print` |
| screenshot directory | dotfiles | `~/src/iamnande/opord/references/screenshots` |
| power menu bind | dotfiles, `hyprland.lua` | `SUPER+M`, replacing today's bare exit |
| volume step | dotfiles, `hyprland.lua` | 5% |
| notifications | dotfiles, mako | everforest colors. timeout unchanged: ten seconds, app timeouts ignored |
| top bar | dotfiles, waybar | left: workspaces 1 to 6. center: hostname. right: tray, idle-inhibit toggle, the stats drawer, clock, power button. *proposed*, and tuned live with nick at execute |
| gtk | rocinante manifest | color scheme `prefer-dark` |
| `vrr` | dotfiles, `hyprland.lua` | set by the outcome of the R21 test |
| nvidia session env | rocinante manifest | `~/.config/uwsm/env`. host-local: sector7 has no nvidia card |
| snapshot retention | rocinante manifest | keep the last 5 |
| sshd | rocinante manifest | keys only, no passwords, no root login |
| senzu state directory | dotfiles | `~/src/iamnande/opord/senzu`, the same on every host |
| `apply` and `drift` host | homelab | this host's name, from `/etc/hostname` |

## States

- **hyprland config format.** `conf only` (today) to `lua only`, in one step.
  a host moves when it pulls the dotfiles, and it must run hyprland 0.56 or
  later by then. rocinante already does. sector7 is on 0.55, so nick upgrades
  it before he pulls there.
- **session.** `active` to `locked` to `screen off` on idle. input brings the
  screen back to `locked`; unlocking returns to `active`. `asleep` is entered
  only from the power menu, and wakes to `locked`.
- **host against manifest.** `clean` or `drifted`. `drift` reports which;
  `apply` moves `drifted` to `clean`.
- **ssh on rocinante.** ends at `keys only`. key login is proven from a second
  host before the switch.

## Behavior

| | before | after |
|---|---|---|
| hyprland 0.57 arrives | session starts with no config | nothing changes |
| the hyprland config | `hyprland.conf` | `hyprland.lua`, the only config. the conf is gone |
| ten minutes idle | screen stays on, unlocked | locks, then the screen turns off. a game or video holding an idle inhibitor prevents both |
| "put the box to sleep" | type `systemctl suspend` | power menu, sleep |
| `SUPER+M` | exits the session at once | opens the power menu: lock, sleep, log out, reboot, shut down |
| screenshot | not possible | region or whole output, to the clipboard and to a file |
| volume and media keys | do nothing | change volume, mute, mute the mic, play, pause, next, previous |
| top bar | workspaces, hostname, clock, and a drawer of stats. no tray | the same, in everforest throughout, plus a tray, an idle-inhibit toggle and a power button |
| `pacman -Syu` | no way back | a read-only snapshot of `@` is taken first |
| "is this box what the record says" | read the readme and compare by hand | `drift` |
| rebuild | hand runbook plus undocumented `/etc` edits | install from the lists, then `apply` |
| a package is added | `pacman -S`, maybe a note | add it to a list with what asks for it, `apply`, `mkrepo`, a record row |
| `senzu`, `/iam-*` skills | look in `~/opord/senzu`, find nothing | find state in `~/src/iamnande/opord/senzu` |
| `make hypr mako` | stows `hypr` only | stows both |
| homelab readme | describes nixos vms on proxmox | points at the book |
| an agent opens homelab | told everything is nix, no pacman, no scripts | a short `AGENTS.md` that matches the repo |
| reviewing a PRD or tech spec | raw markdown in the terminal | the stream's page in the browser: a contents rail, every Rn linked to its requirement, real tables |

## API

no network surface. command-line only; exact names and flags are set in the
tech spec.

- homelab: `apply`, `drift`, and `mkrepo` (moved from the old record).
- dotfiles: one make target that stows every component.
- hyprland binds added: screenshot region, screenshot output, power menu, and
  the `XF86Audio*` keys.

## Lifecycle

- **changing a host.** edit the manifest, run `apply`, run `mkrepo`, append a
  row to the record, commit. `apply` needs root for packages and `/etc`, so
  nick runs it; agents do not run sudo.
- **snapshots.** created by a pacman hook before an upgrade, pruned to the
  retention count, read-only. rolling back is a documented manual step.
- **`hyprland.conf`.** deleted in the change that adds `hyprland.lua`. the way
  back is the previous dotfiles commit.
- **screenshots.** files in opord's `references/screenshots`. opord is a git
  repo after R25; committing a screenshot is done by hand.
- **the plan docs page.** one private page per stream. published at the first
  PRD draft, republished to the same link whenever a doc changes, link kept in
  the state file. the markdown in git stays the source of truth.
- **opord.** a git repo with a private remote on nick's github. nick creates
  the remote and pushes; agents commit locally. the work devbox copy goes to a
  separate private org, later, and nothing personal goes there.
- **the published guide.** superseded by the book. it stays published until
  nick takes it down.
- **the old record.** `~/src/mhq/src/svc/infra` is emptied by the move.
  `vendor/` keeps living on disk, untracked. where it sits is a tech spec call,
  because a worktree has no `vendor/`.
- **two repos.** dotfiles and homelab, one branch each unless the tech spec
  stacks the lua port ahead. pushes are nick's.
- **sector7.** nothing reaches it until nick pulls there, so it cannot change
  by accident. in order: upgrade hyprland to 0.56 or later, move its clones to
  `~/src/iamnande/<repo>`, pull, restow every component. nick's action, at
  rollout.

## Edge Cases

- **a host pulls before it upgrades.** on hyprland 0.55 there is no conf left
  to read, so the session would start without nick's binds. not handled in the
  dotfiles: the order is upgrade, then pull, and both are manual. the fix for
  a wrong order is to check out the previous commit or finish the upgrade.
- **a bind calls a tool the host lacks.** the bind does nothing. each host's
  manifest lists what its binds need. sector7's additions are out of scope.
- **one bar, two hosts.** the waybar config is shared. modules are picked so
  the same file works on a wired tower and a wifi box; nothing in it assumes
  nvidia or a battery.
- **key-only ssh lockout.** key login is proven from a second host before the
  switch. the box has a local console, so a mistake is recoverable.
- **the screenshot directory is missing** (a fresh host, opord not there yet).
  the bind creates it.
- **suspend on nvidia.** untested, and an agent must not suspend the box it
  runs on. nick tests sleep and wake. if wake fails, the sleep entry comes out
  of the menu and the fix goes on the roadmap.
- **the snapshot fails** (disk full, subvolume missing). the upgrade aborts. no
  upgrade without a way back.
- **`apply` stops halfway.** rerunning it finishes the job. it never removes a
  package that is not in a list; it reports it and leaves the call to nick.
- **`drift` without root.** it reads only what a normal user can. files it
  cannot read are reported as unchecked, not as clean.
- **`vendor/` is 2.7G.** it is ignored by git so it cannot be committed by
  accident.
- **host addresses in a public ssh config.** not handled in the PRD; the tech
  spec decides whether host entries live in the dotfiles or in a local include.
- **bluetooth.** no radio in the box. `bluez` stays installed and disabled.
  roadmap.
- **`~/src/mhq/src/svc/secrets/vendor/1password`.** the aur build directory for
  1password. `mkrepo` reads it today; the tech spec says where it goes.

## Observability

- `drift` prints one line per difference and exits nonzero when there is any.
- `apply` prints each change it makes, and nothing when the host is clean.
- the snapshot hook names the snapshot it took in pacman's output, so it lands
  in `/var/log/pacman.log`.
- every change to the host is a dated row in its record.
- metrics and alerting: N/A, one desktop and one user.

## Scope & Non-Goals

**in scope:**
- dotfiles: the lua port, the repo layout, the `way` and `tardis` purge, the
  stow-all target, screenshots, hypridle, the power menu, volume and media
  keys, the mako theme, the top bar, an ssh client config, the plan docs path
  and page.
- homelab: delete the dead content, the agent instructions, the book, the
  roadmap, rocinante's spec, manifest, record and rebuild chapters, `apply`,
  `drift`, `mkrepo`, the snapshot hook, sector7's inventory page and deploy
  path.
- rocinante: the package list in R19, key-only ssh, gtk dark, the vrr test,
  the leftovers.
- opord: `git init` in `~/src/iamnande/opord`, and a private remote on nick's
  github.

**out of scope:**
- a nixos migration for rocinante. roadmap, gated on gaming working there.
- brew. decided against: arch native, one list per host.
- closing the remaining security gaps on rocinante and sector7. its own
  stream, tracked outside this repo.
- sector7's build record and upgrade cadence. a later stream.
- what runs in the cluster.
- hosting the book. it is served with `mdbook serve` on rocinante for now.
- the personal tracking system, and senzu as a service with a mobile-first web
  ui. its own stream. the plan docs page (R28) is the one piece of it here.
- the work devbox copy of opord. nick, later.
- automatic sleep.
- upgrading hyprland on sector7. nick does it before he pulls there.
- archiving `way` and `tardis` on github. nick, in the github ui.
- nvidia suspend units. not needed, the driver handles suspend itself.
- checked on 10-03 and left out: cliphist, snapper, linux-lts, gamescope, just,
  tumbler, thunar-volman.
- writing the host name stories. nick writes them; the pages ship with the
  slot.

## Design Decisions Summary

| decision | options considered | chosen | rationale |
|---|---|---|---|
| where the record lives | stay in `~/src/mhq`; the homelab repo | the homelab repo | versioned, and next to the rest of the lab docs |
| automation level | nixos now; a config tool; plain bash | plain bash | a nixos move is planned, so the arch automation stays thin |
| packages | brew; arch native | arch native, one list per host | repeatability is the goal, not a second package manager |
| guide format | published page; mdbook | mdbook, served locally | the source lives in git. hosting is later |
| the move to lua | lua plus a frozen conf; lua and conf kept in step; a straight cutover | a straight cutover | one config and nothing to keep in step. sector7 only changes when nick pulls there, and he upgrades it first |
| idle | lock, off, sleep; lock, off | lock, then screen off | sleep cuts steam downloads and ssh sessions |
| sleep trigger | idle timer; power menu | power menu | same reason. sleep is a choice |
| snapshot tool | snapper; a plain pacman hook | a plain hook | one subvolume, nothing to configure, nothing to carry to nixos |
| protonplus | flatpak; aur | aur | drops flatpak and 3G of runtimes, and the package lands in the offline repo |
| repo layout | `~/<repo>`; `~/src/<owner>/<repo>` with symlinks; without | `~/src/<owner>/<repo>`, no symlinks | one layout on every host |
| the old nix | keep the tree; delete and link | delete, link from the roadmap | git history keeps it: `homelab@3ceb91d`, dotfiles before `d5edeec` |
| sector7 depth | full build record; inventory and deploy path | inventory and deploy path | the full record is the next stream |
| host names | `<env>-<class>` convention; chosen names | chosen names, each with its story | the convention is dead |
| deployment wording | name the tooling; describe the shape | "gitops, self-hosted, k3s" | the repo is public |
| security gaps | close them all here; their own stream | key-only ssh on rocinante here, the rest in their own stream | they span both hosts, and a public repo is the wrong place to list them |
| agent instructions | patch the nix rules out of `CLAUDE.md`; rewrite on the dotfiles model | rewrite: one real `AGENTS.md`, `CLAUDE.md` only imports it | the old file describes a repo that no longer exists. a few rules that change behavior age better than a repo tour |
| opord remote | local only; a private repo on nick's github | a private repo on nick's github | state survives the box. the work copy gets its own private home |
| where plan docs live | `plan/`; `docs/prds/` | `docs/prds/` | nick's call |
| reading plan docs | raw markdown; a hand-built page per doc; `mdbook serve`; one viewer page that renders the markdown | one viewer page that renders the markdown | one source and no second copy to drift. it works in any repo, with no book around the docs |

## Requirements

- **R1 lua config.** on hyprland 0.56 or later the session loads
  `hyprland.lua` with no deprecation warning, and every bind, autostart and
  monitor rule in today's `hyprland.conf` behaves the same, 240hz included.
  `hyprland.conf` is deleted in the same change. lands first, on its own.
- **R2 repo layout.** nothing in the dotfiles refers to `~/dotfiles`,
  `~/iamnande`, `~/homelab`, `~/rawr` or `~/opord`. repos resolve at
  `~/src/<owner>/<repo>` and senzu state at `~/src/iamnande/opord/senzu`.
  `~/worktrees` is unchanged. no symlinks in `~`. the plan skill and
  `docs/agents.md` put plan docs in `docs/prds/<date>_<slug>/`, not `plan/`.
- **R3 defunct repos.** `way` and `tardis` are gone from the dotfiles: the
  `way` tab, `tardis.kdl`, the `tardis` alias, the `~/way` test.
- **R4 stow all.** one make command stows every component, and `make a b`
  stows both.
- **R5 screenshots.** one bind captures a region, one the whole output. the
  result is on the clipboard and in a file under
  `~/src/iamnande/opord/references/screenshots`.
- **R6 idle.** the session locks after the idle timeout, then the screen turns
  off. it never sleeps on its own. an idle inhibitor prevents both.
- **R7 power menu.** one bind opens a menu with lock, sleep, log out, reboot
  and shut down. sleep suspends to ram and wakes to the lock screen.
- **R8 volume and media keys.** volume up, down and mute, mic mute, play or
  pause, next, previous.
- **R9 look.** notifications use everforest colors and keep the ten second
  timeout. gtk apps are dark.
- **R10 ssh client.** the dotfiles ship an ssh client config that uses the
  1password agent.
- **R11 dead content.** gone from homelab: the nixos tree, the hypervisor doc,
  the empty `iac`, `platform`, `services` and `storage` scaffolding,
  `ARCHITECTURE.md` and the naming convention. the roadmap links the old nix
  at `homelab@3ceb91d` and the dotfiles before `d5edeec`.
- **R12 book.** `mdbook serve` renders the book with no errors or broken
  links. it covers network, hosts, deployment and the roadmap. apart from the
  plan docs in `docs/prds`, it is the only prose documentation; the readme
  points at it.
- **R13 host pages.** each host has a spec, a name section (source, nick's
  experience with it, why he chose it), its manifest and its record.
- **R14 manifest.** rocinante's manifest is in homelab: package lists where
  each package says what asks for it, system files, user files and units. it
  covers every item in the 10-03 drift list. `vendor/` is untracked and
  ignored.
- **R15 rebuild chapters.** rocinante's chapters take the box from the arch iso
  to the desktop, in order, with commands that run in both bash and fish. the
  conversion as it happened lives in the record.
- **R16 apply.** one bash command makes the host match its manifest. a second
  run changes nothing and says so.
- **R17 drift.** one read-only command, no root, reports every difference
  between host and manifest in both directions. it exits zero only when there
  is none.
- **R18 snapshots.** every pacman upgrade first takes a read-only snapshot of
  `@`. old snapshots are pruned. the book says how to roll back.
- **R19 packages.** installed and in the manifest: hypridle, grim, slurp,
  noto-fonts-emoji, noto-fonts-cjk, man-db, man-pages, less, ripgrep, fd,
  btop, tree, fastfetch, github-cli, pacman-contrib, fzf, marksman, k9s,
  difftastic, mangohud, gamemode, mdbook, and from the aur protonplus,
  1password-cli and golangci-lint-langserver (helix already calls it).
  removed: lutris, the protonplus flatpak and then flatpak itself,
  `yay-debug`.
- **R20 key-only ssh.** rocinante's sshd accepts nick's key and refuses
  passwords.
- **R21 gaming.** mangohud and gamemode work per game from steam launch
  options. vrr is tested on the AOC, the result is in the record, and `vrr` is
  set to match.
- **R22 leftovers.** gone: `/etc/X11/xorg.conf.d/00-keyboard.conf`,
  `~/.config/xfce4`, `~/.xsession-errors*`, `~/.dmrc`, `~/.Xauthority`,
  `~/.ICEauthority`.
- **R23 sector7.** the book has an inventory page for sector7 (hardware, os,
  packages, what it runs) and the path from a commit to the cluster, described
  as "gitops, self-hosted, k3s". the inventory script is in the repo.
- **R24 public repo.** nothing committed to homelab names the deploy product
  behind sector7, and nothing publishes a host's open security gaps.
- **R25 opord.** `~/src/iamnande/opord` is a git repo with the state files
  committed and a private remote on nick's github. nick creates the remote and
  pushes.
- **R26 guard hook.** `claude-guard` runs in agent sessions on rocinante, and
  its deny paths match the new layout. nick applies both; the agent hands over
  the diff.
- **R27 agent instructions.** homelab's agent instructions follow the dotfiles
  model: one real file, `AGENTS.md`, and a `CLAUDE.md` that only imports it. it
  holds a short list of rules that change behavior and are true of this repo
  (it is public, a host changes through its manifest, the book is the only
  prose, the terms at the top of this doc) and a note on keeping the list
  pruned. no repo tour, no nix rules.
- **R28 plan docs page.** the plan skill publishes a stream's PRD and tech spec
  as one private page rendered from the markdown files, republishes it when a
  doc changes, and records the link in state. the viewer is one template in
  the skill; no per-stream html is written.
- **R29 top bar.** waybar is in everforest throughout: no catppuccin names or
  literal colors left in its config or styles. it keeps workspaces 1 to 6, the
  hostname, the clock and the stats drawer, and gains a tray, an idle-inhibit
  toggle and a button that opens the power menu. the same config works on both
  hosts.
