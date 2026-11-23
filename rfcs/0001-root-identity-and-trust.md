# rfc 0001: root identity and trust

|           |            |
| --------- | ---------- |
| status    | aligned    |
| updates   | none       |
| obsoletes | none       |
| date      | 2026-11-22 |
| author    | @iamnande  |

## abstract

each MHQ person's identity is rooted in three or more hardware security keys.
this rfc establishes which systems trust those keys directly, how every other
credential sits behind the vault, and how a key gets lost, replaced or added
without losing access.

## terminology

the keywords `MUST`, `MUST NOT`, `SHOULD`, `SHOULD NOT` and `MAY` are to be read
as described in [bcp 14](https://www.rfc-editor.org/info/bcp14) when, and only
when, they appear in capitals.

_MHQ person_ someone with an identity in MHQ, issued root keys.

_MHQ device_ an MHQ managed node.

_root key_ a hardware security key issued to an MHQ person as the root
credential for their identity.

_credential_ a distinct secret an MHQ person uses to prove who they are to a
relying party.

_relying party_ anything that verifies a credential, whether it lives on a root
key or in the vault. often referred to as - RP.

_the vault_ bitwarden, a zero-knowledge secret store holding every credential
that isn't on a root key. it has two parts: the MHQ organization, shared across
MHQ people, and each MHQ person's personal vault.

_touch_ user presence on a root key, plus its pin.

## 1. motivation

passwords are the weak link in the digital foundation for MHQ.

passkey migrations make it easy to fix one relying party at a time, but that's
backwards if the foundation is still a pile of software keys and passwords.

instead we set a secure root digital identity once, then hang everything off it.

other factors:

- homelab migrating from arch to nixos yields a new luks and uefi deployment,
  which leaves an opportune time to establish root-of-trust in hardware.

## 2. specification

### 2.1 root keys

- each MHQ person `MUST` be issued at least `3` root keys, one `MUST` be
  `USB-C`. one root key `MUST` serve as primary for day-to-day operations, held
  on person or stored in a nearby safe. one root key `MUST` serve as a backup
  for primary root key recovery, stored in a nearby safe but `MUST NOT` be
  stored in the same safe as the primary. one root key `MUST` be stored in an
  offsite safe, with a trusted MHQ person. fallback passphrases and FIDO2 pins
  `MUST` have a hard-copy in each safe in a fire-proof container.
- root key names `MUST` be unique across MHQ, and `MUST NOT` be reused.
- root key names `MUST` be expanse characters. root keys `MUST NOT` use station
  or ship names, those are held for MHQ devices.
- credential labels `MUST` be applied everywhere one can be carried, and `MUST`
  be in the form `mhq-<key-name>-<purpose>` (e.g. `mhq-naomi-ssh`).
- each root key `MUST` have a FIDO2 pin set.
- each root key `MUST` expose only FIDO2 + U2F over USB, and `MUST NOT` have NFC
  enabled.

### 2.2 direct trust

- only these `MAY` be relying parties (RP) for a root key: disk encryption on
  each MHQ device, MHQ ssh, and the MHQ vault.
- every root key of an MHQ person `MUST` be enrolled with each of the allowed
  root key RPs.
- any one root key `MUST` be enough, on its own, for each of trusted root RPs.
- every use of a root key `MUST` require its pin, and `MUST NOT` rely solely on
  presence via touch.

### 2.3 the vault

- every other credential `MUST` be stored in the MHQ vault.
- shared or managed credentials `MUST` be stored in the MHQ organization, never
  in a personal vault.
- each MHQ person `MUST` have their own folder in the MHQ organization.
- until an MHQ person manages their own vault, their credentials `SHOULD` live
  in their organization folder. after that, they `MAY` move to their personal
  vault.
- anyone with access to the vault `MUST` be an MHQ person, and `MUST` use a root
  key to get in.
- while an MHQ person's credentials are managed by someone else, the managers
  `MUST` use their own root keys.
- the MHQ organization `MUST` have at least two owners, each an MHQ person, and
  each owner `MUST` have emergency access set up.
- an MHQ person who isn't an owner `MUST` see only the folders they're given.
- a passkey `MUST` be used wherever a relying party offers one.
- passkey-only login `MUST` be turned on wherever it's offered.
- where a password can be removed, it `MUST` be removed.
- where a password stays, the strongest second factor offered `MUST` be used:
  otp, then email, then anything else.

### 2.4 ssh and commit signing

- ssh auth and commit signing `MUST` use resident `ed25519-sk` keys on root
  keys, one per root key.
- software ssh keys `MUST NOT` be used, for auth or signing.

### 2.5 two touches

- reaching any credential `MUST` take two touches - one for unlocking the
  device, then another when: connecting to an MHQ device via ssh, commit
  signing, or accessing the MHQ vault.

## 3. security considerations

- a compromised MHQ device can not push or sign as an MHQ person silently, each
  push and commit signature operation requires a touch.
- api tokens (e.g. `gh`) in integrations where stronger authentication methods
  are nota available are the one kind of credential that `MAY` work with no
  touch. they `MUST` be least-privileged.
- the offsite root key `SHOULD` be close by. it covers theft and a house fire,
  not a regional disaster.
- nfc is off, so a key can't be read or used through a pocket or a bag.
- organization owners can read every folder, each person's included. private
  credentials belong in a personal vault once a person manages their own.

## 4. operational considerations

- adding an MHQ device: enroll disk encryption with every root key, recovery key
  to paper.
- losing a root key: remove it from every relying party, retire its name, issue
  a replacement with a new name and enroll it everywhere.
- adding an MHQ person: at least three root keys, each with a new name, enrolled
  everywhere per section 2. keys the person already owns `MAY` be reused once
  they meet section 2.1.
- losing an owner: the other owner keeps the organization running, and emergency
  access reaches the lost owner's personal vault.
- recovery: the vault's recovery code and each disk encryption recovery key on
  paper, fireproof, in a safe at the primary residence and another at an offsite
  residence.

## 5. references

- [bcp 14](https://www.rfc-editor.org/info/bcp14): rfc 2119 and rfc 8174
- `systemd-cryptenroll(1)`: luks fido2 enrollment
- `ssh-keygen(1)`: `-t ed25519-sk -O resident -O verify-required`
- [ykman](https://docs.yubico.com/software/yubikey/tools/ykman/): key
  configuration
