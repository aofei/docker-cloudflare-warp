FROM ubuntu:22.04 AS build

ARG CLOUDFLARE_WARP_VERSION

RUN apt-get update
RUN apt-get install -y lsb-release curl gnupg2 libcap2-bin
RUN curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-client-archive-keyring.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-client-archive-keyring.gpg] https://pkg.cloudflareclient.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/cloudflare-client.list
RUN apt-get update
RUN apt-get install -y cloudflare-warp${CLOUDFLARE_WARP_VERSION:+"=${CLOUDFLARE_WARP_VERSION}"}

FROM alpine:3.17

ARG S6_OVERLAY_VERSION=3.1.6.2
ARG GLIBC_VERSION=2.34-r0

COPY --from=build /usr/bin/warp-cli /usr/bin/warp-svc /usr/local/bin/
COPY rootfs/ /

RUN apk add --no-cache nftables dbus-libs
RUN for TARBALL in s6-overlay-noarch.tar.xz s6-overlay-x86_64.tar.xz s6-overlay-symlinks-noarch.tar.xz s6-overlay-symlinks-arch.tar.xz; do wget -qO- https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/${TARBALL} | tar -xpJ -C /; done
RUN mkdir /tmp/glibc-pkgs
RUN for PKG in glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk; do wget -q --directory-prefix /tmp/glibc-pkgs https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${PKG}; done
RUN apk add --no-cache --allow-untrusted --force-overwrite /tmp/glibc-pkgs/*
RUN rm -rf /tmp/glibc-pkgs
RUN /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib

ENTRYPOINT ["/init"]
