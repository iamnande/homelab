# PRD: put outbound traffic back through proton vpn

terms used throughout: **gateway** (the unifi cloud gateway ultra), **book**
(the mdbook in this repo), **tunnel** (the gateway's wireguard client to proton
us), **policy route** (a gateway rule that sends a source out a given
interface), **kill switch** (the policy route option that drops traffic when
the tunnel is down), **exception** (a source that goes straight out the wan).

## Problem

the book says all outbound traffic goes through proton vpn (`network.md:17`,
`network.md:116`). it doesn't.

1. **the vpn is off.** found on 11-03: the gateway has two proton clients,
   canada and us, both openvpn, both disabled. every vlan goes straight out the
   wan, so the isp sees every destination from every device.
2. **it was turned off for a reason.** a streaming service blocked playback
   outright with a vpn or proxy error. it's the proton exit ip, not dns or
   region: vpn exit ranges get blocked no matter the resolver.
3. **the us client is half-built.** it's openvpn on port 51820, wireguard's
   default. it was never checked, and nobody knows if it ever connected.
4. **the book is wrong.** it describes a vpn that isn't running and has no
   word on exceptions.

affected: everyone on the network. the privacy default is gone until this
lands.

## Solution

1. a clean wireguard client on the gateway to proton us. the old openvpn
   clients go once the tunnel is verified. (R1, R6)
2. policy routes send every vlan out the tunnel, except work (vlan 50) and the
   apple tv. (R2, R3, R4)
3. the apple tv gets a dhcp reservation so its ip never moves, and that one
   ip goes straight out the wan. (R4)
4. the kill switch is on: tunnel down means vpn-routed traffic stops, it
   doesn't leak out the wan. (R5)
5. the book says what the gateway does: proton us over wireguard, except work
   and the apple tv, fails closed. (R7)

## Configuration

all on the gateway, by hand. nothing here is in code.

| setting | value |
|---|---|
| vpn client | wireguard, proton us, config file generated in the proton account |
| proton options | netshield off (controld does dns), moderate nat off |
| tunnel key | the proton wireguard config, stored in the vault, never in a repo |
| dhcp reservation | apple tv mac → a fixed ip on vlan 40 |
| policy route: vpn | source: vlans 1, 20, 30, 40, 60, 70. interface: tunnel. kill switch on |
| policy route: apple tv | source: the apple tv's reserved ip. interface: wan |
| work, vlan 50 | no policy route. default route, straight out the wan |

## States

| state | vpn-routed vlans | work | apple tv |
|---|---|---|---|
| tunnel up | out the tunnel, proton us exit ip | wan | wan |
| tunnel down | dropped (kill switch) | wan | wan |
| policy route disabled (rollback) | wan | wan | wan |

## Behavior

| | before | after |
|---|---|---|
| home, lab, service, mgmt, guest | wan, isp exit ip | tunnel, proton us exit ip |
| iot (vlan 40), not the apple tv | wan | tunnel |
| apple tv | wan | wan, streaming works |
| work (vlan 50) | wan | wan, unchanged |
| dns | controld over doh | controld over doh, unchanged |
| tunnel drops | n/a | vpn-routed traffic stops until it's back |

isolation is unchanged. vlan 40 stays internet-only, so the apple tv can't
reach or see anything else on the network. the tv itself stays offline.

## API

N/A: no software surface. the change is gateway settings and one book page.

## Lifecycle

- the tunnel is created once from proton's config file. a key rotation means a
  new config file from the proton account and a re-upload.
- the old canada and us openvpn clients are deleted after verification, not
  before, so they stay a fallback until the wireguard client is proven.
- a replacement apple tv gets a new mac: move the reservation to it, or it
  falls into the vpn route and streaming breaks again.
- the gateway's own traffic (updates, controld doh) doesn't go through policy
  routes. that's fine: the isp sees the gateway talk to ubiquiti and controld,
  not what's resolved.

## Edge Cases

- **a new device on vlan 40.** goes out the tunnel. only the apple tv's ip is
  excepted, so nothing new leaks to the wan by default.
- **the apple tv's ip changes.** can't, with the reservation. if the
  reservation is lost, the apple tv falls into the vpn route and streaming
  breaks. fails private, not open.
- **policy route order.** the apple tv sits inside vlan 40, which also goes to
  the tunnel. the apple tv route has to win. verified on the gateway before the
  vpn route goes on (spec, Core).
- **ipv6.** if the wan has ipv6 and a vlan hands out v6 addresses, v6 traffic
  could skip a v4 tunnel. checked during verification, and v6 is off on
  vpn-routed vlans if it leaks.
- **another service blocks the proton exit ip.** handled per device, the same
  way as the apple tv, if it ever comes up. not handled now.
- **guests on vlan 60.** go out the tunnel, so their streaming can hit the
  same block. accepted: guests get the privacy default.
- **game console.** if it's on a vpn-routed vlan, it goes out the tunnel, with
  added latency and maybe strict nat. checked during verification.
- **sector7's tunnel.** not handled, out of scope.

## Observability

- the gateway's vpn client page shows tunnel status and handshake.
- an exit-ip check (`curl -s https://ipinfo.io`) from each class of device is
  the verification, not a monitor.
- no alerting. a dropped tunnel shows up as no internet on the vpn-routed
  vlans, which is the kill switch doing its job.

## Scope & Non-Goals

**in scope:**
- a wireguard client to proton us on the gateway
- policy routes for every vlan but work, the apple tv exception, the kill
  switch
- a dhcp reservation for the apple tv
- deleting the old openvpn clients after verification
- rewording `network.md:17` and `network.md:116`

**out of scope:**
- sector7's tunnel
- the planned vpn zone (vlan 80) for inbound
- a second exit (canada) or failover between exits
- automating gateway config
- alerting on tunnel state

## Design Decisions Summary

| decision | options considered | chosen | rationale |
|---|---|---|---|
| streaming fix | a different server; a different region; a route exception | a route exception | it was an outright block on the exit ip, not slow or wrong region |
| what goes through the vpn | everything; everything but streaming | everything but streaming | keeps the privacy default without breaking streaming |
| tunnel down | fail open to the wan; fail closed | fail closed | a silent leak is worse than a visible outage |
| exit and protocol | canada or us; openvpn or wireguard | us over wireguard | faster than openvpn, and the us client's port already pointed that way |
| work, vlan 50 | through the vpn; straight out the wan | wan | the work laptop runs its own vpn, and a double tunnel or a proton exit ip can trip work security |
| streaming exception scope | all of vlan 40; by device | the apple tv, by device | the apple tv has no acr screen telemetry, and vlan 40 keeps it internet-only |
| the tv itself | on the network; offline | offline | no smart-tv acr to deal with |
| isp visibility of the apple tv | hide it; accept it | accept it | the cost of streaming working. dns stays hidden via controld |
| old openvpn clients | keep; delete now; delete after verification | delete after verification | a fallback until wireguard is proven, then no clutter |

## Requirements

- **R1 tunnel.** the gateway has a wireguard client to proton us, built from a
  fresh proton config, connected with a recent handshake.
- **R2 vpn by default.** a device on vlans 1, 20, 30, 40, 60 or 70 shows a
  proton us exit ip, not the isp's.
- **R3 work skips the vpn.** a device on vlan 50 shows the isp's exit ip.
- **R4 apple tv skips the vpn.** the apple tv has a dhcp reservation, goes out
  the wan, and the streaming service that blocked it plays.
- **R5 fails closed.** with the tunnel down, a device on a vpn-routed vlan
  can't reach the internet. work and the apple tv still can.
- **R6 no leaks, no clutter.** no ipv6 or dns leak from a vpn-routed vlan, and
  the old openvpn clients are gone.
- **R7 the book.** `network.md:17` and `network.md:116` say outbound goes
  through proton us over wireguard, except work (vlan 50) and the apple tv,
  and fails closed.
