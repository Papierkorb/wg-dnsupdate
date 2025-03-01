#!/bin/sh

set -e
set -x

mkdir -p /opt/wg-dnsupdate
cp wg-dnsupdate@.service /etc/systemd/system/
cp wg-dnsupdate.sh /opt/wg-dnsupdate/
systemctl daemon-reload
