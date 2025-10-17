# SecureNet POC – Hybrid LAN/WAN Fabric with SONiC and Dynamic Policy Router

## 1. Overview

This Proof of Concept (POC) demonstrates a **secure LAN/WAN integration** using open components:
- A **SONiC-based core switch** (`core1`)
- A **policy-based router** (`wan-node1`)
- **ZeroTier** for site-to-site overlay networking
- **WireGuard** for Secure Web Access (SWA)

The architecture is modular: the WireGuard tunnel can later be replaced by **commercial Secure Web Gateways (SWG)** such as **Zscaler Internet Access (ZIA)** or **Cloudflare Gateway** without changing the local LAN and VLAN design.

---

## 2. Design Goals

1. Demonstrate integration between:
   - Local VLAN segments
   - Virtual overlay networks (ZeroTier)
   - Secure outbound web access (WireGuard / SWG)
2. Support multiple VLANs with independent routing and policies.
3. Prepare for Zero Trust Network Access (ZTNA) and Secure Web Access service chains.

---

## 3. Topology Summary

| Node         | Role                          | Notes |
|---------------|-------------------------------|--------|
| `core1`       | SONiC switch (Layer 2/3)      | VLANs and SVIs, trunk uplink to WAN router |
| `wan-node1`   | Policy-based router           | Dual tunnels (ZeroTier + WireGuard), VLAN uplinks |
| `linux1`      | Client in LAN VLAN 10         | Uses SONiC SVI as default gateway |
| `iot1`, `iot2`| IoT clients in VLAN 30        | Use SONiC SVI as default gateway |

---

## 4. Logical Network Diagram

### 4.1 High-Level View

```
                   +-----------------------------------+
                   |        WAN-Node1 (Router)         |
                   |-----------------------------------|
                   | eth1.10 → 192.168.10.1/24 (LAN)   |
                   | eth1.30 → 192.168.30.1/24 (IoT)   |
                   | eth1.1001 → 192.168.101.1/24 (SWA)|
                   |                                   |
                   | wg0  (WireGuard) → Secure Web     |
                   | zt0  (ZeroTier)   → Overlay VPN   |
                   +-------------------+---------------+
                                       |
                                       | Trunk (VLAN 10,30,1001 tagged)
                                       |
                           core1:Ethernet1 (SONiC switch)
                                       |
         --------------------------------------------------------
         |                        |                           |
     VLAN 10 (LAN)           VLAN 30 (IoT)             VLAN 30 (IoT)
         |                        |                           |
     Ethernet4 (untagged)     Ethernet7 (untagged)        Ethernet8 (untagged)
         |                        |                           |
     +--------+              +---------+                 +---------+
     | linux1 |              |  iot1   |                 |  iot2   |
     |192.168.10.11/24       |192.168.30.11/24           |192.168.30.12/24
     |GW:192.168.10.1        |GW:192.168.30.1            |GW:192.168.30.1
     +--------+              +---------+                 +---------+
```

---

### 4.2 Tunnel Connectivity

```
+-----------------------------------------------------------+
| WAN-NODE1: Dual Tunnel Architecture                       |
|-----------------------------------------------------------|
|                                                           |
|   ZeroTier (zt0) - Overlay Mesh Network                   |
|   - Used for site-to-site interconnects                   |
|   - Provides encrypted Layer 2 overlay                    |
|   - Traffic routed via VLAN 10 / IoT VLAN 30 as required  |
|                                                           |
|   WireGuard (wg0) - Secure Web Access Tunnel              |
|   - Provides internet breakout through secure endpoint     |
|   - All SWA and IoT VLAN traffic is routed through wg0     |
|   - Policy-based routing ensures isolation                 |
|                                                           |
|   Future Option: Replace wg0 with SWG (Zscaler/Cloudflare)|
|   - Minimal change required                                |
|   - Reuse same VLAN/subnet and policy structure            |
+-----------------------------------------------------------+
```

---

## 5. SONiC Configuration Concept (`core1`)

The SONiC node acts as a Layer-2/3 core switch.  
Key aspects:
- VLANs are defined and assigned to access/trunk ports.
- SVIs (Switch Virtual Interfaces) provide L3 gateways for each VLAN.
- The uplink to `wan-node1` is a trunk port.

### VLAN and Interface Mapping

| Interface | Role | VLAN(s) | Notes |
|------------|-------|---------|------|
| Ethernet1 | Trunk uplink | 10, 30, 1001 | Tagged trunk to WAN router |
| Ethernet4 | Access port | 10 | LAN endpoint |
| Ethernet7 | Access port | 30 | IoT endpoint |
| Ethernet8 | Access port | 30 | IoT endpoint |

### VLAN / SVI Configuration Example

| VLAN | Name | Subnet | SVI Interface | IP Address |
|-------|------|----------|---------------|-------------|
| 10 | LAN | 192.168.10.0/24 | Vlan10 | 192.168.10.1 |
| 30 | IoT | 192.168.30.0/24 | Vlan30 | 192.168.30.1 |
| 1001 | SWA | 192.168.101.0/24 | Vlan1001 | (optional) |

---

## 6. WAN Node Configuration (`wan-node1`)

The `wan-node1` container acts as a **Dynamic Policy-Based Router**.

It is managed by a startup script: `configure_router.sh`.

Key capabilities:
- Inject ZeroTier and WireGuard configurations dynamically.
- Join ZeroTier overlay network.
- Create VLAN sub-interfaces.
- Establish WireGuard interface (`wg0`).
- Apply **policy-based routing (PBR)** to steer traffic per VLAN:
  - LAN and IoT VLANs can follow different egress tunnels.
- Implement NAT and forwarding firewall logic.

### VLAN → Tunnel Mapping

| VLAN | Traffic Type | Egress Tunnel | Policy Table |
|-------|----------------|----------------|---------------|
| 10 | LAN / Corp | ZeroTier (`zt0`) | `zerotier_wan` |
| 30 | IoT | WireGuard (`wg0`) | `swa_wan` |
| 1001 | Secure Web Access | WireGuard (`wg0`) | `swa_wan` |

### Example Routing Logic (simplified)
```bash
ip rule add from 192.168.10.0/24 table zerotier_wan
ip rule add from 192.168.30.0/24 table swa_wan
ip rule add from 192.168.101.0/24 table swa_wan
```

---

## 7. Tunnel Implementation Details

### 7.1 ZeroTier
- Managed by `zerotier-one` service.
- Automatically joins the defined network (`ZT_NETWORKID`).
- Provides L2 connectivity over encrypted transport.
- Ideal for **site-to-site**, **multi-tenant**, and **remote branch** use cases.

### 7.2 WireGuard
- Lightweight L3 VPN interface.
- Configured dynamically by the router script.
- Used for **Secure Web Access** (outbound traffic).

### 7.3 Commercial Secure Web Gateways (Future Replacement)
The WireGuard tunnel (`wg0`) can be replaced by any of the following:
- **Zscaler Internet Access (ZIA)**
- **Cloudflare Gateway**
- **Netskope SWG**

These services act as secure, policy-driven web gateways.  
Only the transport (tunnel type and configuration) changes; the LAN and VLAN logic remain identical.

---

## 8. Security and Policy Design

1. **Segmentation by VLAN:**
   - Corporate and IoT networks separated by design.
   - Independent routing tables and NAT per VLAN.

2. **Tunnels as Security Domains:**
   - ZeroTier: private site-to-site network (encrypted mesh)
   - WireGuard (or SWG): Internet-facing access path (controlled breakout)

3. **NAT and Firewall:**
   - All traffic leaving tunnels is masqueraded.
   - Optional iptables FORWARD policies can restrict inter-VLAN traffic.

---

## 9. Future Extensions

- Replace WireGuard with **Zscaler ZIA** or **Cloudflare Gateway** using GRE/IPSec tunnels.
- Integrate local DNS-based content filtering per VLAN.
- Introduce SONiC route redistribution to share learned prefixes.
- Extend topology to multiple sites with ZeroTier mesh.

---

## 10. Conclusion

The SecureNet POC demonstrates a **modular network architecture** where:
- **SONiC provides the LAN fabric**, VLANs, and SVIs.
- **WAN-Node1 acts as the security edge**, enforcing routing and access policies.
- **Overlay tunnels (ZeroTier + WireGuard/SWG)** deliver encrypted and policy-controlled WAN connectivity.

This structure allows enterprises to scale from a **lightweight POC** to a **production-grade Secure Access Edge**, replacing the open-source SWA tunnel with commercial secure web gateways as needed.
