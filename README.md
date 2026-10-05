# DayanVPN — VLESS + WebSocket + TLS on Railway (with landing page)

A branded version: anyone who opens your domain in a browser sees a **DayanVPN** page with your config link, QR code and setup instructions. Proxy clients connect through the same domain on WebSocket path `/ray`.

## How it works

```
Browser  ──▶  GET /        ──▶  nginx  ──▶  DayanVPN landing page (index.html)
Client   ──▶  WS  /ray     ──▶  nginx  ──▶  Xray (VLESS)  ──▶  internet
```

- **nginx** listens on Railway's `PORT` and splits traffic by path.
- **Xray** listens only on `127.0.0.1:10086` (not exposed publicly).
- **entrypoint.sh** injects your UUID from `config.json` into the landing page at startup — you only ever edit the UUID in one place.
- TLS is terminated by Railway's proxy (your `https://…up.railway.app` domain works out of the box).

## Files

| File | Purpose |
|------|---------|
| `config.json` | Xray server config (VLESS + WS, path `/ray`) — **edit your UUID here** |
| `nginx.conf` | Routes `/` → landing page, `/ray` → Xray |
| `index.html` | DayanVPN landing page (UUID auto-injected) |
| `entrypoint.sh` | Injects UUID, aligns ports, starts both services |
| `Dockerfile` | Builds nginx + latest Xray-core |

## Deploy to Railway

1. **Generate your UUID** (this is the only credential you must change):
   - PowerShell: `[guid]::NewGuid()` · macOS/Linux: `uuidgen`
   - Replace `b7e3c4a1-9f2d-4e68-a1b5-3c9d8f0e2a47` in `config.json`.
2. **Push to GitHub** — create a new (private) repo and upload all 5 files, or via git:

```powershell
git init
git add .
git commit -m "DayanVPN"
git branch -M main
git remote add origin https://github.com/YOUR-USER/dayanvpn.git
git push -u origin main
```

3. **Railway → New Project → Deploy from GitHub repo** → select the repo. Railway builds the Dockerfile automatically.
4. **Networking tab → Generate Domain** → you get e.g. `dayanvpn-abc123.up.railway.app`.
5. Open that URL in a browser — you should see the **DayanVPN** page with a live config link (built from your real domain and UUID automatically).

## Connecting a client

Easiest: open your domain in a browser and hit **Copy config**, then import from clipboard in v2rayNG / Nekobox / Streisand / Hiddify. Or scan the QR code.

Manual share link format:

```
vless://YOUR-UUID@your-domain.up.railway.app:443?encryption=none&security=tls&sni=your-domain.up.railway.app&type=ws&host=your-domain.up.railway.app&path=%2Fray#DayanVPN
```

## Troubleshooting

- **Landing page loads but VPN doesn't connect** → UUID mismatch: the UUID shown at the bottom of the page is injected from `config.json` — it must match what your client uses (if you import from the page's link, it always will).
- **Nothing loads at all** → check Railway build/deploy logs; `entrypoint.sh` or the Xray download likely failed.
- **Works on WiFi but not mobile data / vice versa** → normal, carrier-level blocks vary; the domain itself is standard HTTPS, so try again later or generate a new Railway domain.
- **QR doesn't appear** → the page loads a QR library from cdnjs; if blocked on your network, use the Copy button instead.

## Security notes

- Keep the repo **private** — `config.json` contains your UUID, which is effectively the password to your server.
- Anyone you share the page URL with can get the config — treat the domain as a secret.
- The landing page only reveals UUID/domain to whoever opens it.
