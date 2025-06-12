#!/bin/sh
# modwebui.sh: Modifikasi WebUI Asuswrt-Merlin otomatis

set -e

echo "=== MODIFIKASI WEBUI ASUSWRT-MERLIN ==="

# a. Deteksi USB storage mount point
USB_MOUNT=$(ls -d /tmp/mnt/*/ 2>/dev/null | grep -vE 'opt|\.sys' | head -n 1)

if [ -n "$USB_MOUNT" ] && [ -d "$USB_MOUNT" ]; then
    TARGET="$USB_MOUNT"
    echo "[INFO] USB storage ditemukan di: $USB_MOUNT"
else
    TARGET="/jffs"
    echo "[INFO] USB storage tidak ditemukan. File akan disimpan di: /jffs"
fi

# b. File source dan destinasi
declare -A FILEMAP
FILEMAP["/www/device-map/router.asp"]="$TARGET/router.asp"
FILEMAP["/www/EN.dict"]="$TARGET/EN.dict"
FILEMAP["/www/require/modules/menuTree.js"]="$TARGET/menuTree.js"

# c. Copy dan edit file
echo "[INFO] Memproses file modifikasi..."

# 1. router.asp
if cp -f /www/device-map/router.asp "$TARGET/router.asp"; then
    sed -i 's/刺客模式/Turbo Mode/g' "$TARGET/router.asp" || { echo "[FAIL] Edit router.asp gagal. Reboot router agar file kembali default."; exit 1; }
    echo "[OK] router.asp dimodifikasi dan disimpan di $TARGET"
else
    echo "[FAIL] Copy router.asp gagal. Reboot router agar file kembali default."
    exit 1
fi

# 2. EN.dict
if cp -f /www/EN.dict "$TARGET/EN.dict"; then
    sed -i 's/网易 UU 加速器/UU Accelerator/g' "$TARGET/EN.dict" || { echo "[FAIL] Edit EN.dict gagal. Reboot router agar file kembali default."; exit 1; }
    sed -i 's/UU 路由器插件为三大主机（PS4、Switch、Xbox One）、PC 外服端游提供加速。可实现多设备同时加速，畅享全球联机超快感！/UU router plug-in provides acceleration for three major consoles (PS4, Switch, Xbox One) and foreign server PC games. This plug-in can achieve simultaneous acceleration of multiple devices and enjoy the wonderful experience of global online connection!/g' "$TARGET/EN.dict" || { echo "[FAIL] Edit EN.dict gagal. Reboot router agar file kembali default."; exit 1; }
    echo "[OK] EN.dict dimodifikasi dan disimpan di $TARGET"
else
    echo "[FAIL] Copy EN.dict gagal. Reboot router agar file kembali default."
    exit 1
fi

# 3. menuTree.js
if cp -f /www/require/modules/menuTree.js "$TARGET/menuTree.js"; then
    sed -i 's/网易UU加速器/UU Accelerator/g' "$TARGET/menuTree.js" || { echo "[FAIL] Edit menuTree.js gagal. Reboot router agar file kembali default."; exit 1; }
    echo "[OK] menuTree.js dimodifikasi dan disimpan di $TARGET"
else
    echo "[FAIL] Copy menuTree.js gagal. Reboot router agar file kembali default."
    exit 1
fi

# d. Update atau buat /jffs/scripts/services-start
SERVICE_START="/jffs/scripts/services-start"
BIND_SCRIPT="
# [modwebui.sh] Bind mount file modifikasi WebUI otomatis
BIND_LIST=\"/www/device-map/router.asp $TARGET/router.asp
/www/EN.dict $TARGET/EN.dict
/www/require/modules/menuTree.js $TARGET/menuTree.js\"

echo \"[bind-mount] Memulai proses bind file modifikasi...\"
echo \"\$BIND_LIST\" | while read TARGET SOURCE; do
    [ -z \"\$TARGET\" ] && continue
    [ -z \"\$SOURCE\" ] && continue
    if [ -f \"\$SOURCE\" ]; then
        umount \"\$TARGET\" 2>/dev/null
        mount -o bind \"\$SOURCE\" \"\$TARGET\"
        echo \"[bind-mount] \$SOURCE → \$TARGET : Sukses\"
    else
        echo \"[bind-mount] \$SOURCE tidak ditemukan, lewati.\"
    fi
done
echo \"[bind-mount] Selesai.\"
"

# Tambahkan atau buat services-start
if [ -f "$SERVICE_START" ]; then
    if ! grep -q '\[modwebui\.sh\]' "$SERVICE_START"; then
        echo "$BIND_SCRIPT" >> "$SERVICE_START"
        echo "[OK] Bind mount script ditambahkan ke $SERVICE_START"
    else
        echo "[INFO] Script bind mount sudah ada di $SERVICE_START"
    fi
else
    echo "#!/bin/sh" > "$SERVICE_START"
    echo "$BIND_SCRIPT" >> "$SERVICE_START"
    echo "[OK] $SERVICE_START baru dibuat & script bind mount sudah ditambahkan."
fi
chmod +x "$SERVICE_START"

# e. Tanya ke user
echo
while true; do
    echo "Ingin langsung menjalankan services-start sekarang? [y/n]: "
    read jawab
    case "$jawab" in
        y|Y)
            echo "[INFO] Menjalankan $SERVICE_START..."
            sh "$SERVICE_START"
            echo "[OK] Script bind mount sudah aktif. Silakan refresh WebUI router."
            break
            ;;
        n|N)
            echo "[INFO] Silakan reboot router untuk mengaktifkan modifikasi."
            break
            ;;
        *)
            echo "Masukkan y (ya) atau n (tidak) saja."
            ;;
    esac
done

# f. Sukses
echo
echo "=== Modifikasi WebUI selesai dan sukses! ==="
exit 0
