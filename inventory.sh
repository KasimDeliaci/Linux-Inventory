#!/bin/bash


# Admin fonksiyonlarını dahil et
source admin_fonksiyonlar.sh


# İlerleme çubuğu fonksiyonu
progress_bar() {
    local MESSAGE=$1
    local STEPS=$2

    (
        for ((i = 0; i <= STEPS; i++)); do
            echo "$((i * 100 / STEPS))"
            echo "# $MESSAGE ($i/$STEPS)"
            sleep 1
        done
    ) | zenity --progress --title="İşlem Sürüyor" --text="$MESSAGE" --percentage=0 --auto-close
}

urun_ekle() {
    yetki_kontrol || return 1

    local FORM_OUTPUT=$(zenity --forms --title="Ürün Ekle" --text="Ürün bilgilerini girin:" \
    --add-entry="Ürün Adı" \
    --add-entry="Stok Miktarı" \
    --add-entry="Birim Fiyatı" \
    --add-entry="Kategori")

    if [ -z "$FORM_OUTPUT" ]; then
        zenity --error --title="Hata" --text="İşlem iptal edildi!"
        return 1
    fi

    local URUN_ADI=$(echo "$FORM_OUTPUT" | cut -d'|' -f1 | xargs)
    local STOK=$(echo "$FORM_OUTPUT" | cut -d'|' -f2 | xargs)
    local FIYAT=$(echo "$FORM_OUTPUT" | cut -d'|' -f3 | xargs)
    local KATEGORI=$(echo "$FORM_OUTPUT" | cut -d'|' -f4 | xargs)

    # Doğrulama
    if [ -z "$URUN_ADI" ] || [ -z "$STOK" ] || [ -z "$FIYAT" ] || [ -z "$KATEGORI" ]; then
        zenity --error --title="Hata" --text="Tüm alanları doldurmalısınız!"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),ERROR,Ürün ekleme sırasında eksik bilgi girildi" >> veri/log.csv
        return 1
    fi

    if [[ "$URUN_ADI" =~ \  ]] || [[ "$KATEGORI" =~ \  ]]; then
        zenity --error --title="Hata" --text="Ürün adı ve kategori boşluk içeremez!"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),ERROR,Ürün adı veya kategori boşluk içeriyor" >> veri/log.csv
        return 1
    fi

    if ! [[ "$STOK" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Hata" --text="Stok miktarı pozitif bir sayı olmalıdır!"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),ERROR,Stok miktarı geçersiz" >> veri/log.csv
        return 1
    fi

    if ! [[ "$FIYAT" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
        zenity --error --title="Hata" --text="Fiyat pozitif bir sayı olmalıdır!"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),ERROR,Fiyat geçersiz" >> veri/log.csv
        return 1
    fi

    # Aynı kategori ve ürün adı kombinasyonunu kontrol et
    if awk -F, -v urun="$URUN_ADI" -v kategori="$KATEGORI" '$2 == urun && $5 == kategori' veri/depo.csv | grep -q .; then
        zenity --error --title="Hata" --text="Bu kategori altında bu ürün zaten mevcut!"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),ERROR,Aynı isim ve kategoriyle ürün eklenmeye çalışıldı" >> veri/log.csv
        return 1
    fi

    local URUN_NO=$(awk -F, 'END {print $1+1}' veri/depo.csv)
    [ -z "$URUN_NO" ] && URUN_NO=1
    
    progress_bar "Ürün bilgileri işleniyor..." 2

    echo "$URUN_NO,$URUN_ADI,$STOK,$FIYAT,$KATEGORI" >> veri/depo.csv
    zenity --info --title="Başarılı" --text="Ürün başarıyla eklendi!"
}

urun_sil() {
    yetki_kontrol || return 1

    local URUN_ADI=$(zenity --entry --title="Ürün Sil" --text="Silmek istediğiniz ürünün adını girin:")
    local KATEGORI=$(zenity --entry --title="Ürün Sil" --text="Silmek istediğiniz ürünün kategorisini girin:")

    if [ -z "$URUN_ADI" ] || [ -z "$KATEGORI" ]; then
        zenity --error --title="Hata" --text="Ürün adı ve kategori boş bırakılamaz!"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),ERROR,Ürün silme sırasında eksik bilgi girildi" >> veri/log.csv
        return 1
    fi

    # Ürünün var olup olmadığını kontrol et
    if ! awk -F, -v urun="$URUN_ADI" -v kategori="$KATEGORI" '$2 == urun && $5 == kategori' veri/depo.csv | grep -q .; then
        zenity --error --title="Hata" --text="Belirtilen ürün bulunamadı!"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),ERROR,Silinmek istenen ürün bulunamadı" >> veri/log.csv
        return 1
    fi

    zenity --question --title="Onay" --text="Bu ürünü silmek istediğinize emin misiniz?" || return 1

    # Ürünü sil
    awk -F, -v urun="$URUN_ADI" -v kategori="$KATEGORI" '$2 != urun || $5 != kategori' veri/depo.csv > veri/depo_temp.csv
    mv veri/depo_temp.csv veri/depo.csv

    zenity --info --title="Başarılı" --text="Ürün başarıyla silindi!"
}

# Ürün güncelleme fonksiyonu
urun_guncelle() {
    yetki_kontrol || return 1
    local URUN_ADI=$(zenity --entry --title="Ürün Güncelle" --text="Güncellemek istediğiniz ürünün adını girin:")
    local KATEGORI=$(zenity --entry --title="Ürün Güncelle" --text="Güncellemek istediğiniz ürünün kategorisini girin:")
    if [ -z "$URUN_ADI" ] || [ -z "$KATEGORI" ]; then
        zenity --error --title="Hata" --text="Ürün adı ve kategori boş bırakılamaz!"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),ERROR,Ürün güncelleme sırasında eksik bilgi girildi" >> veri/log.csv
        return 1
    fi

    # Ürünün var olup olmadığını kontrol et
    if ! awk -F, -v urun="$URUN_ADI" -v kategori="$KATEGORI" '$2 == urun && $5 == kategori' veri/depo.csv | grep -q .; then
        zenity --error --title="Hata" --text="Belirtilen ürün bulunamadı!"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),ERROR,Güncellenmek istenen ürün bulunamadı" >> veri/log.csv
        return 1
    fi

    local STOK=$(zenity --entry --title="Stok Güncelle" --text="Yeni stok miktarını girin:")
    local FIYAT=$(zenity --entry --title="Fiyat Güncelle" --text="Yeni fiyatı girin:")
    
    if ! [[ "$STOK" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Hata" --text="Stok miktarı pozitif bir sayı olmalıdır!"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),ERROR,Stok miktarı geçersiz" >> veri/log.csv
        return 1
    fi
    
    if ! [[ "$FIYAT" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
        zenity --error --title="Hata" --text="Fiyat pozitif bir sayı olmalıdır!"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),ERROR,Fiyat geçersiz" >> veri/log.csv
        return 1
    fi

    # Ürünü güncelle
    awk -F, -v urun="$URUN_ADI" -v kategori="$KATEGORI" -v stok="$STOK" -v fiyat="$FIYAT" \
    'BEGIN {OFS=","} 
    $2==urun && $5==kategori {$3=stok; $4=fiyat} 1' veri/depo.csv > veri/depo_temp.csv
    
    mv veri/depo_temp.csv veri/depo.csv
    zenity --info --title="Başarılı" --text="Ürün başarıyla güncellendi!"
}
