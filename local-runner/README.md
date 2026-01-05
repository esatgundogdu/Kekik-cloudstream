# CloudStream Lokal Runner

GitHub Actions kullanmadan CloudStream eklentilerini otomatik olarak derleyen ve güncelleyen Docker container.

## Gereksinimler

- Docker
- Docker Compose
- Git SSH key (GitHub'a push için)

## Kurulum

```bash
cd local-runner

# Container'i derle ve başlat
docker-compose up -d --build

# Logları takip et
docker logs -f cloudstream-builder
```

## Zamanlanmis Gorevler

| Gorev | Zamanlama | Aciklama |
|-------|-----------|----------|
| `kontrol.sh` | Her 9 saatte bir (00:11, 09:11, 18:11) | Domain degisikliklerini kontrol eder |
| `derleyici.sh` | Degisiklik tespit edildiginde | Eklentileri derler ve builds branch'ine push eder |

## Manuel Calistirma

```bash
# Domain kontrolu
docker exec cloudstream-builder /app/scripts/kontrol.sh

# Derleme
docker exec cloudstream-builder /app/scripts/derleyici.sh
```

## Yapilandirma

### Cron zamanlama degistirme

`crontab` dosyasini duzenle:

```cron
# Her 6 saatte bir kontrol
11 */6 * * * root /app/scripts/kontrol.sh >> /var/log/cron.log 2>&1

# Her gun gece 3'te derleme (opsiyonel)
0 3 * * * root /app/scripts/derleyici.sh >> /var/log/cron.log 2>&1
```

### Baslatildiginda kontrol calistirma

`docker-compose.yml`'de environment ekle:

```yaml
environment:
  - RUN_ON_START=true
```

## Dosya Yapisi

```
local-runner/
├── Dockerfile           # Container image
├── docker-compose.yml   # Container yapilandirmasi
├── crontab             # Zamanlanmis gorevler
├── entrypoint.sh       # Container baslatici
├── scripts/
│   ├── derleyici.sh    # Eklenti derleyici
│   └── kontrol.sh      # Domain kontrolcu
└── README.md           # Bu dosya
```

## Cloudstream Entegrasyonu

Container calistiktan sonra:

1. `kontrol.sh` domain degisikliklerini kontrol eder
2. Degisiklik varsa `master` branch'ine commit atar
3. `derleyici.sh` otomatik tetiklenir
4. Derlenen `.cs3` dosyalari `builds` branch'ine push edilir
5. Cloudstream uygulamaniz `{repo_url}/refs/heads/builds/repo.json` uzerinden guncellemeleri alir

## Sorun Giderme

```bash
# Container durumunu kontrol et
docker ps | grep cloudstream

# Loglari incele
docker logs cloudstream-builder

# Container icine gir
docker exec -it cloudstream-builder bash

# Cron durumunu kontrol et
docker exec cloudstream-builder service cron status
```
