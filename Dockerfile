FROM ubuntu AS build

ARG S6_OVERLAY_VERSION=3.1.0.1
ARG CLOUDFLARE_WARP_VERSION

ADD https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-noarch.tar.xz /tmp/
ADD https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-x86_64.tar.xz /tmp/
ADD https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-symlinks-noarch.tar.xz /tmp/
ADD https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-symlinks-arch.tar.xz /tmp/

RUN apt-get update && apt-get install -y curl gnupg2 libcap2-bin xz-utils
RUN mkdir /tmp/s6-overlay/ \
	&& tar -C /tmp/s6-overlay/ -Jxpf /tmp/s6-overlay-noarch.tar.xz \
	&& tar -C /tmp/s6-overlay/ -Jxpf /tmp/s6-overlay-x86_64.tar.xz \
	&& tar -C /tmp/s6-overlay/ -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz \
	&& tar -C /tmp/s6-overlay/ -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz
RUN curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-client-archive-keyring.gpg \
	&& echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-client-archive-keyring.gpg] https://pkg.cloudflareclient.com focal main" > /etc/apt/sources.list.d/cloudflare-client.list \
	&& apt-get update \
	&& apt-get install -y cloudflare-warp$([ ! -z $CLOUDFLARE_WARP_VERSION ] && echo "=$CLOUDFLARE_WARP_VERSION")

FROM alpine

ARG GLIBC_VERSION=2.34-r0

COPY --from=build /tmp/s6-overlay/ /
COPY --from=build /usr/bin/warp-cli /usr/bin/warp-svc /usr/local/bin/
COPY rootfs/ /

RUN apk add --no-cache dbus-libs iptables ip6tables
RUN export GLIBC_PKG_DIR=$(mktemp -d) \
	&& for PKG in glibc-$GLIBC_VERSION.apk glibc-bin-$GLIBC_VERSION.apk; do wget -q --directory-prefix $GLIBC_PKG_DIR https://github.com/sgerrand/alpine-pkg-glibc/releases/download/$GLIBC_VERSION/$PKG; done \
	&& apk add --no-cache --allow-untrusted $GLIBC_PKG_DIR/* \
	&& rm -rf $GLIBC_PKG_DIR \
	&& /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib

ENTRYPOINT ["/init"]
