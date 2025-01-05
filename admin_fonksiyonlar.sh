#!/bin/bash

function yetki_kontrol() {
   if [ "$ROL" != "Yönetici" ]; then
       zenity --error --title="Yetki Hatası" --text="Yönetici yetkisi gerekli!"
       return 1
   fi
   return 0
}

function progress_bar() {
   local MESSAGE=$1
   local STEPS=$2
   (
       for ((i = 0; i <= STEPS; i++)); do
           echo "$((i * 100 / STEPS))"
           echo "# $MESSAGE ($i/$STEPS)"
           sleep 1
       done
   ) | zenity --progress --title="İşlem" --text="$MESSAGE" --percentage=0 --auto-close
}

function kullanici_ekle() {
    yetki_kontrol || return 1  # Yetki kontrolü (Admin)

    # Kullanıcı adı girişi
    local KULLANICI_ADI=$(zenity --entry --title="Kullanıcı Kaydı" --text="Kullanıcı adını girin:") || {
        # Pencere kapatma ikonuna basıldığında çıkış yap
        return 1
    }

    # Kullanıcı adı boş mu kontrol et
    if [ -z "$KULLANICI_ADI" ]; then
        zenity --error --title="Hata" --text="Kullanıcı adı gerekli!"
        kullanici_ekle
        return
    fi

    # Kullanıcı adı zaten var mı kontrol et
    if grep -q "^$KULLANICI_ADI," veri/kullanici.csv; then
        zenity --error --title="Hata" --text="Bu kullanıcı zaten mevcut!"
        kullanici_ekle
        return
    fi

    # Şifre girişi
    local SIFRE=$(zenity --password --title="Şifre Belirle") || {
        # Pencere kapatma ikonuna basıldığında çıkış yap
        return 1
    }

    # Şifre boş mu kontrol et
    if [ -z "$SIFRE" ]; then
        zenity --error --title="Hata" --text="Şifre gerekli!"
        kullanici_ekle
        return
    fi

    # Rol seçme işlemi
    local ROL=$(zenity --list --radiolist --title="Rol Seçimi" --text="Kullanıcı rolünü seçin:" --column="Seç" --column="Rol" FALSE "Kullanıcı" FALSE "Yönetici") || {
        # Pencere kapatma ikonuna basıldığında çıkış yap
        return 1
    }

    # Rol seçilmediyse uyarı göster ve tekrar rol seçme ekranına dön
    if [ -z "$ROL" ]; then
        zenity --warning --title="Uyarı" --text="Lütfen bir rol seçin!"
        kullanici_ekle
        return
    fi

    # Şifreyi MD5 ile hashle
    local SIFRE_HASH=$(echo -n "$SIFRE" | md5sum | awk '{print $1}')

    # CSV dosyasına yazma
    echo "$KULLANICI_ADI,$SIFRE_HASH,$ROL,Aktif" >> veri/kullanici.csv

    # İlerleme çubuğu ve başarı mesajı
    progress_bar "Kullanıcı ekleniyor..." 2
    zenity --info --title="Başarılı" --text="Kullanıcı başarıyla eklendi!"
}

function kullanici_listele() {
    yetki_kontrol || return 1
    
    if [ ! -s veri/kullanici.csv ]; then
        zenity --error --title="Hata" --text="Kullanıcı bulunamadı!"
        return 1
    fi

    local SECILEN_KULLANICI=$(zenity --list \
        --title="Kullanıcı Listesi" \
        --width=500 \
        --height=300 \
        --radiolist \
        --column="Seç" \
        --column="Kullanıcı Adı" \
        --column="Rol" \
        --column="Durum" \
        $(while IFS=',' read -r username hash role status; do
            if [[ $username == *"Kullanıcı Adı"* ]]; then
                continue
            fi
            if [ "$role" = "Yönetici" ]; then
                echo "TRUE"
            else
                echo "FALSE"
            fi
            echo "$username" "$role" "$status"
        done < veri/kullanici.csv)) || return 1

    if [ -n "$SECILEN_KULLANICI" ]; then
        kullanici_guncelle "$SECILEN_KULLANICI"
    fi
}

function kullanici_guncelle() {
    yetki_kontrol || return 1

    local KULLANICI_ADI
    if [ -n "$1" ]; then
        # Parametre olarak kullanıcı adı geldiyse, otomatik olarak al
        KULLANICI_ADI="$1"
    else
        # Parametre yoksa, kullanıcı adını manuel olarak sor
        KULLANICI_ADI=$(zenity --entry --title="Kullanıcı Güncelle" \
            --text="Güncellenecek kullanıcı adı:") || return
    fi

    if ! grep -q "^$KULLANICI_ADI," veri/kullanici.csv; then
        zenity --error --title="Hata" --text="Kullanıcı bulunamadı!"
        return 1
    fi

    local YENI_AD=$(zenity --entry --title="Güncelleme" \
        --text="Yeni kullanıcı adı (boş bırakılabilir):") || return

    local YENI_SIFRE=$(zenity --password --title="Güncelleme" \
        --text="Yeni şifre (boş bırakılabilir):") || return

    local YENI_ROL=$(zenity --list --radiolist --title="Rol Güncelle" \
        --column="Seç" --column="Rol" \
        TRUE "Kullanıcı" FALSE "Yönetici") || return

    local YENI_SIFRE_HASH=""
    if [ -n "$YENI_SIFRE" ]; then
        YENI_SIFRE_HASH=$(echo -n "$YENI_SIFRE" | md5sum | awk '{print $1}')
    fi

    awk -F, -v k="$KULLANICI_ADI" -v yeni_ad="$YENI_AD" \
        -v yeni_sifre="$YENI_SIFRE_HASH" -v yeni_rol="$YENI_ROL" \
        'BEGIN {OFS=","} {
            if ($1==k) {
                if (yeni_ad != "") $1=yeni_ad
                if (yeni_sifre != "") $2=yeni_sifre
                if (yeni_rol != "") $3=yeni_rol
            }
            print $0
        }' veri/kullanici.csv > veri/kullanici_temp.csv && \
        mv veri/kullanici_temp.csv veri/kullanici.csv
    
    progress_bar "Güncelleniyor..." 2
    zenity --info --title="Başarılı" --text="Kullanıcı güncellendi!"
}

function kullanici_sil() {
   yetki_kontrol || return 1

   local KULLANICI_ADI=$(zenity --entry --title="Kullanıcı Sil" \
       --text="Silinecek kullanıcı adı:") || return

   if ! grep -q "^$KULLANICI_ADI," veri/kullanici.csv; then
       zenity --error --title="Hata" --text="Kullanıcı bulunamadı!"
       return 1
   fi

   zenity --question --title="Onay" \
       --text="$KULLANICI_ADI kullanıcısını silmek istediğinize emin misiniz?" || return 1

   grep -v "^$KULLANICI_ADI," veri/kullanici.csv > veri/kullanici_temp.csv && \
       mv veri/kullanici_temp.csv veri/kullanici.csv
   
   progress_bar "Siliniyor..." 2
   zenity --info --title="Başarılı" --text="Kullanıcı silindi!"
}

function hesap_kilitle() {
   yetki_kontrol || return 1

   local KULLANICI=$(zenity --entry --title="Hesap Kilitle" \
       --text="Kilitlenecek kullanıcı adı:") || return

   if [ -z "$KULLANICI" ]; then
       zenity --error --title="Hata" --text="Kullanıcı adı gerekli!"
       return 1
   fi

   if ! grep -q "^$KULLANICI," veri/kullanici.csv; then
       zenity --error --title="Hata" --text="Kullanıcı bulunamadı!"
       return 1
   fi

   zenity --question --title="Onay" \
       --text="$KULLANICI hesabını kilitlemek istediğinize emin misiniz?" || return 1

   awk -F, -v k="$KULLANICI" 'BEGIN {OFS=","} $1==k {$4="Kilitli"} 1' \
       veri/kullanici.csv > veri/kullanici_temp.csv && \
       mv veri/kullanici_temp.csv veri/kullanici.csv
   
   progress_bar "Kilitleniyor..." 2
   zenity --info --title="Başarılı" --text="Hesap kilitlendi!"
}

function hesap_ac() {
   yetki_kontrol || return 1

   local KULLANICI=$(zenity --entry --title="Hesap Aç" \
       --text="Kilidi açılacak kullanıcı adı:") || return

   if [ -z "$KULLANICI" ]; then
       zenity --error --title="Hata" --text="Kullanıcı adı gerekli!"
       return 1
   fi

   if ! grep -q "^$KULLANICI," veri/kullanici.csv; then
       zenity --error --title="Hata" --text="Kullanıcı bulunamadı!"
       return 1
   fi

   zenity --question --title="Onay" \
       --text="$KULLANICI hesabının kilidini açmak istediğinize emin misiniz?" || return 1

   awk -F, -v k="$KULLANICI" 'BEGIN {OFS=","} $1==k {$4="Aktif"} 1' \
       veri/kullanici.csv > veri/kullanici_temp.csv && \
       mv veri/kullanici_temp.csv veri/kullanici.csv
   
   progress_bar "Kilit açılıyor..." 2
   zenity --info --title="Başarılı" --text="Hesap kilidi açıldı!"
}
