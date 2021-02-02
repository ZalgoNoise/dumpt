FROM zalgonoise/alpine:latest

LABEL maintainer="Zalgo Noise <zalgo.noise@gmail.com>"
LABEL version="1.0"
LABEL description="STunnel Docker image compatible with Google G Suite SLDAP tunneling, with added tcpdump for network traffic capturing"

RUN apk add \
    --update \
    --no-cache \
    stunnel \
    libressl \
    unzip \
    ca-certificates \
    tcpdump

COPY rootfs/. /.

ENTRYPOINT ["/init"]
