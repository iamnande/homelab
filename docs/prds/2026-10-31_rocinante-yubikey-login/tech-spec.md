# Tech Spec: rocinante yubikey login

## Overview + Design Principles

Add `pam_u2f` to every pam stack that lets someone into rocinante or up to root,
add `ed25519-sk` keys to ssh, and split hyprlock into a boot lock and an idle
lock. The vault's later unlocks follow polkit, so they take the touch with no
vault-side code.

- The key is required on every path. No `sufficient`, no `nouserok`, no fallback.
- One change, one commit, one `bin/apply`, one proof. A root shell stays open.
- The manifest lands before anything that depends on it.
- Reuse the pam stacks that exist. Add lines, don't restructure.
- Nothing enrolls before the personal keys are in hand.

## Data Model

`/etc/u2f_mappings`, in the manifest, mode 644, root owned. hyprlock runs as me
and has to read it. pam_u2f accepts a file owned by root or the user.

```
iamnande:<credential>,<key>,es256,+presence:<credential>,<key>,es256,+presence:<credential>,<key>,es256,+presence
```

A credential id and public key are as public as an `authorized_keys` line. A
line for root is never added.

## Interfaces

The shared argument set, called `U2F` below. Brackets keep the spaces in one
pam argument.

```
pam_u2f.so authfile=/etc/u2f_mappings origin=pam://rocinante appid=pam://rocinante cue [cue_prompt=Place your finger on the key]
```

| service | file | auth lines |
|---|---|---|
| `login` | manifest, existing | `system-local-login`, then `auth requisite U2F`, then `pam_gnome_keyring.so` |
| `hyprlock` | package, unchanged | includes `login` |
| `hyprlock-touch` | manifest, new | `auth required U2F interactive` |
| `sudo` | manifest, new | `auth required U2F` replaces the `system-auth` auth line |
| `polkit-1` | manifest, new, overrides `/usr/lib/pam.d` | `auth required U2F` replaces the `system-auth` auth line |
| `su` | manifest, new | `pam_rootok.so` stays, `auth required U2F` replaces `pam_unix.so` |

`su-l` includes `su`. Each new file keeps the package's account, session and
password lines as they are.

hyprlock:

| file | change |
|---|---|
| `hyprlock.conf` | `pam:module = hyprlock-touch`, `placeholder_text = $PAMPROMPT` |
| `hyprlock-boot.conf` | new: sources `hyprlock.conf`, sets `pam:module = hyprlock` |
| `hyprland.lua` | `hyprlock --config ~/.config/hypr/hyprlock-boot.conf --grace 0` |

## Validation

- `bin/drift` exits 0 after each apply, and reports any `.pacnew` on these files.
- `/etc/u2f_mappings` has three entries before any stack that reads it lands.
- `grep -r nouserok` and `grep sufficient.*u2f` over the manifest's `pam.d` are empty.
- `/etc/u2f_mappings` has no line for root.

## Core

**Why `interactive` on the idle lock.** hyprlock's auth thread retries forever
and only blocks on a pam prompt. A stack with no prompt fails at once when no
key is present, so it spins. `interactive` makes pam_u2f prompt first, which
holds the loop until enter. The boot lock has the password prompt, so it needs
no `interactive`.

**Why the cue text.** hyprlock drops pam's info messages unless they contain
"Place your finger". Using that text puts the cue in `$PAMPROMPT`.

**Why `requisite` in `login`.** A missed touch stops the stack before
`pam_gnome_keyring.so`, so the keyring opens only after both factors.

**The vault.** The app's system auth is `com.bitwarden.Bitwarden.unlock`, which
is `auth_self` in polkit, so it runs `polkit-1`. Its timeout goes to 30 minutes
by hand. Biometric unlock is already on.

**Key setup, once per key.** `ykman config usb -d OTP`, then
`pamu2fcfg -n -o pam://rocinante -i pam://rocinante`, the first key without `-n`.
On each client: `ssh-keygen -t ed25519-sk -O application=ssh:rocinante -f ~/.ssh/rocinante_sk_<name>`.

## Query Layer

N/A: no queries.

## API Layer

N/A: no handlers. `sshd` is unchanged, since a touch is already its default for
sk keys.

## Files Changed

| file | change |
|---|---|
| `hosts/rocinante/pkg/10-base.txt` | `pam-u2f`, `yubikey-manager` |
| `hosts/rocinante/root/etc/u2f_mappings` | new |
| `hosts/rocinante/root/etc/pam.d/login` | the touch line |
| `hosts/rocinante/root/etc/pam.d/hyprlock-touch` | new |
| `hosts/rocinante/root/etc/pam.d/sudo` | new |
| `hosts/rocinante/root/etc/pam.d/polkit-1` | new |
| `hosts/rocinante/root/etc/pam.d/su` | new |
| `hosts/rocinante/home/.ssh/authorized_keys` | sk keys in, then the old key out |
| `docs/hosts/rocinante/build.md`, `operate.md`, `record.md` | enrollment, retiring a key, the way back, rows |
| dotfiles `src/hypr/.config/hypr/hyprlock.conf` | service and prompt |
| dotfiles `src/hypr/.config/hypr/hyprlock-boot.conf` | new |
| dotfiles `src/hypr/.config/hypr/hyprland.lua` | the boot line and its comment |

## Services & Ordering

No PRs on this stack. Each step lands on `main`, and stow links from the main
dotfiles clone, so the hypr changes take effect there.

| order | repo / service | branch | base | contents |
|---|---|---|---|---|
| 1 | homelab | `nick/rocinante-yubikey-login` | `main` | packages, mappings, `login`, `hyprlock-touch` |
| 2 | dotfiles | `nick/rocinante-yubikey-login` | `main` | both hyprlock configs, `hyprland.lua` |
| 3 | homelab | `nick/rocinante-yubikey-login` | `main` | `sudo`, `polkit-1`, `su`, ssh keys, the book |

## Integration Tests

Manual, on the box, by me. Agents run `bin/drift` only.

| # | test | expect |
|---|---|---|
| 1 | tty2: right password, no key | refused |
| 2 | tty2: wrong password, key touched | refused |
| 3 | tty2: password + touch | login |
| 4 | tty2: root, right password + touch | refused |
| 5 | boot: password + touch | desktop, keyring open |
| 6 | boot: password, no touch | still locked, keyring closed |
| 7 | idle lock, no key, wait a minute | no retries in the journal, no cpu spin |
| 8 | idle lock: plug in, enter, touch | unlocks |
| 9 | idle lock: password typed, no key | refused |
| 10 | `hyprlock-boot.conf` | `pam:module` wins over the sourced value |
| 11 | sudo with no key, sudo with a touch | refused, then root |
| 12 | `sudo -n true` from a script, right after a touch in the same pane | refused |
| 13 | a script's sudo with no tty, no touch | times out, refused |
| 14 | pkexec, run0, su: no key, then a touch | refused, then allowed |
| 15 | vault locked: touch in the app's prompt | unlocks |
| 16 | vault locked: `ssh -T git@github.com` | fails until a touch |
| 17 | each of three keys on each prompt | all work |
| 18 | ssh from the phone with a key tapped + handle, then with no tap | login, then refused |
| 19 | old key removed: ssh with it | refused |

## Rollout Plan

Gates: all three keys in hand, and sudo already reaches pam (`sudo -k`, then
`sudo true` prompts).

Before step 3: a btrfs snapshot, a `sudo -i` shell left open on a spare tty, and
a live usb that boots.

| step | change | proof | stop if |
|---|---|---|---|
| 1 | packages, `bin/mkrepo` | `bin/drift` | |
| 2 | OTP off, three keys in the mapping | file has three entries, no root | a key won't enroll |
| 3 | `login` | tests 1-6 | any test fails |
| 4 | `hyprlock-touch`, then the dotfiles | tests 7-10 | the idle lock spins or can't be unlocked |
| 5 | `sudo` | tests 11-13 | |
| 6 | `polkit-1`, `su` | tests 14-15 | hyprpolkitagent can't finish a touch |
| 7 | vault timeout | tests 15-16 | |
| 8 | sk keys added | test 18 | |
| 9 | old key removed | test 19 | |
| 10 | book and record | `mdbook build` | |

Rollback, by reach:

- **One stack bad, root shell open:** `git revert`, then restore the file from
  the root shell.
- **Everything refused:** live usb, mount the root subvolume, restore that
  file from the snapshot, or remove the `pam_u2f` lines.
- **Ssh locked out:** the local console, per `operate.md`.

## Resolved Questions

| question | resolution |
|---|---|
| can the two locks use different pam files | yes, `--config` plus `auth:pam:module`; test 10 proves the override |
| does hyprlock need enter before touch | it starts pam at once; the idle stack adds enter on purpose |
| does a late key need a failed attempt | no, the enter press retries |
| who sees `/etc/u2f_mappings` | everyone can read it, only root can write it |
| what catches a missing pam service | hyprlock falls back to `su`, which takes the same touch |
| ttys 2-6 | password + touch |
| which clients get a handle | the phone, by nfc tap. work machines get none |

## Requirements Coverage

| requirement | covered by |
|---|---|
| R1: | § Files Changed, § Rollout Plan step 1 |
| R2: | § Data Model, § Core, § Rollout Plan step 2 |
| R3: | § Interfaces `login`, tests 1-6 |
| R4: | § Interfaces `hyprlock-touch`, tests 7-9 |
| R5: | § Interfaces hyprlock, test 10 |
| R6: | § Core, tests 7-8 |
| R7: | § Interfaces `sudo`, test 11 |
| R8: | § Interfaces `polkit-1` and `su`, tests 4 and 14 |
| R9: | § Core, tests 18-19 |
| R10: | § Core, tests 15-16 |
| R11: | tests 12-13 |
| R12: | § Rollout Plan |
| R13: | § Files Changed, § Rollout Plan step 10 |
