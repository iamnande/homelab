# Tech Spec: put outbound traffic back through proton vpn

## Overview + Design Principles

the gateway gets a wireguard client to proton us, policy routes that send
every vlan through it but work and the apple tv, and a kill switch. the book's
two vpn lines get reworded to match. the gateway work is by hand, in its ui,
by nick: agents can't reach it, so every check is a screenshot or a paste-back.
the only code change is `docs/network.md`.

1. **private by default.** a source not named as an exception goes out the
   tunnel. a new device inherits that without anyone touching the gateway.
2. **fail closed.** a down tunnel is an outage, never a leak.
3. **exceptions by device, not by network.** one ip, pinned by a reservation,
   not all of vlan 40.
4. **old config stays until the new one is proven.** the openvpn clients are
   deleted last.
5. **the book matches the gateway.** it lands after verification, so it never
   describes something that isn't running.

## Data Model

gateway state after the change:

```
vpn clients
  proton-us-wg       wireguard   proton us     enabled
  (Proton VPN - Canada, Proton VPN - US: deleted after verification)

dhcp reservations
  apple tv           <mac>  ->  <fixed ip>     vlan 40

policy routes
  apple-tv-wan       source: <apple tv ip>                interface: wan
  all-via-proton     source: vlans 1, 20, 30, 40, 60, 70  interface: proton-us-wg  kill switch: on

vlan 50 (work)       no policy route, default route out the wan
```

the proton config file holds the tunnel's private key. it goes in the vault,
next to the proton account. never in this repo, never in a screenshot.

## Interfaces

N/A: no rpc, cli or events. the interfaces are the gateway's ui and the proton
account's wireguard config generator.

## Validation

- **the config file.** generated for one server in the us, protocol
  wireguard, netshield off, moderate nat off. one config per device in the
  proton account, labeled for the gateway.
- **the reservation.** the apple tv's ip is outside the dhcp pool, or the
  gateway pins it inside it. either way it can't be handed to another device.
- **the routes.** the apple tv route has to win over the vlan 40 match in the
  vpn route. checked with an exit-ip test from the apple tv, not assumed.
- **no v6 bypass.** the wan's ipv6 state and each vpn-routed vlan's v6 setting
  are checked before the vpn route goes on.

## Core

nick does each step on the gateway and pastes back or screenshots the result.
the order keeps the network usable the whole way: nothing goes through the
tunnel until it's proven, and the kill switch goes on last.

1. **baseline.** from a home device (vlan 20): `curl -s https://ipinfo.io`.
   note the isp exit ip. screenshot the gateway's wan ipv6 setting and each
   vlan's ipv6 setting.
2. **config.** in the proton account, make a wireguard config for a us
   server, netshield off, moderate nat off. save the file to the vault.
3. **tunnel.** gateway → vpn → vpn client → create, wireguard, upload the
   file. name it `proton-us-wg`. screenshot the status: connected, recent
   handshake. (R1)
4. **reservation.** pin the apple tv's mac to a fixed ip on vlan 40. reboot
   the apple tv, confirm it took the ip. (R4)
5. **apple tv route.** policy route `apple-tv-wan`: source the apple tv's ip,
   interface wan. create it before the vpn route, so it's there when vlan 40
   flips. (R4)
6. **vpn route, kill switch off.** policy route `all-via-proton`: source vlans
   1, 20, 30, 40, 60, 70, interface `proton-us-wg`. leave the kill switch off
   for now, so a bad tunnel doesn't strand the session.
7. **check routing.** run the exit-ip checks from Integration Tests, 1 to 4.
   if the apple tv shows a proton ip, the vpn route is winning: reorder the
   routes, and if the gateway can't order them, swap the vlan 40 source for
   ip ranges around the apple tv's ip (e.g. `.2-.199` and `.201-.254` with the
   apple tv on `.200`). (R2, R3, R4)
8. **kill switch.** turn it on in `all-via-proton`. run test 5. (R5)
9. **leaks.** tests 6 and 7. if v6 leaks, turn ipv6 off on the vpn-routed
   vlans. (R6)
10. **soak.** a day of normal use: streaming, video calls, the switch 2.
11. **clean up.** delete `Proton VPN - Canada` and `Proton VPN - US`. (R6)
12. **the book.** reword `network.md:17` and `network.md:116`. (R7)

book text, `network.md:17`:

```
* 🕵️‍♂️ **vpn for outbound traffic:** traffic leaving the lab routes through
proton vpn to preserve privacy, with exceptions by device or network only.
```

`network.md:116`:

```
* outbound traffic goes through proton us over wireguard, except work (vlan 50)
and the apple tv. if the tunnel drops, that traffic stops instead of going out
the wan.
```

## Query Layer

N/A: no data store.

## API Layer

N/A: no handlers or entry points.

## Files Changed

| file | change |
|---|---|
| `docs/network.md` | reword lines 17 and 116 to the text in Core |
| `docs/prds/2026-11-06_restore-proton-vpn-egress/prd.md` | this plan's PRD |
| `docs/prds/2026-11-06_restore-proton-vpn-egress/tech-spec.md` | this spec |

## Services & Ordering

the gateway goes first and has no PR. the book PR waits for the soak, so it
never merges ahead of what's running.

| order | repo / service | branch | base | contents |
|---|---|---|---|---|
| 1 | gateway (by hand) | n/a | n/a | Core steps 1 to 11 |
| 2 | homelab | `nick/restore-proton-vpn-egress` | `main` | the plan docs and the `network.md` reword |

## Integration Tests

manual. each is a paste-back or a screenshot from nick.

| # | from | check | pass |
|---|---|---|---|
| 1 | home device, vlan 20 | `curl -s https://ipinfo.io` | proton us exit ip |
| 2 | work laptop, vlan 50, its own vpn off | same | isp exit ip |
| 3 | apple tv | play the service that blocked it | plays, no vpn or proxy error |
| 4 | an iot device that isn't the apple tv, or a guest device | exit ip, if it can show one | proton us exit ip |
| 5 | home device, tunnel disabled | `curl -s -m 10 https://ipinfo.io` | times out. work and the apple tv still work. re-enable after |
| 6 | home device | `curl -s -6 -m 10 https://ifconfig.co` | fails, or shows a proton v6 address. never the isp's |
| 7 | home device | a dns leak test (e.g. dnsleaktest.com, extended) | controld resolvers only |
| 8 | switch 2 | an online match | plays. note latency and nat type |

## Rollout Plan

| stage | gate | verify | rollback |
|---|---|---|---|
| tunnel (steps 2-3) | none | connected, recent handshake | delete the client. nothing routes through it yet |
| apple tv (4-5) | tunnel up | the apple tv took its ip | delete the route and reservation |
| vpn route (6-7) | apple tv route in place | tests 1 to 4 | disable `all-via-proton`. everything goes out the wan, as today |
| kill switch (8) | tests 1 to 4 pass | test 5 | turn the kill switch off |
| leaks (9) | kill switch on | tests 6 and 7 | turn v6 off on the vpn-routed vlans |
| soak (10) | all above pass | test 8, a day of normal use | disable `all-via-proton` |
| clean up (11) | soak passes | the old clients are gone | n/a: the wireguard client is proven |
| book (12) | clean up done | the PR renders the new lines | revert the PR |

the fast rollback is one toggle: disable `all-via-proton`. the network is back
to today's state in seconds, and the tunnel and the apple tv route can stay.

## Resolved Questions

| question | resolution |
|---|---|
| why not a different server or region for streaming | it was an outright block on the exit ip. any proton exit has the same problem |
| does the gateway's own traffic need the tunnel | no. it talks to ubiquiti and controld over doh, and the isp learns nothing from that it doesn't already know |
| does the apple tv leak anything | its destinations, to the isp. accepted. dns stays hidden via controld, and vlan 40 keeps it away from everything else |
| how the apple tv beats the vlan 40 match | route order, checked in step 7. fallback: ip ranges around its ip |
| guests on vlan 60 | through the tunnel. their streaming can hit the same block. accepted: guests don't get streaming |
| the switch 2 | on home (vlan 20), through the tunnel. test 8 decides. if online play suffers, a by-device exception like the apple tv |
| when the openvpn clients go | after the soak, not before |

## Requirements Coverage

| requirement | covered by |
|---|---|
| R1: tunnel | § Core step 3, § Rollout Plan (tunnel) |
| R2: vpn by default | § Core steps 6-7, § Integration Tests 1 and 4 |
| R3: work skips the vpn | § Data Model (vlan 50), § Integration Tests 2 |
| R4: apple tv skips the vpn | § Core steps 4, 5 and 7, § Integration Tests 3 |
| R5: fails closed | § Core step 8, § Integration Tests 5 |
| R6: no leaks, no clutter | § Core steps 9 and 11, § Integration Tests 6 and 7 |
| R7: the book | § Core step 12, § Files Changed, § Services & Ordering 2 |
