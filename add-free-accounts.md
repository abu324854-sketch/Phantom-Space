# Bepul hisoblarni ulash (rclone orqali)

Avval rclone o'rnatilgan bo'lishi kerak (install skriptlari buni o'zi qiladi; yoki `winget install Rclone.Rclone`).
Har xizmatdan **bittadan** hisob oching. Quyidagi nomlarni (mega, gdrive, pcl, b2free) o'zgartirmang — installerga `-Extras` da shu nomlarni berasiz.

## MEGA (20 GB)
```
rclone config create mega mega user SIZNING@EMAIL pass "$(rclone obscure 'MEGA_PAROLI')"
```
Windows PowerShell'da:
```
$p = rclone obscure "MEGA_PAROLI"; rclone config create mega mega user SIZNING@EMAIL pass $p
```
Agar MEGA'da 2 bosqichli tasdiq yoqilgan bo'lsa, `rclone config` ni interaktiv ishlating.

## Google Drive (15 GB)
```
rclone config create gdrive drive scope drive
```
Brauzer ochiladi: Google hisobingizga kirib ruxsat bering.

## pCloud (10 GB)
```
rclone config create pcl pcloud
```
Brauzer ochiladi: kirib ruxsat bering. (Eslatma: pCloud Yevropa serveri bo'lsa, rclone so'raganda hostname sifatida `eapi.pcloud.com` tanlang.)

## Tekshirish
```
rclone listremotes
rclone about mega:
```

## Birlashtirish
```
.\install-windows.ps1 -Url "https://DOMENINGIZ" -Extras "mega,gdrive,pcl"
```
Birinchi bo'lib Oracle serveringiz to'ladi. U to'lib qolsa, o'rnatuvchini `-OracleFull` bilan qayta ishga tushiring: yangi fayllar mega, gdrive, pcl ga tushadi, eskilari esa avvalgidek ochiladi.
