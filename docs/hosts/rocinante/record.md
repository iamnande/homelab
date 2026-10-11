# record

the dated log of what was done to rocinante, in order. it is append-only: a
change to the host adds a row, and old rows are not rewritten.

every date is 2026 and every time is pacific. rows 1 to 18 were read back from
`/var/log/pacman.log` and the shell history. the rest were written down as they
happened.

## the gaming box, 09-19 to 09-27

| # | when | what | how |
| --- | --- | --- | --- |
| 1 | 09-19 16:51 | base system | archinstall from the iso (see below) |
| 2 | 09-19 16:54 | network | `/etc/systemd/network/20-wired.network`, enable `systemd-networkd` and `systemd-resolved`, `ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf` |
| 3 | 09-19 17:11 | firefox | `pacman -S` |
| 4 | 09-19 17:13 | multilib | uncomment `[multilib]` in `/etc/pacman.conf`, `pacman -Sy` |
| 5 | 09-19 17:14 | nvidia-utils lib32-nvidia-utils vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools steam lutris | `pacman -S` (168 packages) |
| 6 | 09-19 17:16 | git | `pacman -S` |
| 7 | 09-19 17:2x | sshd | `systemctl enable --now sshd` |
| 8 | 09-19 18:06 | protontricks | `pacman -S` |
| 9 | 09-19 19:07 | wmctrl xdotool | `pacman -S` |
| 10 | 09-19 20:11 | flatpak, protonplus | `pacman -S flatpak`, `flatpak install flathub com.vysp3r.ProtonPlus` (3G of runtimes) |
| 11 | 09-19 | proton builds | through protonplus: GE-Proton10-28, Proton-GE Latest, Proton-EM Latest |
| 12 | 09-20 14:51 | claude code | `curl -fsSL https://claude.ai/install.sh \| bash`, `~/.local/bin` on the path |
| 13 | 09-20 15:30 | flameshot scrot xorg-xwininfo | `pacman -S` |
| 14 | 09-20 15:37 | sudo policy | a file under `/etc/sudoers.d`. not kept in this repo |
| 15 | 09-20 19:17 | pipewire-pulse pipewire-alsa wireplumber realtime-privileges | `pacman -S`, `systemctl --user enable pipewire pipewire-pulse wireplumber`, user in `realtime` |
| 16 | 09-27 17:47 | base-devel | `pacman -S` |
| 17 | 09-27 17:49 | yay 13.0.1 | `makepkg -si` in `vendor/yay` (pulls `go` in as a build dependency) |
| 18 | 09-27 17:50 | 1password 8.12.36 | `yay -S 1password`, signing key from `https://downloads.1password.com/linux/keys/1password.asc` |

row 1, archinstall, in the order it installed:

1. `base sudo linux linux-firmware mkinitcpio btrfs-progs amd-ucode`
2. `zram-generator`
3. `grub`, `efibootmgr`
4. `nvidia-open libva-nvidia-driver`
5. `nano vim openssh htop wget smartmontools xdg-utils`
6. `xfce4 xfce4-goodies pavucontrol gvfs xarchiver`
7. `xorg-server xorg-xinit`
8. `lightdm lightdm-gtk-greeter`

the answers it was given: 1G fat32 `/boot`, the rest btrfs (`compress=zstd:3`)
with `@`, `@home`, `@log`, `@pkg`. grub at the removable path
(`EFI/BOOT/BOOTX64.EFI`) loading a unified kernel image. zram swap. no network
config and no audio, both done by hand later. user `iamnande` in `wheel`.
`US/Pacific`, `en_US.UTF-8`, `us` keymap.

things that never landed: `nvidia-open-dkms` (conflicts with `nvidia-open`),
`pipewire-jack` (conflicts with `jack2`), and NetworkManager (never installed,
so the `enable` for it in the shell history did nothing).

## the hyprland conversion, 10-03

done in place. no reflash: the base stayed, hyprland went on top, and xfce came
off once steam ran under it.

| # | when | what | how |
| --- | --- | --- | --- |
| 19 | 10-03 16:34 | full upgrade | `pacman -Syu`, the first since install (linux 7.2.8) |
| 20 | 10-03 16:42 | hyprland desktop | `pacman -S --needed - < pkg/40-hypr.txt`, `~/.config/uwsm/env`, `systemctl --user enable hyprpolkitagent` |
| 21 | 10-03 16:44 | dev tools | `pacman -S --needed - < pkg/50-dev.txt`, `pacman -D --asexplicit go`, `rustup default stable` |
| 22 | 10-03 16:47 | dotfiles | one `make` per component, then `make fisher` |
| 23 | 10-03 16:51 | 1password ssh agent | settings, developer. `~/.ssh/iamnande.pub` from `allowed_signers`, git remotes moved to ssh |
| 24 | 10-03 17:05 | login switch | `chsh -s /usr/bin/fish`, `systemctl disable lightdm`. tty1, fish, uwsm, hyprland |
| 25 | 10-03 17:12 | bluez bluez-utils | `pacman -S`. there is no bluetooth radio in the box, so `bluetooth.service` stays off |
| 26 | 10-03 17:28 | mako | `pacman -S mako`, `make mako` in the dotfiles (ten second timeout). replaces `xfce4-notifyd` |
| 27 | 10-03 17:29 | xfce retired | `pacman -Rnsu` on the `xfce4` and `xfce4-goodies` groups, xorg-server, lightdm and the x11 helpers: 100 packages. `exo` and `xfconf` stay for thunar, marked `--asdeps` |

the commands as they ran that day. the build files still lived outside this
repo then, so the paths are the old ones.

```sh
cd ~/src/mhq/src/svc/infra

# first full upgrade since install
sudo pacman -Syu

# 94 packages, about 420M
sudo pacman -S --needed - < pkg/40-hypr.txt
sudo pacman -S --needed - < pkg/50-dev.txt
sudo pacman -D --asexplicit go

# dotfiles, one make per component
cd ~/src/iamnande/dotfiles
make agents
make backgrounds
make bin
make fish
make ghostty
make git
make helix
make hypr
make mako
make waybar
make wofi
make zellij
make fisher

# login: tty1, fish, uwsm, hyprland
chsh -s /usr/bin/fish
sudo systemctl disable lightdm
```

the monitor had been running at 60hz under xfce, the mode it advertises as
preferred. the hyprland config asks for the highest rate instead, and it has
run at 239.96hz since.

## the refinement, 10-04 to 10-10

the build files moved into this repo as the manifest, and from row 30 on the
host changes through `bin/apply`.

| # | when | what | how |
| --- | --- | --- | --- |
| 28 | 10-04 21:57 | full upgrade, and the tools that build the book | `pacman -Syu --needed mdbook mdbook-mermaid lychee shellcheck` (61 packages). two tries with `-S` alone failed with 404s, because the package database was a day old |
| 29 | 10-04 22:09 | build files moved into this repo | the lists, the system files and `mkrepo` became `hosts/rocinante/` and `bin/`. `vendor/` moved to `~/src/iamnande/homelab/vendor`. `bin/mkrepo`: 845 packages |
| 30 | 10-04 22:13 | first `bin/apply` | 23 packages from the repos (53 with dependencies), then `protonplus`, `1password-cli` and `golangci-lint-langserver-bin` from the aur. `~/.config/pacman/makepkg.conf`, `playerctl` marked explicit, gtk set to dark |
| 31 | 10-04 22:24 | protonplus runs natively | the service calls `/usr/bin/protonplus update all` in place of the flatpak. the timer lost `Persistent=true`, which kept it from firing whenever the login came more than a minute after boot. `bin/apply`, restart the timer, start the service once |
| 32 | 10-10 14:11 | lutris, flatpak and the xfce leftovers removed | `flatpak uninstall --all`, `pacman -Rns lutris flatpak yay-debug` (59 packages), `/etc/X11/xorg.conf.d/00-keyboard.conf`, `~/.config/xfce4` and the x session files under `~`. `usermod -aG gamemode iamnande` |
| 33 | 10-10 14:17 | snapshot store | `@snapshots` created at the top level of the filesystem, `mkdir /.snapshots`. then `bin/apply`: the fstab line, the pacman hook and `/usr/local/bin/snapshot-root`. first pair `2026-10-10T21-18-20Z` |
| 34 | 10-10 14:17 | my key authorized for ssh | the same `bin/apply` installed `~/.ssh/authorized_keys`. a key login from a second host was accepted before row 38 |
| 35 | 10-10 14:33 | what row 32 left behind | the flatpak and lutris data and caches under `~`, `/var/lib/flatpak`, and `pacman -Rns gnome-desktop meson vala` (28 packages) |
| 36 | 10-10 14:35 | full upgrade | `pacman -Syu`. the hook took `2026-10-10T21-35-16Z` first, then 110 packages with linux 7.2.9 and nvidia-open 615.78.08. reboot |
| 37 | 10-10 14:40 | prune seen working | four more `snapshot-root` runs made six pairs. it kept five and removed the oldest with its image |
| 38 | 10-10 15:03 | ssh takes keys only | `bin/apply` installed `/etc/ssh/sshd_config.d/10-keys-only.conf`, ran `sshd -t` and reloaded sshd. from the second host a key login works and a password login is refused |
| 39 | 10-10 15:19 | offline repo refreshed | `bin/mkrepo`: 839 packages, 2.9G |
| 40 | 10-10 19:09 | a keyring, unlocked by the login | `bin/apply` installed `gnome-keyring` and `/etc/pam.d/login`, the stock file plus two `pam_gnome_keyring.so` lines. 1password had no secret store to keep this host's two-factor token in, so every unlock asked for a code. reboot: a login into a user session that is already running does not start the keyring's socket |

two things worth keeping from these rows:

- **install with the upgrade.** `pacman -S` against an old database asks the
  mirrors for versions they no longer carry. `pacman -Syu` with the names, and
  never `-Sy` alone.
- **`Persistent=true` on a timer that only has boot and interval triggers.**
  once a stamp file exists, a trigger time that has already passed at start is
  dropped, and the interval has nothing to count from. the timer is dead for
  that boot.

## checked, and not

| when | what |
| --- | --- |
| 10-03 | a clean root resolves every list from the offline repo alone: 783 packages, no network |
| 10-10 | `bin/drift` exits 0 |
| 10-10 | the same resolve after the upgrade: 109 names, 822 packages, every file present in the repo |
| 10-10 | after the reboot the login unlocks the keyring, and a second 1password unlock asks for no code |
| 10-10 | variable refresh over hdmi: not available. the driver reports the output as `vrr_capable: 0`, and the monitor's edid offers it there as freesync (48 to 240hz), not as hdmi 2.1 vrr |
| never | the [build](build.md) chapter end to end, from the iso |
| never | a [rollback](operate.md#rolling-back) to a snapshot |
