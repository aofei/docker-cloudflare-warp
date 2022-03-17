#!/bin/bash

/usr/bin/supervisorctl start cloudflare-warp-daemon
if [[ "$(/usr/bin/warp-cli --accept-tos account)" == *"Missing"* ]]; then /usr/bin/warp-cli --accept-tos register; fi
/usr/bin/warp-cli --accept-tos connect
/usr/sbin/iptables -t nat -A POSTROUTING -o CloudflareWARP -j MASQUERADE
/usr/sbin/ip6tables -t nat -A POSTROUTING -o CloudflareWARP -j MASQUERADE
