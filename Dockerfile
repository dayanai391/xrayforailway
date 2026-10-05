# Xray-core (VLESS + WebSocket) for Railway
FROM alpine:3.20

RUN apk add --no-cache curl unzip ca-certificates

# Install latest Xray-core
RUN mkdir -p /usr/local/bin/xray /usr/local/share/xray \
    && curl -fsSL -o /tmp/Xray-linux-64.zip "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip" \
    && unzip -o /tmp/Xray-linux-64.zip -d /usr/local/bin/xray \
    && chmod +x /usr/local/bin/xray/xray \
    && rm /tmp/Xray-linux-64.zip

# GeoIP/GeoDomain data (used by routing rules)
RUN curl -fsSL -o /usr/local/share/xray/geoip.dat "https://github.com/XTLS/Xray-core/releases/latest/download/geoip.dat" \
    && curl -fsSL -o /usr/local/share/xray/geosite.dat "https://github.com/XTLS/Xray-core/releases/latest/download/geosite.dat" \
    || true

# Railway injects PORT at runtime; entrypoint rewrites the listen port accordingly
ENV PORT=8080

COPY config.json /etc/xray/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

CMD ["/entrypoint.sh"]
