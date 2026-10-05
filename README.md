# VLESS + WebSocket + TLS on Railway

A ready-to-deploy Xray (VLESS over WebSocket) server for Railway. Railway's reverse proxy terminates TLS for you, so the tunnel between your client and the server is encrypted with HTTPS — no custom domain required.

## Files

| File | Purpose |
|------|---------|
| `config.json` | Xray server config (VLESS + WebSocket, path `/ray`, port 8080) |
| `Dockerfile` | Builds the container with latest Xray-core |
| `entrypoint.sh` | Makes Xray listen on Railway's injected `PORT` |

## 1. Generate your own UUID (recommended)

The config ships with a placeholder UUID. Generate a fresh one so nobody else can use your server:

- **Windows (PowerShell):** `[guid]::NewGuid()`
- **macOS / Linux:** `uuidgen`
- **Browser:** search "generate uuid v4"

Copy the new UUID over the one in `config.json`:

```json
"clients": [ { "id": "YOUR-NEW-UUID-HERE", "flow": "" } ]
```

Optional: change `"path": "/ray"` to any random string (e.g. `/a8f3k2`) for a little extra obscurity — just remember it for the client config.

## 2. Deploy to Railway

1. Push these 4 files to a new GitHub repository (any name).
2. Go to [railway.app](https://railway.app) → **New Project → Deploy from GitHub repo**.
3. Railway detects the `Dockerfile` automatically and builds it.
4. Once deployed, open the **Networking / Domains** tab and click **Generate Domain**.
   You'll get something like `your-app-abc123.up.railway.app`.
5. Optional but recommended: in **Settings → Networking**, enable HTTP/2 and keep public HTTP enabled (default).

> Railway free tier is fine for light personal use.

## 3. Client config

Use your address from step 4 — example for `your-app-abc123.up.railway.app`:

```json
{
  "inbounds": [
    { "port": 10808, "listen": "127.0.0.1", "protocol": "socks", "settings": { "udp": true } },
    { "port": 10809, "listen": "127.0.0.1", "protocol": "http" }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "your-app-abc123.up.railway.app",
            "port": 443,
            "users": [
              { "id": "YOUR-UUID-HERE", "encryption": "none", "flow": "" }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": { "serverName": "your-app-abc123.up.railway.app" },
        "wsSettings": { "path": "/ray" }
      }
    }
  ]
}
```

Run with: `xray run -c client.json`, then point your browser/apps to `socks5://127.0.0.1:10808`.

### Share link (for mobile clients like v2rayNG / Nekobox / Streisand)

```
vless://YOUR-UUID-HERE@your-app-abc123.up.railway.app:443?encryption=none&security=tls&sni=your-app-abc123.up.railway.app&type=ws&path=%2Fray#Railway
```

Paste this link into your mobile client, or import it as a QR code.

## 4. Verify

- From your client, check `curl -x socks5h://127.0.0.1:10808 https://ifconfig.me` — it should print Railway's server IP, not your own.
- In Railway's **Deploy Logs** you should see `Xray ... started` with no errors.

## Troubleshooting

- **Connection refused / 502:** the service isn't listening on Railway's `PORT` — check that `entrypoint.sh` runs (look at build logs; if the file lost its executable bit on Windows transfer, Railway's `chmod +x` in the Dockerfile fixes it).
- **Client connects but no traffic:** UUID mismatch between `config.json` and your client — they must match exactly.
- **Path errors:** WebSocket path must match on both sides (default `/ray`).
- **Slow speeds:** Railway free tier is shared; a paid plan or a different region (Settings → Region) often helps.

## Security notes

- Anyone with your UUID + domain can use your server — keep them private.
- Change the UUID and WS path before sharing the repo publicly.
- This encrypts traffic between your client and Railway; traffic exits from Railway's IP (or your configured outbound).
