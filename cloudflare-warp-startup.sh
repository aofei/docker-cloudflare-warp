#!/bin/sh

PRESTART_SCRIPT=/usr/lib/supervisor/scripts/cloudflare-warp-prestart.sh
if [[ -x "$PRESTART_SCRIPT" ]]; then $PRESTART_SCRIPT; fi
/usr/bin/supervisorctl start cloudflare-warp-daemon
if [[ "$(/usr/bin/warp-cli --accept-tos account)" == *"Missing"* ]]; then
	/usr/bin/warp-cli --accept-tos register
	/usr/bin/warp-cli --accept-tos enable-always-on
fi
/usr/bin/warp-cli --accept-tos connect
/sbin/iptables -t nat -A POSTROUTING -o CloudflareWARP -j MASQUERADE
/sbin/ip6tables -t nat -A POSTROUTING -o CloudflareWARP -j MASQUERADE
POSTSTART_SCRIPT=/usr/lib/supervisor/scripts/cloudflare-warp-poststart.sh
if [[ -x "$POSTSTART_SCRIPT" ]]; then $POSTSTART_SCRIPT; fi
