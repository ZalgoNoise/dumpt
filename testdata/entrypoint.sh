#!/bin/sh
# Run a STunnel service with tcpdump in Docker, via:
#       docker run -dit \
#       -v `find /dir/ -name "Google*.zip"`:/data/Google.zip \
#       -p 1636:1636 --name tcp-stunnel \
#       zalgonoise/tcp-stunnel:latest
#
#       docker run -dit \
#       -v `find /dir/ -name "Google*.key"`:/data/stunnel.key \
#       -v `find /dir/ -name "Google*.crt"`:/data/stunnel.crt \
#       -p 1636:1636 --name tcp-stunnel \
#       zalgonoise/tcp-stunnel:latest
#





# Create configuration file for STunnel
# Defaults to Google's G Suite LDAP parameters

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

# Expects keys to be attached
# Creates directory if doesn't exist


if ! [ -d /data ]
then
    mkdir /data
    chmod 777 /data
fi

if ! [ -d /data/out ]
then
    mkdir /data/out
    chmod 777 /data/out
fi

cd /data

# Extracts contents from .zip file if provided

if [ -f /data/*.zip ]
then 
    unzip /data/*.zip 
fi


# Expects certificate in the /data directory
# Generates new crt/key if they aren't there

if ! [ -f /data/*.crt ] || ! [ -f /data/*.key ]
then
    openssl req -x509 -nodes -newkey rsa:2048 -days 3650 -subj '/CN=stunnel' \
                -keyout stunnel.key -out stunnel.crt
    chmod 600 stunnel.pem
else 
    mv /data/*.crt /data/stunnel.crt
    mv /data/*.key /data/stunnel.key
fi


# Sets an output file name, which increments in number
# in case a file already exists

function checkFile() {
    inc=$1
    filename="/data/out/tcp-stunnel"
    ext=".pcap"

    if [ -z ${inc} ]
    then
        if ! [ -f ${filename}${ext} ]
        then
            outfile=${filename}${ext}
        else
            checkFile 1
        fi
    else
        if ! [ -f ${filename}-${inc}${ext} ]
        then
            outfile=${filename}-${inc}${ext}
        else
            checkFile $((inc+1))
        fi
    fi
}

if [ -z ${outfile} ]
then
    checkFile
fi


# Pushes default config from /etc/stunnel/stunnel.conf
# Probes port 1636 unless specified in the command line
# e.g.: docker run --rm -ti \
#           -v `find /dir/ -name "Google*.zip"`:/data/Google.zip \
#           -v /path/to/out:/data/out \
#           -p 1636:1636 \
#           --name tcp-stunnel \
#           tcp-stunnel:0.1
#
#
if [ -z "$@" ]
then
    echo "Starting STunnel with default config"
    sh -c stunnel /etc/stunnel/stunnel.conf &
    tcpdump -i eth0 -v -w ${outfile}
elif [ "$@" == "-v" ]
then
    echo "Starting STunnel with custom config"
    sh -c stunnel /etc/stunnel/stunnel.conf &
    tcpdump -i eth0 -v 'port 1636'
fi