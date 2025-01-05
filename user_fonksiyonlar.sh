#!/bin/bash

urun_listele() {
    # CSV dosyasını oku ve Zenity listesi için uygun formata dönüştür
    local URUNLER=$(awk -F, 'NR > 1 {print $1 "\n" $2 "\n" $3 "\n" $4 "\n" $5}' veri/depo.csv)

    if [ -z "$URUNLER" ]; then
        zenity --error --title="Hata" --text="Hiçbir ürün bulunamadı!"
    else
        # Zenity listesi ile ürünleri göster
        echo -e "$URUNLER" | zenity --list \
            --title="Ürün Listesi" \
            --text="Depodaki Ürünler:" \
            --column="Ürün No" --column="Ürün Adı" --column="Stok" --column="Ürün Fiyatı" --column="Kategori" \
            --width=650 --height=400
    fi
}

rapor_menu() {
    local secim=$(zenity --list --title="Raporlama Menüsü" --column="Raporlar" --height=400 --width=500 \
        "Stokta Azalan Ürünler" \
        "En Yüksek Stok Miktarı" \
        "Kategori Bazlı Ürünler" \
        "Tüm Envanteri Görüntüle" \
        "Fiyata Göre Sırala (Yüksekten Düşüğe)" \
        "Ana Menüye Dön")

    # Cancel butonuna basıldıysa veya geçersiz seçim yapıldıysa ana menüye dön
    if [ $? -eq 1 ] || [ -z "$secim" ]; then
        ana_menu
        return
    fi

    case $secim in
        "Stokta Azalan Ürünler") rapor_stokta_azalan ;;
        "En Yüksek Stok Miktarı") rapor_en_yuksek_stok ;;
        "Kategori Bazlı Ürünler") rapor_kategori_bazli ;;
        "Tüm Envanteri Görüntüle") rapor_tum_envanter ;;
        "Fiyata Göre Sırala (Yüksekten Düşüğe)") fiyata_gore_sirala ;;
        "Ana Menüye Dön") ana_menu ;;
        *) zenity --error --title="Hata" --text="Geçersiz seçim!" ;;
    esac
}

# Stokta azalan ürünleri raporla
rapor_stokta_azalan() {
    local esik_deger=$(zenity --entry --title="Stok Eşiği" --text="Stok eşiğini girin (örnek: 10):")
    if [[ ! "$esik_deger" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Hata" --text="Geçerli bir sayı giriniz!"
        return 1
    fi

    local rapor=$(awk -F, -v esik="$esik_deger" 'NR > 1 && $3 < esik {print $1 "\n" $2 "\n" $3 "\n" $4 "\n" $5}' veri/depo.csv)
    if [ -z "$rapor" ]; then
        zenity --info --title="Rapor" --text="Eşik değerin altında ürün bulunamadı."
    else
        echo -e "$rapor" | zenity --list \
            --title="Stokta Azalan Ürünler" \
            --text="Stokta Azalan Ürünler:" \
            --column="Ürün No" --column="Ürün Adı" --column="Stok" --column="Ürün Fiyatı" --column="Kategori" \
            --width=650 --height=400
    fi
}

# En yüksek stok miktarına sahip ürünleri raporla
rapor_en_yuksek_stok() {
    local esik_deger=$(zenity --entry --title="Stok Eşiği" --text="Stok eşiğini girin (örnek: 50):")
    if [[ ! "$esik_deger" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Hata" --text="Geçerli bir sayı giriniz!"
        return 1
    fi

    local rapor=$(awk -F, -v esik="$esik_deger" 'NR > 1 && $3 >= esik {print $1 "\n" $2 "\n" $3 "\n" $4 "\n" $5}' veri/depo.csv)
    if [ -z "$rapor" ]; then
        zenity --info --title="Rapor" --text="Eşik değerin üstünde ürün bulunamadı."
    else
        echo -e "$rapor" | zenity --list \
            --title="En Yüksek Stok Miktarı" \
            --text="En Yüksek Stok Miktarı:" \
            --column="Ürün No" --column="Ürün Adı" --column="Stok" --column="Ürün Fiyatı" --column="Kategori" \
            --width=650 --height=400
    fi
}

# Kategori bazlı ürünleri raporla
rapor_kategori_bazli() {
    local kategori=$(zenity --entry --title="Kategori Seçimi" --text="Hangi kategoriyi raporlamak istiyorsunuz?")
    if [ -z "$kategori" ]; then
        zenity --error --title="Hata" --text="Kategori adı boş bırakılamaz!"
        return 1
    fi

    local rapor=$(awk -F, -v kat="$kategori" 'NR > 1 && $5 == kat {print $1 "\n" $2 "\n" $3 "\n" $4 "\n" $5}' veri/depo.csv)
    if [ -z "$rapor" ]; then
        zenity --info --title="Rapor" --text="Belirtilen kategoride ürün bulunamadı."
    else
        echo -e "$rapor" | zenity --list \
            --title="Kategori Bazlı Ürünler" \
            --text="Kategori Bazlı Ürünler:" \
            --column="Ürün No" --column="Ürün Adı" --column="Stok" --column="Ürün Fiyatı" --column="Kategori" \
            --width=650 --height=400
    fi
}

# Tüm envanteri raporla
rapor_tum_envanter() {
    local rapor=$(awk -F, 'NR > 1 {print $1 "\n" $2 "\n" $3 "\n" $4 "\n" $5}' veri/depo.csv)
    if [ -z "$rapor" ]; then
        zenity --info --title="Rapor" --text="Envanterde hiçbir ürün bulunamadı."
    else
        echo -e "$rapor" | zenity --list \
            --title="Tüm Envanter" \
            --text="Tüm Envanter:" \
            --column="Ürün No" --column="Ürün Adı" --column="Stok" --column="Ürün Fiyatı" --column="Kategori" \
            --width=650 --height=400
    fi
}

# Fiyata göre sıralama (yüksekten düşüğe)
fiyata_gore_sirala() {
    # CSV dosyasını oku, fiyata göre sırala ve Zenity listesi için uygun formata dönüştür
    local rapor=$(awk -F, 'NR > 1 {print $4 "," $2 "," $3 "," $5}' veri/depo.csv | sort -t, -k1,1nr | awk -F, '{print $2 "\n" $3 "\n" $1 "\n" $4}')

    if [ -z "$rapor" ]; then
        zenity --info --title="Rapor" --text="Envanterde hiçbir ürün bulunamadı."
    else
        echo -e "$rapor" | zenity --list \
            --title="Fiyata Göre Sıralama" \
            --text="Fiyata Göre Sıralama (Yüksekten Düşüğe):" \
            --column="Ürün Adı" --column="Stok" --column="Ürün Fiyatı" --column="Kategori" \
            --width=650 --height=400
    fi
}


