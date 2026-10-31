# PRD: rocinante yubikey login

## Problem

The yubikey should be the only way into rocinante, and the only way to root on
it. A password joins the key where one is needed, at boot and on the ttys, and
never stands in for it. A key that leaves with me should mean something.

Affected: me, at the desk and over ssh. Nothing else logs in to this host.

## Solution

1. Install the key tooling through the manifest.
2. Enroll three personal YubiKey 5 NFC keys in a root owned mapping file, with
   OTP turned off on each.
3. The boot lock and ttys 2-6 ask for password + touch.
4. The idle lock asks for a touch only, through its own pam service.
5. The boot lock gets its own small config, so the two locks can differ.
6. The locks show a cue, and an idle lock with no key waits instead of retrying.
7. sudo asks for a touch only.
8. polkit and su ask for a touch only, which covers pkexec and run0 too.
9. ssh into rocinante takes `ed25519-sk` keys only.
10. The vault takes the master password once per boot, locks on idle, and
    unlocks with a touch after that.
11. Each change lands alone and is proven with a root shell open.
12. The book and record say how all of it works and how to get back in.

## Configuration

| what | where | value |
|---|---|---|
| key mappings | `/etc/u2f_mappings` | one line for my user, three keys |
| pam_u2f origin and appid | each pam line | `pam://rocinante` |
| touch cue | `cue_prompt=` | `Place your finger on the key` |
| idle lock service | `hyprlock.conf`, `auth:pam:module` | `hyprlock-touch` |
| boot lock service | `hyprlock-boot.conf`, `auth:pam:module` | `hyprlock` |
| vault timeout | the app's settings, by hand | 30 minutes, then lock |

## States

| prompt | asks for | no key |
|---|---|---|
| boot lock | password + touch | stays locked |
| ttys 2-6 | password + touch | no login |
| idle lock | enter + touch | stays locked |
| sudo | touch | no sudo |
| pkexec, run0 | touch | no root |
| su | touch, for a user with a mapping | fails, and root has no mapping |
| ssh in | `ed25519-sk` key + handle file | no login |
| vault, first unlock of a boot | master password | key not involved |
| vault, later unlocks | touch | master password still works |

## Behavior

- **Boot:** type the password, press enter, touch. The keyring unlocks only
  after both pass. The vault then asks for its master password on workspace 6.
- **Back at the idle lock:** plug in, press enter, touch.
- **The vault after idle:** it locks 30 minutes in, and the ssh agent and git
  signing stop with it until a touch unlocks it.
- **sudo:** the key blinks and the terminal says so. A touch earns the usual
  five minute ticket for that terminal.

## API

N/A: no external surface. Enrollment uses the stock `pamu2fcfg`, `ykman` and
`ssh-keygen`.

## Lifecycle

- **Add a key:** run `pamu2fcfg -n` with the key in, append to the mapping line
  in the manifest, run `bin/apply`. Make an `ed25519-sk` handle on the client
  and add its line to `authorized_keys`.
- **Retire a lost key:** remove its mapping entry and its `authorized_keys`
  line, run `bin/apply`.
- **Handle files** stay on each client and never enter this repo.

## Edge Cases

- **One key lost:** a backup key, then retire the lost one.
- **pam_u2f broken:** every key fails at once across sudo, ttys and both locks.
  The way back is a live usb, undoing the pam files from there.
- **Key plugged in after the lock starts:** seen on the enter press.
- **Password right, touch missed at the boot lock:** the password prompt comes
  back and the keyring stays locked.
- **sudo over ssh:** the key is on the client, so it fails unless a key sits in
  the tower. Accepted.
- **A script starts sudo:** touch-only sudo needs no tty, so it can wait on a
  blink. Never touch a blink I didn't start. A pin was not taken.
- **A pam service file goes missing:** hyprlock falls back to the `su` service,
  which takes the same touch. The manifest still lands before the dotfiles.
- **Root at a tty:** root has no mapping, so a root login fails even with the
  right password.
- **hyprpolkitagent shows no cue:** the key's blink is the cue. If it can't
  complete a touch, the rollout stops at that step.
- **Package upgrade replaces a pam file:** pacman leaves a `.pacnew`, and
  `bin/drift` reports any difference.

## Observability

N/A: nothing new. `bin/drift` covers the manifest files, and pam logs go to the
journal.

## Scope & Non-Goals

**in scope:**
- rocinante's two locks, ttys, sudo, polkit, ssh in, and the vault's unlock.

**out of scope:**
- sector7 and any other host.
- outbound ssh from rocinante to github or sector7.
- work keys, which stay work keys.
- a pin on the keys, resident keys.
- the vault account's login or two-step settings.

## Design Decisions Summary

| decision | options considered | chosen | rationale |
|---|---|---|---|
| lock mode | touch, password + touch, split | split: boot both, idle touch | the keyring needs the password once a boot, later unlocks should be fast |
| no key on a touch prompt | password fallback, none | none | a fallback makes the password alone enough |
| ttys | password only, password + touch | password + touch | no password-only side door, spare keys are the way back |
| key's home | keychain, left in the tower | keychain | a key left in the tower proves nothing |
| mapping file | `~/.config/Yubico/u2f_keys`, `/etc/u2f_mappings` | `/etc/u2f_mappings` | a file i own lets any program of mine add a key |
| idle lock wait | automatic retry, `interactive` | `interactive` | hyprlock only pauses on a pam prompt, so no prompt means a busy retry |
| polkit and su | password, touch | touch | the key is the only way in, so root costs the same on every path |
| vault | as is, boot + touch, never lock | boot password, then touch | linux needs the master password after every app start |
| ssh key type | handle file, resident | handle file | a login needs the key and the file |
| order against sudo's password | fold together, password first | password first | it shouldn't wait on a shipment |

## Requirements

- **R1 Packages.** `pam-u2f` and `yubikey-manager` are in the manifest, each with its reason.
- **R2 Enrollment.** three personal keys are enrolled in root owned `/etc/u2f_mappings`, with `origin` and `appid` pinned and OTP off.
- **R3 Boot lock and ttys.** the boot lock and ttys 2-6 need password + touch, and the keyring unlocks only after both.
- **R4 Idle lock.** the idle lock needs a touch, takes no password, and has its own pam service that doesn't include `login`.
- **R5 Boot config.** the boot lock runs from its own config, which sources `hyprlock.conf` and changes only the pam service.
- **R6 Cue and wait.** the locks show a touch cue, and an idle lock with no key waits for enter without retrying.
- **R7 sudo.** sudo needs a touch, with no password fallback.
- **R8 polkit and su.** pkexec, run0 and su need a touch, with no password fallback, and root has no mapping.
- **R9 ssh.** `authorized_keys` holds one `ed25519-sk` key per yubikey, and the old key leaves only after they are proven from a second host.
- **R10 Vault.** the vault takes the master password once per boot, locks after 30 idle minutes, and unlocks later with a touch.
- **R11 Scripts.** a script can't reach root without a touch, including right after a touch in the same pane.
- **R12 Proof.** each pam change lands alone and is proven with a root shell open.
- **R13 Book.** the book's build, operate and record pages cover enrollment, retiring a key and the way back.
