FROM alpine

LABEL maintainer="aofei@aofeisheng.com"

RUN export BUILD_ONLY_PKGS="ca-certificates curl" \
	&& apk add --no-cache $BUILD_ONLY_PKGS \
	&& export GLIBC_VERSION=2.34-r0 \
	&& for PKG in glibc-$GLIBC_VERSION glibc-bin-$GLIBC_VERSION; do curl -fsSL https://github.com/sgerrand/alpine-pkg-glibc/releases/download/$GLIBC_VERSION/$PKG.apk -o /tmp/$PKG.apk; done \
	&& apk add --no-cache --allow-untrusted /tmp/*.apk \
	&& /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib \
	&& apk add --no-cache dbus-libs iptables ip6tables openrc \
	&& rm -rf /tmp/* \
	&& apk del $BUILD_ONLY_PKGS

COPY warp-cli warp-svc /usr/bin/
COPY init.d/ /etc/init.d/

RUN rc-update add cloudflare-warp default

CMD ["/sbin/openrc-init"]
