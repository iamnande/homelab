# operate

how rocinante is changed and kept current. one rule: the manifest changes
first, then the host.

every command runs from the root of this repo, in bash or fish. `bin/drift`
and `bin/apply` read the host's name from `/etc/hostname`.

## changing the host

1. edit the manifest under `hosts/rocinante/`.
2. look at what will happen, then do it.
3. refresh the offline repo if a package came or went.
4. add a dated row to the [record](record.md).
5. commit.

```sh
bin/apply -n
bin/apply
bin/mkrepo
```

a package is one line in a list: the name, then what asks for it. repo
packages go in the numbered lists and anything from the aur goes in `aur.txt`.

```text
hypridle     # idle lock and screen off (dotfiles: hypr)
```

## drift

`bin/drift` reports where the host differs from its manifest. it is read-only
and needs no root. it prints one finding per line as `kind: what: subject`,
and exits 0 when there is none, 1 when there is any, 2 on an error.

| finding | means | `apply` |
| --- | --- | --- |
| `pkg: missing`, `aur: missing` | listed, not installed | installs it |
| `pkg: unlisted`, `aur: unlisted` | installed by hand, in no list | leaves it. list it or remove it |
| `pkg: dependency`, `aur: dependency` | listed, but installed as a dependency, so an orphan cleanup could take it | marks it explicit |
| `list: duplicate`, `list: malformed`, `list: foreign`, `list: native` | a mistake in a list file | leaves it. fix the list |
| `file: missing`, `file: differs`, `file: mode` | a manifest file is absent, different, or has the wrong executable bit | copies it |
| `file: unchecked` | `drift` could not read the target | leaves it |
| `file: pacnew` | a package shipped a newer default beside a managed file | leaves it. see [upgrading](#upgrading) |
| `unit: disabled`, `user-unit: disabled` | listed, not enabled | enables and starts it |
| `setting: differs` | a setting is not the listed value | sets it |
| `setting: unchecked` | the setting could not be read | leaves it |

it looks from the manifest to the host. the other direction is covered for
packages (`unlisted`) and not for files, so that check is by hand:

```sh
pacman -Qii | grep -F '[modified]'
```

that lists every packaged config file that has been edited. each one should be
in `root/`, or be one the system edits itself: `passwd`, `group`, `shells`,
`subuid`, `subgid`, `resolv.conf` and the mirrorlist.

## apply

`bin/apply` runs `drift` and fixes what it reports, so the two cannot
disagree. `bin/apply -n` prints the commands and changes nothing. on a host
that already matches, both print nothing.

- run it as yourself. it calls sudo where it needs to and refuses to run as
  root, because the files under `~` and the aur builds must not be root's.
- the order is repo packages, files, aur packages, units, settings. it stops
  at the first step that fails and is safe to run again.
- it installs with `pacman -S`, not `-Syu`. if the package database is more
  than a day or so old, [upgrade](#upgrading) first.
- it never removes anything. a removal is a command run by hand
  (`sudo pacman -Rns` and the line deleted from the list) and a row in the
  record.
- it reloads systemd after a unit file or `fstab` changes, and it does not
  restart what is running. restart the unit that changed yourself.
- when a file under `/etc/ssh` changes it runs `sshd -t` before the reload, so
  a bad config never reaches the running daemon.
- what `drift` reports and `apply` does not handle is printed as
  `apply: left alone: ...`.

## upgrading

```sh
sudo pacman -Syu
yay -Sua
bin/drift
bin/mkrepo
```

- pacman takes a snapshot before it touches anything and prints its name
  (`snapshot-root: ...`). if the snapshot fails, the upgrade does not happen.
- never `pacman -Sy` on its own, and never install against an old database.
  the mirrors only carry current versions.
- reboot when `linux` or `nvidia-open` moved. the modules of the running
  kernel are gone once the new one is installed.
- `file: pacnew` from `drift` means a package shipped a new default for a file
  the manifest manages. merge it with `pacdiff`, copy the result back into
  `root/`, and delete the `.pacnew`.
- add a row to the record with the kernel and driver versions.

## snapshots

every upgrade first adds a pair to `/.snapshots`: a read-only snapshot of the
root, and the unified kernel image as it was at that moment. the image is kept
because `/boot` is fat32 and outside the snapshot, and a root rolled back
without its image boots a kernel whose modules are gone. the newest five pairs
are kept.

```sh
ls /.snapshots
sudo snapshot-root
```

the second line takes one by hand, before anything risky that is not an
upgrade.

- the store is `@snapshots`, a subvolume beside the root and not inside it, so
  rolling the root back does not take the snapshots with it.
- `/home`, `/var/log` and the package cache are their own subvolumes. they are
  not in a snapshot and a rollback leaves them alone.
- `snapshot-root` refuses to run when `/.snapshots` is not that subvolume,
  mounted. no store, no upgrade.

to remove a pair by hand, with its name in place of `NAME`:

```sh
sudo btrfs subvolume delete /.snapshots/NAME
sudo rm /.snapshots/NAME.efi
```

## rolling back

this has never been run. each piece has been checked on its own: the pairs
exist, the image is copied, the prune works.

pick a pair with `ls /.snapshots` and put its name in place of `NAME`.

if the system still boots:

```sh
sudo mount --mkdir -o subvolid=5 /dev/nvme0n1p2 /mnt/top
sudo mv /mnt/top/@ /mnt/top/@broken
sudo btrfs subvolume snapshot /mnt/top/@snapshots/NAME /mnt/top/@
sudo cp /mnt/top/@snapshots/NAME.efi /boot/EFI/Linux/arch-linux.efi
sudo reboot
```

if it does not, the same from the arch iso:

```sh
mount -o subvolid=5 /dev/nvme0n1p2 /mnt
mv /mnt/@ /mnt/@broken
btrfs subvolume snapshot /mnt/@snapshots/NAME /mnt/@
mount --mkdir /dev/nvme0n1p1 /esp
cp /mnt/@snapshots/NAME.efi /esp/EFI/Linux/arch-linux.efi
umount /esp /mnt
reboot
```

once the rolled-back system has proven itself, delete the broken root and
bring the offline repo back in line with what is installed.

```sh
sudo mount --mkdir -o subvolid=5 /dev/nvme0n1p2 /mnt/top
sudo btrfs subvolume delete -R /mnt/top/@broken
sudo umount /mnt/top
bin/mkrepo
```

what to expect afterwards: pacman's database lives in the root, so it goes
back with it. the pacman log does not, so it still shows the upgrade that was
undone. the package cache still holds the newer files.

## the offline repo

`bin/mkrepo` copies the package file of everything installed into
`vendor/repo`, a pacman repo named `[mhq]`, and drops versions that are no
longer installed. the [build](build.md) chapter installs from it. run it after
every upgrade or install.

- `vendor/` is not in git. it lives in the main clone,
  `~/src/iamnande/homelab/vendor`, and a worktree writes to that same
  directory. `HOMELAB_VENDOR` points it somewhere else.
- repo packages come from the pacman cache. aur packages come from yay's cache
  and the build directories under `vendor/`.
- `bin/mkrepo DIR` writes the repo to another place, a usb stick for one. a
  rebuild on a new disk with no network needs that stick, with clones of this
  repo and the dotfiles beside it.

to check that the lists resolve from the repo alone, with no root and no
network:

```sh
mkdir -p /tmp/mhq/db/sync /tmp/mhq/root
cp ~/src/iamnande/homelab/vendor/repo/mhq.db.tar.zst /tmp/mhq/db/sync/mhq.db
printf '%s\n' '[options]' 'Architecture = auto' 'SigLevel = Optional TrustAll' '[mhq]' 'Server = file:///home/iamnande/src/iamnande/homelab/vendor/repo' > /tmp/mhq/pacman.conf
pacman --config /tmp/mhq/pacman.conf --dbpath /tmp/mhq/db --root /tmp/mhq/root -Sp $(bin/pkglist rocinante) $(bin/pkglist rocinante --aur) | wc -l
```

it prints how many packages a clean root would install, and names anything
the repo cannot supply.

## ssh

logins are by key only. to let another key in, add its line to
`hosts/rocinante/home/.ssh/authorized_keys` and run `bin/apply`.

the way back from a lockout is the local console: delete
`/etc/ssh/sshd_config.d/10-keys-only.conf` and `sudo systemctl reload sshd`.

## the login

tty1 logs me in at boot, and hyprland starts the lock first, so the lock
screen is the login. the password typed there unlocks the keyring through
`/etc/pam.d/hyprlock`, which includes `/etc/pam.d/login`. tty2 and up still
show the banner and ask for the password.

if the lock won't let me in: ctrl+alt+f2, log in, and turn the autologin
off.

```sh
sudo rm -r /etc/systemd/system/getty@tty1.service.d
sudo systemctl daemon-reload
```

then reboot, and tty1 asks for the password again. if hyprlock died, its
lock-died screen covers the desktop, and a reboot from tty2 brings a fresh
lock.

to undo the whole thing, turn the autologin off first, then revert the
dotfiles. the other order leaves a boot that logs in with no lock.

## proton builds

protonplus keeps the proton builds current from a user timer, hourly.

```sh
systemctl --user list-timers protonplus.timer
protonplus list steam-system
```
