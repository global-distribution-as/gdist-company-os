# Mac mini — Automatisering

Alle scripts ligger i `scripts/`. Kjøres av macOS LaunchAgents (= systemets cron).

---

## Oversikt

| Script | Hva | Når |
|--------|-----|-----|
| `sync-all.sh` | Synker vault til GitHub | Hvert 10. min |
| `daily-report.sh` | E-post med ordre + inquiries | Kl 07:30 man–fre |
| `setup-mac-mini.sh` | Førstegangsoppsett | Én gang |

---

## Slik aktiverer du (etter oppsett)

```zsh
# Vault-sync:
launchctl load ~/Library/LaunchAgents/com.gdist.vault-sync.plist

# Daglig rapport:
launchctl load ~/Library/LaunchAgents/com.gdist.daily-report.plist

# Sjekk at de kjører:
launchctl list | grep gdist
```

---

## Sjekke at alt fungerer

```zsh
# Se vault-sync-logg (live):
tail -f /tmp/gdist-vault-sync.log

# Se rapport-logg:
tail -f /tmp/gdist-daily-report.log

# Test daglig rapport manuelt (uten e-post):
zsh ~/Documents/GlobalDistribution/scripts/daily-report.sh
```

---

## Konfigurere e-post (Resend)

1. Opprett gratis konto på [resend.com](https://resend.com)
2. Opprett API-nøkkel
3. Fyll inn i `scripts/config.env`:
   - `RESEND_API_KEY`
   - `EMAIL_FROM` (må være verifisert domene)
   - `EMAIL_DANIEL` og `EMAIL_MARTIN`
4. Test: `zsh ~/Documents/GlobalDistribution/scripts/daily-report.sh`

---

## Deaktivere / endre tidspunkt

```zsh
# Stopp en agent:
launchctl unload ~/Library/LaunchAgents/com.gdist.daily-report.plist

# Rediger tidspunkt i plist-filen:
open ~/Library/LaunchAgents/com.gdist.daily-report.plist

# Last inn igjen:
launchctl load ~/Library/LaunchAgents/com.gdist.daily-report.plist
```

---

## Hva rapporten inneholder

- Antall aktive ordre + status og utestående beløp
- Åpne inquiries (nye forespørsler som ikke er besvart)
- Forfalte betalinger med ⚠️-varsel

---

## Konflikter i vault

Hvis to maskiner har redigert samme fil:

```zsh
cd ~/Documents/GlobalDistribution
git status          # se hvilke filer som kolliderer
# Rediger filene og løs konflikten manuelt
git add .
git commit -m "vault: løs konflikt"
git push origin main
```
