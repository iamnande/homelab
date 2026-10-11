# build

from the arch iso to the desktop, in order. there are two starting points:

- **the disk is fine and the root is not.** keep `@home`, `@log`, `@pkg`,
  `@snapshots` and the boot partition, and replace only `@`. the repos, the
  offline repo and the steam library are all in `@home`, so nothing is
  downloaded.
- **a new or wiped disk.** the same steps, plus the ones marked **new disk**.

if the box still boots and the problem is an upgrade,
[roll back](operate.md#rolling-back) instead. that is minutes, this is an
evening.

checked: the package lists resolve from the offline repo alone, with no
network (see the [record](record.md#checked-and-not)). not checked: this
chapter end to end. it has never been run from the iso. the steps are a
standard arch install fitted to this disk and this manifest.

every command here runs in bash and in fish. the iso boots into zsh, and
nothing here goes beyond what all three share.

## the layout

```text
nvme0n1  samsung 990 evo 2T, gpt
├─ p1  1G    fat32  /boot
│              grub at EFI/BOOT/BOOTX64.EFI
│              loads the unified kernel image EFI/Linux/arch-linux.efi
└─ p2  1.8T  btrfs, compress=zstd:3
     @           /
     @home       /home                   steam, the repos, the offline repo
     @log        /var/log
     @pkg        /var/cache/pacman/pkg
     @snapshots  /.snapshots             one pair per upgrade
```

swap is 4G of zram. there is no swap partition.

## 1. the disk

boot the arch iso.

keeping the disk: move the old root aside and make an empty one.

```sh
mount -o subvolid=5 /dev/nvme0n1p2 /mnt
mv /mnt/@ /mnt/@old
btrfs subvolume create /mnt/@
umount /mnt
```

**new disk:** partition it with `cfdisk /dev/nvme0n1` as in the layout (gpt, a
1G efi system partition, the rest linux filesystem), then make the filesystems
and all five subvolumes.

```sh
mkfs.fat -F 32 /dev/nvme0n1p1
mkfs.btrfs /dev/nvme0n1p2
mount /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@ /mnt/@home /mnt/@log /mnt/@pkg /mnt/@snapshots
umount /mnt
```

either way, mount everything where the new system expects it.

```sh
mount -o subvol=@,compress=zstd:3,discard=async /dev/nvme0n1p2 /mnt
mount --mkdir -o subvol=@home,compress=zstd:3,discard=async /dev/nvme0n1p2 /mnt/home
mount --mkdir -o subvol=@log,compress=zstd:3,discard=async /dev/nvme0n1p2 /mnt/var/log
mount --mkdir -o subvol=@pkg,compress=zstd:3,discard=async /dev/nvme0n1p2 /mnt/var/cache/pacman/pkg
mount --mkdir -o subvol=@snapshots,compress=zstd:3,discard=async /dev/nvme0n1p2 /mnt/.snapshots
mount --mkdir -o fmask=0077,dmask=0077 /dev/nvme0n1p1 /mnt/boot
```

**new disk:** this repo has to be on the disk before the next step, at
`/mnt/home/iamnande/src/iamnande/homelab`. copy a clone over from the stick
that carries the offline repo (see [operate](operate.md#the-offline-repo)),
with `vendor/repo` inside it. with a network and no stick, clone it:

```sh
pacman -Sy git
git clone https://github.com/iamnande/homelab /mnt/home/iamnande/src/iamnande/homelab
```

## 2. packages

from the offline repo. this installs exactly what the box last ran, the aur
packages included, because `bin/mkrepo` keeps their built files too.

```sh
cd /mnt/home/iamnande/src/iamnande/homelab
printf '%s\n' '[options]' 'Architecture = auto' 'SigLevel = Optional TrustAll' '[mhq]' 'Server = file:///mnt/home/iamnande/src/iamnande/homelab/vendor/repo' > /tmp/mhq.conf
pacstrap -C /tmp/mhq.conf /mnt $(bin/pkglist rocinante) $(bin/pkglist rocinante --aur)
```

if pacstrap stops on a signature it cannot check (an old iso has an old
keyring), change `SigLevel` to `Never`. every file in the repo was verified
when it was first downloaded.

with no offline repo, install from the mirrors instead. the manifest's
`pacman.conf` turns on multilib, which the 32-bit libraries need. the aur
packages wait for step 5.

```sh
cd /mnt/home/iamnande/src/iamnande/homelab
pacstrap -C hosts/rocinante/root/etc/pacman.conf /mnt $(bin/pkglist rocinante)
```

## 3. system files

still in the repo:

```sh
cp -r hosts/rocinante/root/. /mnt/
ln -sf /usr/share/zoneinfo/US/Pacific /mnt/etc/localtime
ln -sf /run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
```

the first line lays down every system file in the manifest: the hostname, the
locale and the console keymap, `fstab`, `pacman.conf`, the kernel command line
and the image preset, the grub entry, zram, the wired network, the sshd
drop-in, the login pam file that unlocks the keyring, and the snapshot hook
with its script.

**new disk:** `fstab` and `etc/kernel/cmdline` name the old disk's filesystems
by id. `blkid /dev/nvme0n1p1 /dev/nvme0n1p2` prints the new ones. put the two
`UUID` values in `/mnt/etc/fstab` and the `PARTUUID` of `p2` in
`/mnt/etc/kernel/cmdline`, and commit both back to the manifest after the
first boot.

## 4. inside the new root

```sh
arch-chroot /mnt
locale-gen
hwclock --systohc
useradd -u 1000 -U -G wheel,realtime,gamemode -s /usr/bin/fish iamnande
passwd iamnande
sed 's/#.*//' /home/iamnande/src/iamnande/homelab/hosts/rocinante/units.txt | xargs systemctl enable
mkinitcpio -P
```

- **new disk:** add `-m` to `useradd` so it makes the home directory, and then
  `chown -R iamnande:iamnande /home/iamnande`, because the clone from step 1
  belongs to root.
- give `iamnande` sudo with `visudo`. the policy is a file under
  `/etc/sudoers.d` and is not kept in this repo.
- the `sed` line enables the units in `units.txt`: the network, time sync and
  sshd. a fresh install enables none of them.
- `mkinitcpio -P` builds the unified kernel image from the command line and
  the preset copied in step 3, at the path grub already loads. if pacstrap
  left a `/boot/initramfs-linux.img` behind, nothing uses it and it can go.

**new disk:** grub is not on the boot partition yet.

```sh
grub-install --target=x86_64-efi --efi-directory=/boot --removable
grub-mkconfig -o /boot/grub/grub.cfg
```

then leave and reboot.

```sh
exit
umount -R /mnt
reboot
```

## 5. first login

log in on tty1 as `iamnande`.

keeping the disk, the dotfiles are still linked in `@home`, so fish hands
straight over to hyprland.

**new disk:** there are no dotfiles yet, so it is a bare fish prompt. clone
them, or copy the clone from the stick, and link every component. then log out
and back in.

```sh
git clone https://github.com/iamnande/dotfiles ~/src/iamnande/dotfiles
cd ~/src/iamnande/dotfiles
make all
make fisher
```

if step 2 used the mirrors, yay has to be built by hand before `apply` can
build the rest of `aur.txt`. the first line stops makepkg from building a
`-debug` package beside it, and the second fetches the key 1password's build
is checked against.

```sh
cd ~/src/iamnande/homelab
install -D -m 644 hosts/rocinante/home/.config/pacman/makepkg.conf ~/.config/pacman/makepkg.conf
curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import
git clone https://aur.archlinux.org/yay.git vendor/yay
cd vendor/yay
makepkg -si
```

then, from a terminal in the session, make the host match its manifest. this
is where the files under `~`, the user units and the gtk settings arrive.

```sh
cd ~/src/iamnande/homelab
bin/apply
```

## 6. identity

open 1password, sign in, and turn on the ssh agent under settings, developer.
`ls -l ~/.1password/agent.sock` then shows a socket, and the fish config
points `SSH_AUTH_SOCK` at it.

**new disk:** git signs with `~/.ssh/iamnande.pub`, which is not in the
dotfiles. the same key is in `allowed_signers`, which `make git` linked. write
it out, check the agent holds it, and move the clones from https to ssh.

```sh
awk '{print $2, $3}' ~/.ssh/allowed_signers > ~/.ssh/iamnande.pub
ssh-add -L
ssh -T git@github.com
git -C ~/src/iamnande/dotfiles remote set-url origin git@github.com:iamnande/dotfiles.git
git -C ~/src/iamnande/homelab remote set-url origin git@github.com:iamnande/homelab.git
```

the new root has new ssh host keys either way, so every client that has
logged in here before will warn once.

## 7. what lives outside pacman

keeping the disk, all of this is in `@home` already.

**new disk:**

```sh
rustup default stable
rustup component add rust-analyzer
curl -fsSL https://claude.ai/install.sh | bash
```

## 8. games

keeping the disk, the library, the proton builds and every prefix are in
`@home`. start steam and play.

**new disk:** copy the library back into `~/.local/share/Steam/steamapps`
before the first start, or let steam download it again. install the proton
builds with protonplus. its timer checks for new ones every hour from then on.

per game, in steam's launch options: `gamemoderun mangohud %command%`.

## 9. finish

```sh
cd ~/src/iamnande/homelab
bin/drift
bin/mkrepo
```

`drift` prints nothing and exits 0 when the host matches. then add a row to
the [record](record.md).

keeping the disk, the old root is still there as `@old`. once the new one has
proven itself, delete it. `-R` because systemd keeps two small subvolumes of
its own inside the root.

```sh
sudo mount --mkdir -o subvolid=5 /dev/nvme0n1p2 /mnt/top
sudo btrfs subvolume delete -R /mnt/top/@old
sudo umount /mnt/top
```

to read the book on the box, see [reading it](../../README.md#reading-it).
