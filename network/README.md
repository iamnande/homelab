# network

networking is the unsung hero and backbone of the lab.

---

## design decisions

* 🛡️ **segmentation first:** each network is isolated by purpose, with
default-deny between zones, to reduce blast radius and enforce least-privilege
access.

* 🌐 **split-horizon dns:** internal resolution allows private names like
`gateway.morethq.com` to resolve while public services resolve via controld
using dns-over-https (doh).

* 🕵️‍♂️ **vpn for outbound traffic:** all traffic leaving the lab routes through
proton vpn to preserve privacy.

* 🏗️ **enterprise patterns at home:** over-segmentation, strict firewalling, and
tls coverage create a safe, realistic playground.

---

## hardware

* modem: arris - surfboard sb6183
* gateway: unifi cloud gateway ultra
* switch: unifi lite 8 poe
* access points:
    * (2) unifi u6 in-wall

<details open>
    <summary>network infrastructure diagram</summary>

```mermaid
graph TD

    %% --- Core network path ---
    internet["🌐 internet"]
    modem["arris surfboard sb6183<br/>(modem)"]
    gateway["unifi cloud gateway ultra<br/>(gateway)"]
    switch["unifi lite 8 poe<br/>(switch)"]

    internet --> modem --> gateway --> switch

    %% --- downstairs ---
    subgraph downstairs
        ap_down["u6 in-wall<br/>(downstairs ap)"]
        client_d1["smart tv"]
        client_d2["game console"]
        client_d3["iot devices"]
    end

    switch --> ap_down
    ap_down -.-> client_d1
    ap_down -.-> client_d2
    ap_down -.-> client_d3

    %% --- upstairs ---
    subgraph upstairs
        ap_up["u6 in-wall<br/>(upstairs ap)"]
        client_u1["laptop / workstation"]
        client_u2["phone / tablet"]
        client_u3["iot hub"]
    end

    switch --> ap_up
    ap_up -.-> client_u1
    ap_up -.-> client_u2
    ap_up -.-> client_u3

    %% --- lab ---
    subgraph lab["lab (vlan 30)"]
        proxmox["proxmox tower<br/>(hypervisor)"]
    end

    switch --> proxmox

    %% --- Legend ---
    classDef wired stroke-width:2px,stroke:#333;
    classDef wireless stroke-dasharray:5 5,stroke:#999;
```
</details>

---

## segmentation

the network is segmented into 6 trust zones, with a default of deny. there are
currently 7 vlans, each with their own subnet.

zones:

| zone       | associated vlans      | description                            |
| ---------- | --------------------- | -------------------------------------- |
| internal   | 1, 20, 30, 40, 50, 70 | trusted internal networks              |
| external   | wan 1, wan 2, vpn-xx  | internet uplinks and vpn clients       |
| gateway    | gateway               | gateway; enforces firewall rules       |
| vpn        | tbd                   | vpn servers; encrypted inbound traffic |
| hotspot    | 60                    | guest wi-fi; internet-only access      |
| dmz        | tbd                   | future public zone; extreme isolation  |

vlans:

| vlan | purpose    | subnet         | notes                                  |
| ---- | ---------- | -------------- | -------------------------------------- |
| 1    | management | 172.16.0.0/24  | gateway, aps                           |
| 20   | home       | 172.16.20.0/24 | personal devices                       |
| 30   | lab        | 172.16.30.0/24 | experimental services, containers      |
| 40   | iot        | 172.16.40.0/24 | smart devices, internet-only, isolated |
| 50   | work       | 172.16.50.0/24 | work device, internet-only, isolated   |
| 60   | guest      | 172.16.60.0/24 | guest wifi, internet-only, isolated    |
| 70   | service    | 172.16.70.0/24 | internal production apps, media, sync  |

* all outbound traffic goes through proton vpn via udp.
* all dns queries go through controld via doh.
* vlans 40 (iot), 50 (work), and 60 (guest) are strictly internet-only,
entirely isolated from internal resources.
* vlans 1 (mgmt), 20 (home), 30 (lab), and 70 (service) have internal routing
as needed.

<details open>
    <summary>network segmentation diagram</summary>

```mermaid
graph TD

    %% --- core gateway ---
    gateway["unifi cloud gateway ultra<br/>(gateway zone)"]

    %% --- internal zone ---
    subgraph internal["internal zone"]
        vlan_1["vlan 1: management<br/>172.16.0.0/24"]
        vlan_20["vlan 20: home<br/>172.16.20.0/24"]
        vlan_30["vlan 30: lab<br/>172.16.30.0/24"]
        vlan_40["vlan 40: iot<br/>172.16.40.0/24"]
        vlan_50["vlan 50: work<br/>172.16.50.0/24"]
        vlan_70["vlan 70: service<br/>172.16.70.0/24"]
    end

    %% --- hotspot zone ---
    subgraph hotspot["hotspot zone"]
        vlan_60["vlan 60: guest<br/>172.16.60.0/24"]
    end

    %% --- vpn zone ---
    subgraph vpn["vpn zone"]
        vlan_80["vlan 80: vpn (planned)"]
    end

    %% --- external zone ---
    subgraph external["external zone"]
        wan1["wan 1"]
        wan2["wan 2"]
        vpn_us["vpn-us"]
        vpn_xx["vpn-xx"]
    end

    %% --- dmz zone ---
    subgraph dmz["dmz zone (planned)"]
        dmz_net["dmz network"]
    end

    %% --- gateway connections ---
    gateway --> internal
    gateway --> hotspot
    gateway --> vpn
    gateway --> external
    gateway --> dmz

    %% --- internet / dns ---
    internet["🌐 internet"]
    doh["doh: controld<br/>all vlans"]

    vlan_1 --> doh
    vlan_20 --> doh
    vlan_30 --> doh
    vlan_40 --> doh
    vlan_50 --> doh
    vlan_60 --> doh
    vlan_70 --> doh
    vlan_80 --> doh
    doh --> internet

%% --- Isolation Notes ---
    classDef isolated fill:#AA2525,stroke:#f00,stroke-width:2px;
    class vlan_40,vlan_50,vlan_60 isolated
```

</details>

---

## proxmox trunk port

the proxmox tower connects to the switch via a trunk port on **port 8** of the
unifi lite 8 poe with the following vlan policy:

* **native (untagged): vlan 30 (lab)** — proxmox host management traffic rides
  untagged. the switch enforces vlan 30 implicitly. no vlan sub-interface needed
  on the host.

* **tagged: vlan 70 (service)** — vms destined for the service network carry an
  explicit vlan 70 tag set on the proxmox network device.

* **vlan 30 vms (e.g. devbox-nick)** — also ride native (no explicit tag). this
  is intentional: any accidental untagged traffic lands on vlan 30 (lab), not
  vlan 70 (service) or any other sensitive segment. the switch is the boundary,
  not individual vm configs.

**tradeoff accepted:** vlan 30 vms can't carry an explicit tag — they're
indistinguishable from host management traffic at the switch level. acceptable
for a lab-tier threat model. revisit if vlan 30 ever holds sensitive workloads.
