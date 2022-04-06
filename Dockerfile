FROM ubuntu:20.04 AS build

ARG CLOUDFLARE_WARP_VERSION

RUN apt-get update && apt-get install -y curl gnupg2 libcap2-bin
RUN curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-client-archive-keyring.gpg \
	&& echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-client-archive-keyring.gpg] https://pkg.cloudflareclient.com focal main" > /etc/apt/sources.list.d/cloudflare-client.list \
	&& apt-get update \
	&& apt-get install -y cloudflare-warp$([ ! -z $CLOUDFLARE_WARP_VERSION ] && echo "=$CLOUDFLARE_WARP_VERSION")

FROM alpine

ARG GLIBC_VERSION=2.34-r0

COPY --from=build /usr/bin/warp-cli /usr/bin/warp-svc /usr/local/bin/
COPY init.d/ /etc/init.d/

RUN apk add --no-cache dbus-libs iptables ip6tables openrc
RUN export GLIBC_PKG_DIR=$(mktemp -d) \
	&& for PKG in glibc-$GLIBC_VERSION.apk glibc-bin-$GLIBC_VERSION.apk; do wget -q --directory-prefix $GLIBC_PKG_DIR https://github.com/sgerrand/alpine-pkg-glibc/releases/download/$GLIBC_VERSION/$PKG; done \
	&& apk add --no-cache --allow-untrusted $GLIBC_PKG_DIR/* \
	&& rm -rf $GLIBC_PKG_DIR \
	&& /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib

RUN rc-update add cloudflare-warp default

CMD ["/sbin/openrc-init"]
