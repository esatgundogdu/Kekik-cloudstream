#!/bin/bash
# CloudStream Eklenti Derleyici
# Workflow: Derleyici.yml'in lokal versiyonu

# set -e kaldirildi - bazi eklentiler hata verse bile diger islemler devam etsin

REPO_DIR="/repo"
BUILDS_DIR="/tmp/builds-repo"
LOG_FILE="/var/log/derleyici.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log "Derleme baslatiliyor..."

cd "$REPO_DIR"

# Git ayarlari
git config user.email "${GIT_USER_EMAIL:-actions@github.com}"
git config user.name "${GIT_USER_NAME:-GitHub Actions}"

# Master branch'ten en son degisiklikleri cek
log "Master branch guncelleniyor..."
git fetch origin master
git checkout master
git reset --hard origin/master

# Gradle ile derleme (--continue ile hatalar olsa bile devam et)
log "Eklentiler derleniyor..."
chmod +x gradlew
./gradlew clean || true
./gradlew make makePluginsJson --continue || true

# builds branch'i ayri bir dizine clone'la
log "Builds branch hazirlaniyor..."
rm -rf "$BUILDS_DIR"
git clone --single-branch --branch builds "$(git remote get-url origin)" "$BUILDS_DIR" 2>/dev/null || {
    # builds branch yoksa olustur
    mkdir -p "$BUILDS_DIR"
    cd "$BUILDS_DIR"
    git init
    git remote add origin "$(git -C "$REPO_DIR" remote get-url origin)"
    git checkout --orphan builds
    git commit --allow-empty -m "Initial builds branch"
}

cd "$BUILDS_DIR"

# Eski dosyalari silmeden yeni dosyalari kopyala (ustune yaz)
# Bu sayede derleme hatasi veren eklentilerin eski versiyonlari korunur
log "Derleme ciktilari kopyalaniyor..."
cp "$REPO_DIR"/repo.json . 2>/dev/null || true
find "$REPO_DIR" -path "**/build/*.cs3" -exec cp {} . \; 2>/dev/null || true

# plugins.json kontrol - yoksa veya bos ise orijinal repodan cek
if [ ! -s "$REPO_DIR/build/plugins.json" ]; then
    log "plugins.json olusturulamadi, orijinal repodan cekiliyor..."
    curl -s "https://raw.githubusercontent.com/keyiflerolsun/Kekik-cloudstream/builds/plugins.json" -o plugins.json
    # URL'leri kendi repomuzla degistir
    REPO_OWNER=$(git -C "$REPO_DIR" remote get-url origin | sed 's/.*github.com[:/]\([^/]*\).*/\1/')
    sed -i "s|keyiflerolsun/Kekik-cloudstream|${REPO_OWNER}/Kekik-cloudstream|g" plugins.json
else
    cp "$REPO_DIR"/build/plugins.json . 2>/dev/null || true
fi

# Dosyalari listele
log "Kopyalanan dosyalar:"
ls -la *.cs3 2>/dev/null | head -20 || log "cs3 dosyasi bulunamadi"

# Git commit ve push
log "GitHub'a push yapiliyor..."
git config user.email "${GIT_USER_EMAIL:-actions@github.com}"
git config user.name "${GIT_USER_NAME:-GitHub Actions}"

git add .
MASTER_SHA=$(git -C "$REPO_DIR" rev-parse --short HEAD)
COMMIT_MSG="${MASTER_SHA} - $(date '+%Y-%m-%d %H:%M:%S') derlemesi"

if git diff --cached --quiet; then
    log "Degisiklik yok, commit atlaniyor"
else
    git commit --amend -m "$COMMIT_MSG" 2>/dev/null || git commit -m "$COMMIT_MSG"
    git push origin builds --force
    log "Push tamamlandi!"
fi

# Gecici dizini temizle
rm -rf "$BUILDS_DIR"

# Repo'ya geri don
cd "$REPO_DIR"
git checkout master

log "Derleme tamamlandi!"
log "=========================================="
