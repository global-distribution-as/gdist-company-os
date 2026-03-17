# Remote Access — gdist-mini (Mac mini M4)

## Quick Connect

```bash
# From anywhere (via Tailscale)
ssh gdist@100.75.168.54

# From local network only
ssh gdist@10.0.0.34
```

## Network Info

| Property | Value |
|----------|-------|
| Hostname | gdist-mini |
| Local IP | 10.0.0.34 |
| Tailscale IP | 100.75.168.54 |
| Tailscale account | g-dist@ |
| MacBook Pro (Tailscale) | 100.111.160.10 |

## Services

| Service | Port | Check Command |
|---------|------|---------------|
| n8n | 5678 | `curl -s http://localhost:5678/healthz` |
| Ollama | 11434 | `curl -s http://localhost:11434/api/tags` |
| SSH | 22 | `ssh gdist@100.75.168.54` |

## Check If Services Are Running

```bash
# All at once
ollama list && \
curl -s http://localhost:5678/healthz && \
launchctl list | grep -E "n8n|ollama"
```

## Restart a Service

```bash
# Restart n8n
launchctl unload ~/Library/LaunchAgents/com.gdist.n8n.plist
launchctl load ~/Library/LaunchAgents/com.gdist.n8n.plist

# Restart Ollama
brew services restart ollama
```

## If Mac mini Is Unreachable

1. **Check Tailscale**: Open Tailscale app on MacBook Pro, verify both machines show "Connected"
2. **Check if Mac mini is online**: Try pinging `100.75.168.54`
3. **If Tailscale shows offline**: Mac mini may have lost power or rebooted
   - Tailscale auto-starts on boot, but verify in System Settings → Login Items
4. **If SSH hangs**: Remote Login may have been disabled
   - Need physical access or screen sharing to re-enable
5. **Last resort**: Power cycle the Mac mini physically

## Access n8n Dashboard Remotely

From MacBook Pro browser:
```
http://100.75.168.54:5678
```

## Access Ollama Remotely

```bash
# From MacBook Pro, query Ollama on Mac mini
curl http://100.75.168.54:11434/api/tags
```
