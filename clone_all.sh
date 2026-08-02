#!/bin/bash
export GIT_TERMINAL_PROMPT=0
cd /d/pw-pdf || exit 1
LOG=/d/pw-pdf/clone_log.txt
echo "=== CLONE START $(date) ===" > "$LOG"
REPOS="build_tools desktop-apps sdkjs web-apps core desktop-sdk dictionaries document-templates"
i=0
for r in $REPOS; do
  i=$((i+1))
  if [ -d "/d/pw-pdf/$r/.git" ]; then
    echo "[$i/8] $r: already cloned, skipping" | tee -a "$LOG"
    continue
  fi
  echo "[$i/8] Cloning $r ..." | tee -a "$LOG"
  if git clone --depth 1 --single-branch --branch release/v9.4.0 "https://github.com/ONLYOFFICE/$r.git" "/d/pw-pdf/$r" >> "$LOG" 2>&1; then
    echo "[$i/8] $r: DONE (release/v9.4.0)" | tee -a "$LOG"
  else
    rm -rf "/d/pw-pdf/$r"
    echo "[$i/8] $r: release/v9.4.0 nahi mila, master try kar raha hoon..." | tee -a "$LOG"
    if git clone --depth 1 --single-branch --branch master "https://github.com/ONLYOFFICE/$r.git" "/d/pw-pdf/$r" >> "$LOG" 2>&1; then
      echo "[$i/8] $r: DONE (master)" | tee -a "$LOG"
    else
      echo "[$i/8] $r: FAILED" | tee -a "$LOG"
    fi
  fi
done
echo "=== CLONE END $(date) ===" | tee -a "$LOG"
