#!/bin/bash

function boot() {
    # Sadece bu projeye ait .sh dosyalarının çalıştırılabilir olmasını sağla
    chmod +x *.sh

    # Gerekli dizin ve dosyaları oluştur (sadece yoksa)
    if [ ! -d "veri" ]; then
        mkdir -p veri
    fi

    if [ ! -f "veri/log.csv" ]; then
        touch veri/log.csv
        echo "Tarih,İşlem,Detay" > veri/log.csv
    fi

    if [ ! -f "veri/kullanici.csv" ]; then
        touch veri/kullanici.csv
        echo "Kullanıcı Adı,Şifre (MD5),Rol,Hesap Durumu" > veri/kullanici.csv
        echo "admin,d41d8cd98f00b204e9800998ecf8427e,Yönetici,Aktif" >> veri/kullanici.csv
    fi

    if [ ! -f "veri/depo.csv" ]; then
        touch veri/depo.csv
        echo "Ürün No,Ürün Adı,Stok,Ürün Fiyatı,Kategori" > veri/depo.csv
    fi

    # Başlangıç log kaydı
    echo "$(date '+%Y-%m-%d %H:%M:%S'),BOOT,Sistem başlatıldı" >> veri/log.csv
}

boot

source admin_fonksiyonlar.sh
source inventory.sh
source manage_program.sh
source user_fonksiyonlar.sh

function landing_page() {
    while true; do
        local secim=$(zenity --list \
            --title="Envanter Yönetim Sistemi" \
            --text="Hoş Geldiniz!\nLütfen bir işlem seçin:" \
            --column="İşlemler" \
            "Giriş Yap" \
            "Kayıt Ol" \
            "Çıkış" \
            --height=250 --width=400)
        
        if [ $? -eq 1 ]; then
            zenity --question --title="Çıkış" --text="Programdan çıkmak istiyor musunuz?" --default-cancel
            if [ $? -eq 0 ]; then
                exit 0
            else
                return
            fi
        fi
        
        case "$secim" in
            "Giriş Yap") giris_yap ;;
            "Kayıt Ol") kayit_ol ;;
            "Çıkış") exit 0 ;;
            *) return ;;
        esac
    done
}

function kullanici_dogrula() {
   local KULLANICI=$1
   local MD5_SIFRE=$2
   local KAYIT=$(awk -F, -v k="$KULLANICI" -v s="$MD5_SIFRE" '$1==k && $2==s && $4=="Aktif"' veri/kullanici.csv)
   if [ -n "$KAYIT" ]; then
       export ROL=$(echo "$KAYIT" | awk -F, '{print $3}')
       return 0
   fi
   return 1
}

function giris_yap() {
   local deneme=0
   while [ $deneme -lt 3 ]; do
       KULLANICI=$(zenity --entry --title="Giriş Yap" --text="Kullanıcı adınızı girin:") || {
           zenity --question --title="Çıkış" --text="Çıkmak istiyor musunuz?" --default-cancel
           if [ $? -eq 0 ]; then return; fi
           continue
       }

       if [ -z "$KULLANICI" ]; then
           zenity --error --title="Hata" --text="Kullanıcı adınızı girmelisiniz!"
           continue
       fi

       if ! grep -q "^$KULLANICI," veri/kullanici.csv; then
           zenity --error --title="Hata" --text="Böyle bir kullanıcı bulunamadı."
           # Hatalı giriş denemesi log kaydı
           echo "$(date '+%Y-%m-%d %H:%M:%S'),HATALI_GIRIS,\"$KULLANICI hatalı giriş yaptı (kullanıcı bulunamadı)\"" >> veri/log.csv
           continue
       fi

       local DURUM=$(awk -F, -v k="$KULLANICI" '$1==k {print $4}' veri/kullanici.csv)
       if [ "$DURUM" == "Kilitli" ]; then
           zenity --error --title="Hata" --text="Hesabınız kilitli. Lütfen adminle iletişime geçin."
           # Hatalı giriş denemesi log kaydı
           echo "$(date '+%Y-%m-%d %H:%M:%S'),HATALI_GIRIS,\"$KULLANICI hatalı giriş yaptı (hesap kilitli)\"" >> veri/log.csv
           return 1
       fi

       SIFRE=$(zenity --password --title="Şifre Girin") || {
           zenity --question --title="Çıkış" --text="Çıkmak istiyor musunuz?" --default-cancel
           if [ $? -eq 0 ]; then return; fi
           continue
       }

       MD5_SIFRE=$(echo -n "$SIFRE" | md5sum | awk '{print $1}')
       if kullanici_dogrula "$KULLANICI" "$MD5_SIFRE"; then
           zenity --info --title="Başarılı" --text="Hoşgeldiniz, $KULLANICI!"
           ana_menu
           return 0
       else
           zenity --error --title="Hata" --text="Kullanıcı adı veya şifre hatalı."
           # Hatalı giriş denemesi log kaydı
           echo "$(date '+%Y-%m-%d %H:%M:%S'),HATALI_GIRIS,\"$KULLANICI hatalı giriş yaptı (yanlış şifre)\"" >> veri/log.csv
           ((deneme++))
       fi
   done

   if [ $deneme -eq 3 ]; then
       zenity --error --title="Hata" --text="Hesabınız kilitlendi."
       # Hesap kilidi log kaydı
       echo "$(date '+%Y-%m-%d %H:%M:%S'),HESAP_KILITLENDI,\"$KULLANICI hesabı kilitlendi\"" >> veri/log.csv
       awk -F, -v k="$KULLANICI" 'BEGIN {OFS=","} $1==k {$4="Kilitli"} 1' veri/kullanici.csv > veri/kullanici_temp.csv
       mv veri/kullanici_temp.csv veri/kullanici.csv
   fi
}

function kayit_ol() {
    # Kullanıcı adı girişi
    local KULLANICI_ADI=$(zenity --entry --title="Kayıt Ol" --text="Kullanıcı adını girin:") || {
        zenity --question --title="Çıkış" --text="İşlemi iptal etmek istiyor musunuz?" --default-cancel
        if [ $? -eq 0 ]; then return; fi
        kayıt_ol
        return
    }

    # Kullanıcı adı boş mu kontrol et
    if [ -z "$KULLANICI_ADI" ]; then
        zenity --error --title="Hata" --text="Kullanıcı adı gerekli!"
        kayıt_ol
        return
    fi

    # Kullanıcı adı zaten var mı kontrol et
    if grep -q "^$KULLANICI_ADI," veri/kullanici.csv; then
        zenity --error --title="Hata" --text="Bu kullanıcı zaten mevcut!"
        kayıt_ol
        return
    fi

    # Şifre girişi
    local SIFRE=$(zenity --password --title="Şifre Belirle") || {
        zenity --question --title="Çıkış" --text="İşlemi iptal etmek istiyor musunuz?" --default-cancel
        if [ $? -eq 0 ]; then return; fi
        kayıt_ol
        return
    }

    # Şifre boş mu kontrol et
    if [ -z "$SIFRE" ]; then
        zenity --error --title="Hata" --text="Şifre gerekli!"
        kayıt_ol
        return
    fi

    # Şifreyi MD5 ile hashle
    local SIFRE_HASH=$(echo -n "$SIFRE" | md5sum | awk '{print $1}')

    # Rol otomatik olarak "Kullanıcı" atanır
    local ROL="Kullanıcı"

    # CSV dosyasına yazma
    echo "$KULLANICI_ADI,$SIFRE_HASH,$ROL,Aktif" >> veri/kullanici.csv

    # İlerleme çubuğu ve başarı mesajı
    progress_bar "Kayıt oluşturuluyor..." 2
    zenity --info --title="Başarılı" --text="Kayıt başarıyla oluşturuldu!"
}

function ana_menu() {
   while true; do
       if [ "$ROL" == "Yönetici" ]; then
           # Yönetici için tam menü
           secim=$(zenity --list --title="Ana Menü" --text="İşlem seçin:" \
               --column="İşlemler" \
               "Kullanıcı ve Hesap İşlemleri" \
               "Envanter Yönetimi" \
               "Rapor Al" \
               "Program ve Sistem Yönetimi" \
               "Çıkış" \
               --height=300 --width=400) || exit 0
       else
           # Kullanıcı için kısıtlı menü
           secim=$(zenity --list --title="Ana Menü" --text="İşlem seçin:" \
               --column="İşlemler" \
               "Envanter Yönetimi" \
               "Rapor Al" \
               "Çıkış" \
               --height=300 --width=400) || exit 0
       fi

       case "$secim" in
           "Kullanıcı ve Hesap İşlemleri")
               if [ "$ROL" == "Yönetici" ]; then
                   kullanici_hesap_menu
               else
                   zenity --info --title="Uyarı" --text="Bu işlem için yönetici yetkisi gereklidir."
               fi
               ;;
           "Envanter Yönetimi") envanter_menu ;;
           "Rapor Al") rapor_menu ;;
           "Program ve Sistem Yönetimi")
               if [ "$ROL" == "Yönetici" ]; then
                   sistem_menu
               else
                   zenity --info --title="Uyarı" --text="Bu işlem için yönetici yetkisi gereklidir."
               fi
               ;;
           "Çıkış") exit 0 ;;
       esac
   done
}

function kullanici_hesap_menu() {
   while true; do
       if ! secim=$(zenity --list --title="Kullanıcı İşlemleri" \
           --column="İşlemler" \
           "Yeni Kullanıcı Ekle" \
           "Kullanıcıları Listele" \
           "Kullanıcı Güncelle" \
           "Kullanıcı Sil" \
           "Hesap Kilidi Kaldır" \
           "Ana Menüye Dön" \
           --height=300 --width=400); then
           return
       fi

       case "$secim" in
           "Yeni Kullanıcı Ekle") kullanici_ekle ;;
           "Kullanıcıları Listele") kullanici_listele ;;
           "Kullanıcı Güncelle") kullanici_guncelle ;;
           "Kullanıcı Sil") kullanici_sil ;;
           "Hesap Kilidi Kaldır") hesap_ac ;;
           "Ana Menüye Dön") return ;;
       esac
   done
}

function envanter_menu() {
   while true; do
       if ! secim=$(zenity --list --title="Envanter Yönetimi" \
           --column="İşlemler" \
           "Ürün Ekle" \
           "Ürün Listele" \
           "Ürün Güncelle" \
           "Ürün Sil" \
           "Ana Menüye Dön" \
           --height=300 --width=400); then
           return
       fi

       case "$secim" in
           "Ürün Ekle") urun_ekle ;;
           "Ürün Listele") urun_listele ;;
           "Ürün Güncelle") urun_guncelle ;;
           "Ürün Sil") urun_sil ;;
           "Ana Menüye Dön") return ;;
       esac
   done
}

function sistem_menu() {
   while true; do
       if ! secim=$(zenity --list --title="Sistem Yönetimi" \
           --column="İşlemler" \
           "Disk Alanını Göster" \
           "Diske Yedekle" \
           "Hata Kayıtlarını Göster" \
           "Ana Menüye Dön" \
           --height=300 --width=400); then
           return
       fi

       case "$secim" in
           "Disk Alanını Göster") disk_alani_goster ;;
           "Diske Yedekle") yedekle ;;
           "Hata Kayıtlarını Göster") hata_kayitlarini_goster ;;
           "Ana Menüye Dön") return ;;
       esac
   done
}

landing_page
