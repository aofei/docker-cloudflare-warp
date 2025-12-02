FROM debian:13-slim AS build

ARG S6_OVERLAY_VERSION=3.2.1.0
ARG CLOUDFLARE_WARP_VERSION

RUN << EOF
set -eux

BUILD_ONLY_DEPS="lsb-release curl xz-utils"

apt-get update
apt-get install -y ${BUILD_ONLY_DEPS} gnupg

for tarball in s6-overlay-noarch.tar.xz "s6-overlay-$(uname -m).tar.xz"; do
	curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/${tarball}" | tar -xpJ -C /
done

curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-client-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-client-archive-keyring.gpg] https://pkg.cloudflareclient.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/cloudflare-client.list
apt-get update
apt-get install -y "cloudflare-warp${CLOUDFLARE_WARP_VERSION:+=${CLOUDFLARE_WARP_VERSION}}"

apt-get purge -y --auto-remove ${BUILD_ONLY_DEPS}
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EOF

FROM debian:13-slim
COPY --from=build / /
COPY rootfs/ /
ENTRYPOINT ["/init"]
CMD ["/command/s6-pause"]
