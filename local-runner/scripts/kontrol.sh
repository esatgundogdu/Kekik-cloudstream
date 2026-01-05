#!/bin/bash
# Domain Değişiklik Kontrolü
# Workflow: Kontrol.yml'in lokal versiyonu

set -e

REPO_DIR="/repo"
LOG_FILE="/var/log/kontrol.log"
SCRIPT_DIR="$(dirname "$0")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log "Domain kontrolü başlatılıyor..."

cd "$REPO_DIR"

# En son değişiklikleri çek
log "Git pull yapılıyor..."
git fetch origin master
git checkout master
git pull origin master

# Python betiğini çalıştır
log "KONTROL.py çalıştırılıyor..."
python3 KONTROL.py 2>&1 | tee -a "$LOG_FILE"

# Değişiklik kontrolü
log "Değişiklikler kontrol ediliyor..."
if git diff --quiet .; then
    log "Değişiklik yok, işlem sonlandırılıyor."
    log "=========================================="
    exit 0
fi

# Değişiklik varsa commit ve push
log "Değişiklikler tespit edildi, commit yapılıyor..."
git config user.email "${GIT_USER_EMAIL:-actions@github.com}"
git config user.name "${GIT_USER_NAME:-GitHub Actions}"

git add -A
git commit -m "♻️ Domain Değişikliği" -m "🔄 Otomatik domain güncellemeleri yapıldı."
git push origin master

log "Değişiklikler GitHub'a push edildi."

# Derleyiciyi tetikle (domain değişikliği varsa yeniden derle)
log "Derleyici tetikleniyor..."
"$SCRIPT_DIR/derleyici.sh"

log "=========================================="
