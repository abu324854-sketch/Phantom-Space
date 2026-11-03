#!/usr/bin/env python3
"""
Eski va katta fayllarni bulutga ko'chirib, kompyuter xotirasini bo'shatadi.

Xavfsizlik: fayl avval bulutga nusxalanadi, hajmi va SHA-256 tekshiriladi,
FAQAT shundan keyin lokal nusxa o'chiriladi. Lokal joyda "fayl.ext.cloud"
belgisi qoladi (bulutdagi manzil yozilgan). Standart rejim - sinov (hech narsa o'zgarmaydi).

Misollar:
  python offload.py --mount P:\\ --folders "C:\\Users\\Men\\Videos" "C:\\Users\\Men\\Downloads"
  python offload.py --mount P:\\ --folders ~/Videos --days 60 --min-mb 50 --apply
  python offload.py --mount P:\\ --restore "C:\\Users\\Men\\Videos\\kino.mp4.cloud" --apply
"""
import argparse
import hashlib
import json
import os
import platform
import shutil
import sys
import time
from pathlib import Path

PROTECTED_PARTS = {
    "windows", "program files", "program files (x86)", "programdata", "appdata",
    "system32", "$recycle.bin", "system volume information", ".git", "node_modules",
    "library", "System", "bin", "sbin", "usr", "etc", "var", "proc", "sys", "dev",
}
SKIP_SUFFIXES = {".cloud", ".sys", ".dll", ".exe", ".lnk", ".tmp"}
HOST = platform.node() or "kompyuter"


def sha256(path, chunk=8 * 1024 * 1024):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def human(n):
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024:
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} PB"


def is_protected(p: Path):
    return any(part.lower() in {x.lower() for x in PROTECTED_PARTS} for part in p.parts)


def candidates(folders, days, min_bytes):
    cutoff = time.time() - days * 86400
    for folder in folders:
        root = Path(folder).expanduser().resolve()
        if not root.is_dir():
            print(f"O'tkazib yuborildi (papka yo'q): {root}")
            continue
        for dirpath, dirnames, filenames in os.walk(root):
            dp = Path(dirpath)
            dirnames[:] = [d for d in dirnames if not is_protected(dp / d) and not d.startswith(".")]
            for name in filenames:
                p = dp / name
                if p.suffix.lower() in SKIP_SUFFIXES or name.startswith("."):
                    continue
                try:
                    st = p.stat()
                except OSError:
                    continue
                last_used = max(st.st_atime, st.st_mtime)
                if st.st_size >= min_bytes and last_used < cutoff:
                    yield root, p, st.st_size


def offload(mount, folders, days, min_mb, apply):
    mount = Path(mount)
    if not mount.exists():
        sys.exit(f"Bulut disk topilmadi: {mount}. Avval ulang (install skripti).")
    base = mount / "Offloaded" / HOST
    total = 0
    count = 0
    for root, p, size in candidates(folders, days, int(min_mb * 1024 * 1024)):
        rel = p.relative_to(root)
        dest = base / root.name / rel
        total += size
        count += 1
        if not apply:
            print(f"[SINOV] {p}  ({human(size)})")
            continue
        try:
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(p, dest)
            if dest.stat().st_size != size or sha256(p) != sha256(dest):
                print(f"XATO: tekshiruv mos kelmadi, o'chirilmadi: {p}")
                dest.unlink(missing_ok=True)
                continue
            stub = Path(str(p) + ".cloud")
            stub.write_text(json.dumps({"cloud_path": str(dest), "size": size, "host": HOST}), encoding="utf-8")
            p.unlink()
            print(f"KO'CHIRILDI: {p}  ({human(size)})")
        except Exception as e:
            print(f"XATO ({p}): {e}")
    action = "bo'shatiladi" if not apply else "ko'rib chiqildi"
    print(f"\nJami: {count} ta fayl, {human(total)} {action}.")
    if not apply:
        print("Haqiqatan ko'chirish uchun --apply qo'shing.")


def restore(stub_path, apply):
    stub = Path(stub_path)
    info = json.loads(stub.read_text(encoding="utf-8"))
    cloud = Path(info["cloud_path"])
    target = Path(str(stub)[: -len(".cloud")])
    if not cloud.exists():
        sys.exit(f"Bulutda fayl topilmadi: {cloud}")
    print(f"Qaytariladi: {cloud} -> {target}")
    if apply:
        shutil.copy2(cloud, target)
        stub.unlink()
        print("Tayyor.")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--mount", required=True, help="Bulut disk (masalan P:\\ yoki ~/P)")
    ap.add_argument("--folders", nargs="*", default=[], help="Tozalanadigan papkalar")
    ap.add_argument("--days", type=int, default=90, help="Necha kundan beri ishlatilmagan (standart 90)")
    ap.add_argument("--min-mb", type=float, default=20, help="Minimal hajm MB (standart 20)")
    ap.add_argument("--apply", action="store_true", help="Haqiqatan bajarish (aks holda sinov)")
    ap.add_argument("--restore", help="Qaytarish uchun .cloud fayl yo'li")
    a = ap.parse_args()
    if a.restore:
        restore(a.restore, a.apply)
    else:
        if not a.folders:
            sys.exit("--folders ko'rsating")
        offload(os.path.expanduser(a.mount), a.folders, a.days, a.min_mb, a.apply)
```[cite: 5]
