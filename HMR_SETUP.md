# Vite HMR Setup - rails-base

## Architecture Simplifiée

This project uses a simple, working setup for Vite HMR in Docker:

```
Browser (Firefox/Chrome)
    ↓ HTTPS
Traefik (port 443)
    ↓
Rails Container (web:3000) on rails.localtest.me
    ↓ (internal Docker network)
Vite Container (vite:3036)
    ↑ WebSocket (direct connection, no Traefik)
Browser (ws://localhost:3036)
```

## Key Configuration

### vite.config.ts
```typescript
base: "/",
server: {
  host: "0.0.0.0",
  port: 3036,
  https: false,
  allowedHosts: ["vite", "localhost", "127.0.0.1"],
  hmr: {
    host: "localhost",
    port: 3036,
    protocol: "ws",  // Plain WebSocket, not WSS
  },
}
```

### config/vite.json
```json
{
  "development": {
    "autoBuild": true,
    "port": 3036,
    "host": "0.0.0.0",
    "https": false
  }
}
```

### docker-compose.yml
- Two services: `web` (Rails) and `vite` (Vite dev)
- Both on `proxy` network for Traefik
- Simple Traefik labels on `web` service only
- Environment: `VITE_RUBY_HOST=vite`, `VITE_RUBY_PORT=3036`

## Why This Works

1. **Assets**: Rails proxies `/vite/*` requests to Vite via Docker DNS (`http://vite:3036`)
2. **HMR WebSocket**: Browser connects directly to `ws://localhost:3036` (no Traefik proxy needed)
3. **Simple**: No complex middleware, no StripPrefix issues, no double-prefix problems
4. **Portable**: Works in WSL with Docker Desktop

## Troubleshooting

See "Common Issues & Solutions" section in CLAUDE.md
