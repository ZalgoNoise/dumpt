# dumpt

![CI](https://github.com/ZalgoNoise/dumpt/workflows/CI/badge.svg)

_________

### Description


An Stunnel proxy server with tcpdump, to monitor LDAP traffic when configured with Google Workspace Secure LDAP.

This container will allow you to add the `.crt`/`.key` pair generated in your Admin Console (as a zip file, or individual `.crt`/`.key` files) on the `/data` folder in the container, which in turn will pre-configure the Stunnel for Google Workspace Secure LDAP.

________

### Running dumpt

Start an stunnel service with `tcpdump` in Docker, by running:

_with a `.zip` file_:

```
docker run -it \
    -v $(find /path/to/dir/ -maxdepth 1 -name "Google*.zip"):/data/Google.zip \
    -v /path/to/output:/data/out \
    -p 1636:1636 \
    --name dumpt \
    zalgonoise/dumpt:latest
```

_with a `.crt`/`.key` pair_:

```
docker run -it \
    -v $(find /path/to/dir/ -maxdepth 1 -name "Google*.crt"):/data/stunnel.crt \
    -v $(find /path/to/dir/ -maxdepth 1 -name "Google*.key"):/data/stunnel.key \
    -v /path/to/output:/data/out \
    -p 1636:1636 \
    --name dumpt \
    zalgonoise/dumpt:latest
```

___________

### `tcpdump` Contents

The tool will generate a `.pcap` file that is placed on `/data/out`, thus linking this folder as a volume from your machine. 

> Files will not overwrite, don't worry -- they increment as numbered files

You can then analyze your `.pcap` file with other tools, including Wireshark.

__________

### Container configuration

The container is using my [`zalgonoise/alpine`](https://github.com/zalgonoise/alpine) base image to take advantage of the s6-overlay, to create running services.

This way, there is no need to send processes to the background blindly and better monitoring for runtime errors.

Stunnel is configured in `/etc/stunnel/stunnel.conf`, by creating a preset configuration file:

```bash

cd /etc/stunnel

cat << EOF > stunnel.conf
foreground = yes

setuid = stunnel
setgid = stunnel

socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[${SERVICE:-ldap}]
client = ${CLIENT:-yes}
accept = ${ACCEPT:-1636}
connect = ${CONNECT:-ldap.google.com:636}
cert = /data/stunnel.crt
key = /data/stunnel.key
EOF

```

Your certificate and key are moved to `/data/stunnel.*` in conformity to this configuration.

`tcpdump` on the other hand is just listening for network activity in this container. Since we are expecting the interactions to be solely between the LDAP client and Google, all network traffic in the machine is worth capturing. Further filtering can be placed in the analyzer tool of choice.

The command ran is the following:

```bash
tcpdump -i eth0 -vvv -w ${outfile}
```
