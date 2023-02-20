#!/bin/bash
#startup script for container

/usr/local/bin/create-certificate.sh -h

exec /bin/bash