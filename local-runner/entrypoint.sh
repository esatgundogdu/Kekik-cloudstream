#!/bin/bash
# Container başlatıcı script

set -e

echo "=========================================="
echo "CloudStream Builder Container Başlatılıyor"
echo "Tarih: $(date)"
echo "=========================================="

# Log dizinlerini oluştur
touch /var/log/cron.log
touch /var/log/derleyici.log
touch /var/log/kontrol.log

# Git güvenli dizin ayarı (mounted volume için)
git config --global --add safe.directory /repo

# İlk çalıştırmada bir kontrol yap (opsiyonel)
if [ "${RUN_ON_START:-false}" = "true" ]; then
    echo "İlk kontrol çalıştırılıyor..."
    /app/scripts/kontrol.sh || true
fi

echo "Cron daemon başlatılıyor..."
echo "Zamanlanmış görevler:"
cat /etc/cron.d/cloudstream-cron
echo ""
echo "Log takibi: docker logs -f cloudstream-builder"
echo "=========================================="

# Cron'u ön planda çalıştır ve logları göster
cron && tail -f /var/log/cron.log /var/log/derleyici.log /var/log/kontrol.log
