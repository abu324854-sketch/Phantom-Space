# PCloud — bepul shaxsiy bulut (P: disk)

Kompyuteringizda **P:** disk paydo bo'ladi. Fayllar Oracle serverida (200 GB) va qo'shimcha bepul hisoblarda (MEGA 20, Google Drive 15, pCloud 10 GB) turadi. Kompyuter yoqilganda disk avtomatik ulanadi. Jami taxminan 250 GB.

## Papkalar
- `server/oracle-setup.sh` — Oracle serverini bir buyruq bilan sozlaydi (WebDAV + HTTPS)
- `client/install-windows.ps1`, `client/install-unix.sh` — P: diskni ulaydi + avtostart
- `client/add-free-accounts.md` — MEGA/Drive/pCloud ni ulash
- `client/offload.py`, `client/install-offload-task.ps1` — eski/katta fayllarni bulutga ko'chirib joy bo'shatish
- `server/server.js`, `Dockerfile`, `docker-compose.yml` — muqobil Node serveri (sinalmagan; Oracle uchun `oracle-setup.sh` ni ishlating)

## Bosqichlar

### 1. Oracle serverini oling (bir marta)
1. cloud.oracle.com da hisob oching (bank kartasi so'ralishi mumkin).
2. "Always Free" server yarating: Ubuntu, boot disk hajmini **200 GB** (maksimal bepul hajm) qilib.
3. Bepul domen oling (masalan duckdns.org) va uni server IP manziliga yo'naltiring.
4. Oracle konsolida: Networking → Security List → Ingress Rules: **80 va 443** portlarni oching.

### 2. Serverda o'rnatish
Serverga SSH orqali kiring, `server/oracle-setup.sh` ni nusxalab:
```
sudo bash oracle-setup.sh
```
Domen, login va parolni so'raydi (parol kamida 12 belgi).

### 3. Kompyuterni ulash
Faqat Oracle bilan (Windows, PowerShell — Administrator):
```
.\client\install-windows.ps1 -Url "https://DOMENINGIZ"
```
Mac/Linux:
```
./client/install-unix.sh https://DOMENINGIZ admin
```

### 4. Bepul hisoblarni qo'shish (ixtiyoriy, +45 GB)
`client/add-free-accounts.md` bo'yicha MEGA, Google Drive, pCloud ni ulang, so'ng:
```
.\client\install-windows.ps1 -Url "https://DOMENINGIZ" -Extras "mega,gdrive,pcl"
```
Oracle to'lib qolsa, `-OracleFull` qo'shib qayta ishga tushiring.

### 5. Joyni bo'shatish
Avval sinov (hech narsa o'zgarmaydi):
```
python client\offload.py --mount P:\ --folders "C:\Users\Men\Videos" "C:\Users\Men\Downloads"
```
Natija yoqsa `--apply` qo'shing. Fayl bulutga nusxalanadi, SHA-256 tekshiriladi, faqat keyin lokal nusxa o'chadi; o'rnida `fayl.ext.cloud` belgisi qoladi. Qaytarish:
```
python client\offload.py --mount P:\ --restore "C:\...\kino.mp4.cloud" --apply
```
Har kuni avtomatik: `.\client\install-offload-task.ps1 -Folders "C:\Users\Men\Videos"`

## Cheklovlar (halol ro'yxat)
- Bepul hajm ~250 GB. Undan ko'p kerak bo'lsa, pullik xizmat kerak (masalan Backblaze B2 ~$6.95/TB oyiga).
- Bepul tarif shartlari o'zgarishi mumkin; Oracle bo'sh turgan bepul serverni o'chirib qo'yishi mumkin. **Muhim fayllarning zaxirasini boshqa joyda ham saqlang.**
- Har xizmatdan bittadan hisob oching (bir nechta bepul hisob ko'pincha qoidalarga zid).
- Dastur va o'yinlarni P: dan ishlatish sekin. Hujjat, video, rasm, arxiv uchun yaxshi.
- Kompyuter tezlashishi diskda joy bo'shashidan bo'ladi (RAM'ga ta'sir qilmaydi). Lokal kesh standart 10 GB, `-CacheGB` bilan o'zgartiring.
- Bu skriptlarning serverga o'rnatish va Windows qismlari haqiqiy mashinada sinab ko'rilmagan; xato chiqsa xabarini yuboring, tuzataman.
