#!/bin/bash

# Admin fonksiyonlarını dahil et
source admin_fonksiyonlar.sh

# Disk alanı gösterme
disk_alani_goster() {
    yetki_kontrol || return 1

    # Dosyaların boyutlarını hesapla
    local SH_SIZE=$(du -ch *.sh | grep total | awk '{print $1}')
    local DEPO_SIZE=$(du -ch veri/depo.csv 2>/dev/null | grep total | awk '{print $1}')
    local KULLANICI_SIZE=$(du -ch veri/kullanici.csv 2>/dev/null | grep total | awk '{print $1}')
    local LOG_SIZE=$(du -ch veri/log.csv 2>/dev/null | grep total | awk '{print $1}')

    # Toplam boyut
    local TOTAL_SIZE=$(du -ch *.sh veri/*.csv 2>/dev/null | grep total | awk '{print $1}')

    # Zenity listesi ile bilgileri göster
    echo -e "Script Dosyaları\n$SH_SIZE\ndepo.csv\n$DEPO_SIZE\nkullanici.csv\n$KULLANICI_SIZE\nlog.csv\n$LOG_SIZE\nToplam\n$TOTAL_SIZE" | zenity --list \
        --title="Disk Alanı Kullanımı" \
        --text="Disk Alanı Kullanım Bilgileri:" \
        --column="Dosya Türü" --column="Boyut" \
        --width=400 --height=300
}

# Dosyaları yedekleme (sadece değişiklik olduğunda)
yedekle() {
    yetki_kontrol || return 1  # Yetki kontrolü

    local son_yedek=$(ls -t yedekler/depo_*.csv 2>/dev/null | head -n 1)
    local son_degisim=$(stat -c %Y veri/depo.csv)

    if [ -z "$son_yedek" ] || [ "$son_degisim" -gt "$(stat -c %Y "$son_yedek")" ]; then
        progress_bar "Dosyalar yedekleniyor..." 3  # İlerleme çubuğu

        mkdir -p yedekler
        cp veri/depo.csv yedekler/depo_$(date +%Y%m%d%H%M%S).csv 2>/dev/null
        cp veri/kullanici.csv yedekler/kullanici_$(date +%Y%m%d%H%M%S).csv 2>/dev/null

        zenity --info --title="Yedekleme Tamamlandı" --text="Dosyalar başarıyla yedeklendi!"
    else
        zenity --info --title="Yedekleme" --text="Son yedeklemeden bu yana değişiklik yapılmadı."
    fi
}

# Hata kayıtlarını gösterme
hata_kayitlarini_goster() {
    yetki_kontrol || return 1

    if [ ! -f veri/log.csv ]; then
        zenity --error --title="Hata" --text="Hata kayıt dosyası bulunamadı!" --width=300 --height=200
        return 1
    fi

    local LOG_CONTENT=$(cat veri/log.csv)

    if [ -z "$LOG_CONTENT" ]; then
        zenity --info --title="Hata Kayıtları" --text="Herhangi bir hata kaydı bulunamadı." --width=300 --height=200
    else
        echo "$LOG_CONTENT" | zenity --text-info --title="Hata Kayıtları" --width=600 --height=400
    fi
}

# Program kapatma fonksiyonu (kullanıcıya onay sorar)
program_kapat() {
    zenity --question --title="Çıkış" --text="Programı kapatmadan önce verilerinizi kaydetmek ister misiniz?" --default-cancel
    if [ $? -eq 0 ]; then
        yedekle
    fi
    exit 0
}

# Beklenmedik kapatmaları yakalama
trap "yedekle; exit" SIGINT SIGTERM

# Program Yönetimi Alt Menüsü
program_yonetimi() {
    local secim=$(zenity --list --title="Program Yönetimi" --column="İşlemler" \
    "Disk Alanı Göster" "Diske Yedekle" "Hata Kayıtlarını Göster" "Geri Dön" --width=500 --height=300)

    if [ $? -eq 1 ] || [ -z "$secim" ]; then
        return 0
    fi

    case $secim in
        "Disk Alanı Göster") disk_alani_goster ;;
        "Diske Yedekle") yedekle ;;
        "Hata Kayıtlarını Göster") hata_kayitlarini_goster ;;
        "Geri Dön") return 0 ;;
        *) zenity --error --title="Hata" --text="Geçersiz seçim!" ;;
    esac
}
