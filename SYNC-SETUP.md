# Obsidian Vault Sync Setup

Git-based sync via GitHub. No iCloud. Runs automatically every 5 minutes.

## Prerequisites

- Git installed
- SSH key added to GitHub (or use HTTPS)
- Access to `global-distribution-as` org on GitHub

---

## One-time setup (Mac Mini / College Mac)

### 1. Clone the vault

```zsh
git clone git@github.com:global-distribution-as/gdist-company-os.git ~/Documents/GlobalDistribution
```

### 2. Make sync.sh executable

```zsh
chmod +x ~/Documents/GlobalDistribution/sync.sh
```

### 3. Create the launchd plist

Create the file `~/Library/LaunchAgents/com.gdist.obsidian-sync.plist` with this content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.gdist.obsidian-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>/Users/YOUR_USERNAME/Documents/GlobalDistribution/sync.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/obsidian-sync.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/obsidian-sync.log</string>
</dict>
</plist>
```

> Replace `YOUR_USERNAME` with your macOS username (run `whoami` to check).
> Also update the path in `sync.sh` if your username differs.

### 4. Load the agent

```zsh
launchctl load ~/Library/LaunchAgents/com.gdist.obsidian-sync.plist
```

### 5. Verify it's running

```zsh
launchctl list | grep gdist
```

You should see `com.gdist.obsidian-sync` in the output.

---

## Open in Obsidian

- Open Obsidian → **Open folder as vault**
- Select `~/Documents/GlobalDistribution`

---

## Manual sync (if needed)

```zsh
~/Documents/GlobalDistribution/sync.sh
```

## Check sync logs

```zsh
cat /tmp/obsidian-sync.log
```

---

## Conflict resolution

If two machines edit the same note simultaneously, git rebase may create a conflict. Open the conflicted file, resolve manually, then run:

```zsh
cd ~/Documents/GlobalDistribution
git add .
git commit -m "vault: resolve conflict"
git push origin main
```
