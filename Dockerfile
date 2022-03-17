FROM ubuntu:20.04

LABEL maintainer="aofei@aofeisheng.com"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y curl gnupg2 iproute2 iptables supervisor \
	&& curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-client-archive-keyring.gpg \
	&& echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-client-archive-keyring.gpg] https://pkg.cloudflareclient.com focal main" | tee /etc/apt/sources.list.d/cloudflare-client.list > /dev/null \
	&& apt-get update \
	&& apt-get install -y cloudflare-warp

COPY cloudflare-warp-supervisord.conf /etc/supervisor/conf.d/
COPY cloudflare-warp-startup.sh /usr/lib/supervisor/scripts/

ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["--nodaemon"]
