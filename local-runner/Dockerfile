# CloudStream Eklenti Derleyici ve Kontrol Container'i
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools"

# Temel paketler
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    python3.11 \
    python3-pip \
    git \
    cron \
    curl \
    unzip \
    wget \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Timezone ayarı
ENV TZ=Europe/Istanbul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Python bağımlılıkları (KONTROL.py için)
RUN pip3 install --no-cache-dir \
    Kekik \
    cloudscraper \
    pycryptodome

# Android SDK kurulumu
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    cd ${ANDROID_HOME}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip && \
    unzip -q cmdline-tools.zip && \
    rm cmdline-tools.zip && \
    mv cmdline-tools latest

# Android SDK bileşenlerini kabul et ve yükle
RUN yes | sdkmanager --licenses > /dev/null 2>&1 && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Çalışma dizini
WORKDIR /app

# Script'leri kopyala
COPY scripts/ /app/scripts/
COPY crontab /etc/cron.d/cloudstream-cron
COPY entrypoint.sh /app/entrypoint.sh

# İzinleri ayarla
RUN chmod +x /app/scripts/*.sh /app/entrypoint.sh && \
    chmod 0644 /etc/cron.d/cloudstream-cron && \
    crontab /etc/cron.d/cloudstream-cron

# Log dosyası oluştur
RUN touch /var/log/cron.log

# Entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
