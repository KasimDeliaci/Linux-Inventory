# 📦 Envanter Yönetim Sistemi

Envanter Yönetim Sistemi, kullanıcıların ürünlerini ve stoklarını kolayca yönetmesine olanak tanır. Bu sistem, **Zenity** kullanılarak oluşturulmuş, kullanıcı dostu bir arayüz sunar. Kullanıcı ve admin hesaplarının yönetimi, ürün ekleme/güncelleme/silme gibi envanter işlemleri ve detaylı raporlama özelliklerini içerir.

## Demo Videosu

Sistemin nasıl çalıştığını gösteren bir videoya bu linkten ulaşabilirsiniz: [Demo Videosu](https://www.youtube.com/watch?v=7ebTg85kMo8)

## 🚀 Özellikler

### Kullanıcı ve Hesap Yönetimi
* Yeni kullanıcı kaydı
* Kullanıcı listeleme, güncelleme ve silme
* Hesap kilitleme ve kilidi kaldırma

### Envanter Yönetimi
* Ürün ekleme, listeleme, güncelleme ve silme
* Ürünlere göre raporlama

### Program ve Sistem Yönetimi
* Disk alanını kontrol etme
* Veri dosyalarını yedekleme
* Hata kayıtlarını görüntüleme

### Raporlama
* Stokta azalan ürünler
* En yüksek stok miktarına sahip ürünler
* Fiyata Göre Sıralama
* Envanteri Listeleme
* Kategori bazlı sıralama

## 🖥️ Nasıl Kurulur?

### 1. Depoyu Klonlayın

```bash
git clone https://github.com/KasimDeliaci/Linux-Inventory
cd Linux-Inventory
```

### 2. Gerekli Bağımlılıkları Yükleyin

**Ubuntu/Debian:**
```bash
sudo apt-get install zenity
```

**macOS:**
```bash
brew install zenity
```

**Windows:**
* Zenity, Windows'ta doğrudan desteklenmez. Alternatif olarak WSL kullanabilirsiniz.

### 3. Veri Klasörlerini ve Dosyalarını Hazırlayın

```bash
mkdir -p veri yedekler
touch veri/depo.csv veri/kullanici.csv veri/log.csv
```

### 4. Programı Başlatın

```bash
bash main.sh
```

## 📋 Kullanıcı Rolleri

| Rol | Yetkiler |
|-----|----------|
| Admin | Kullanıcı yönetimi (ekleme, silme, güncelleme, hesap kilidi açma), ürün işlemleri, sistem yönetimi |
| Kullanıcı | Ürün listeleme, raporlama |

## 📌 Dosya Yapısı

```
.
├── main.sh               # Ana başlatma dosyası
├── admin_fonksiyonlar.sh # Admin işlemleri (kullanıcı yönetimi vb.)
├── inventory.sh          # Ürün yönetimi (ekleme, güncelleme, silme vb.)
├── manage_program.sh     # Sistem yönetimi (disk kontrol, yedekleme vb.)
├── user_fonksiyonlar.sh  # Kullanıcı işlemleri (raporlama vb.)
├── veri/                 # Veri dosyaları
│   ├── depo.csv         # Ürün bilgileri
│   ├── kullanici.csv    # Kullanıcı bilgileri
│   └── log.csv          # Hata kayıtları
├── yedekler/            # Yedek dosyaları
└── README.md            # Proje açıklamaları
```

## 📂 Veri Dosyası Formatı

### kullanici.csv

| Kullanıcı Adı | Şifre (MD5) | Rol | Durum |
|---------------|-------------|-----|--------|
| admin | d41d8cd98f00b204e9800998ecf8427e | Yönetici | Aktif |

### depo.csv

| Ürün No | Ürün Adı | Stok | Fiyat | Kategori |
|---------|----------|------|--------|-----------|
| 1 | Kalem | 100 | 5.50 | Kırtasiye |

## 🔄 Başlıca Fonksiyonlar

* `kullanici_ekle()`: Yeni kullanıcı ekler
* `kullanici_listele()`: Kayıtlı kullanıcıları listeler
* `urun_ekle()`: Yeni ürün ekler
* `urun_guncelle()`: Mevcut ürün bilgilerini günceller
* `urun_sil()`: Ürünü siler
* `yedekle()`: Veri dosyalarını yedekler
* `disk_alani_goster()`: Disk kullanımını gösterir
* `hata_kayitlarini_goster()`: Hata kayıtlarını listeler
