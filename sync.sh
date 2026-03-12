#!/bin/zsh
cd ~/Documents/GlobalDistribution
git add .
git commit -m "vault: auto-sync $(date '+%Y-%m-%d %H:%M')" --allow-empty
git pull --rebase origin main
git push origin main
