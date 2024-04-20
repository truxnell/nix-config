# DNS & DHCP

!!! info "TLDR"

    External DNS: Client -> Adguard Home (r->

My DNS has evolved and changed over time, especially with a personal desire to keep my entire internet backbone boring and standard off a trusted vendor. 'Why cant I connect to my Minecraft server' and 'Are you playing with the internet again' are questions I don't want to have to answer in this house.

Sadly, while I do love my Unifi Dream Machine Pro, its DNS opportunity is lackluster and I really prefer split-dns so I don't have to access everything with ip:port.

# General

<DNS IMAGE>

My devices all use the Unifi DHCP server to get addresses, which I much prefer so I maintain all my clients in the single-pane-of-glass the UDMP provides. In the DHCP options, I add the
