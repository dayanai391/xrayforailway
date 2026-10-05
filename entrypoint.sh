#!/bin/sh
# Railway injects the PORT env var; make Xray listen on it so routing works.
PORT="${PORT:-8080}"
sed "s/\"port\": [0-9]*/\"port\": ${PORT}/" /etc/xray/config.json > /tmp/config.json
exec /usr/local/bin/xray/xray run -c /tmp/config.json
