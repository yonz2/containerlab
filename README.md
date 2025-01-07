# Software Defined Connectivity
Attempt to simulate software defined connectivity between sites using ZeroTrust based tunnels (initially with Zerotier)

The simulationm is setup using [containerlab](https://containerlab.dev/) 

The aim is to use a SONiC based switch / UCPE as the core component at each site, providing WAN connectivity and Layer 3 services such as DHCP, DNS for the local networks.

The WAN connectivity will be based on TLS Tunnels based on solutions like [ZeroTier](https://zrotier.com) or [Cloudfalre](https://www.cloudflare.com/) (other solutions are of course possible)

## Iniital Configuration


![Sites](./sites-clab.png)
