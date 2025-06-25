#!/bin/sh
# modwebui.sh: Modifikasi WebUI Asuswrt-Merlin otomatis (hanya /jffs/modwebui)

set -e

echo "=== MODIFIKASI WEBUI ASUSWRT-MERLIN ==="

TARGET="/jffs/modwebui"

# Pastikan folder target ada
if [ ! -d "$TARGET" ]; then
    mkdir -p "$TARGET" || { echo "[FAIL] Gagal membuat folder $TARGET. Pastikan /jffs tidak penuh."; exit 1; }
    echo "[OK] Folder $TARGET sudah dibuat."
fi

# File source dan destinasi
ROUTERASP_SRC="/www/device-map/router.asp"
ROUTERASP_DST="$TARGET/router.asp"

ENDICT_SRC="/www/EN.dict"
ENDICT_DST="$TARGET/EN.dict"

MENUTREE_SRC="/www/require/modules/menuTree.js"
MENUTREE_DST="$TARGET/menuTree.js"

echo "[INFO] Memproses file modifikasi..."

# 1. router.asp
if cp -f "$ROUTERASP_SRC" "$ROUTERASP_DST"; then
    sed -i 's/刺客模式/Turbo Mode/g' "$ROUTERASP_DST" || { echo "[FAIL] Edit router.asp gagal. Reboot router agar file kembali default."; exit 1; }
    echo "[OK] router.asp dimodifikasi dan disimpan di $TARGET"
else
    echo "[FAIL] Copy router.asp gagal. Reboot router agar file kembali default."
    exit 1
fi

# 2. EN.dict
if cp -f "$ENDICT_SRC" "$ENDICT_DST"; then
    sed -i 's/网易 UU 加速器/UU Accelerator/g' "$ENDICT_DST" || { echo "[FAIL] Edit EN.dict gagal. Reboot router agar file kembali default."; exit 1; }
    sed -i 's/UU 路由器插件为三大主机（PS4、Switch、Xbox One）、PC 外服端游提供加速。可实现多设备同时加速，畅享全球联机超快感！/UU router plug-in provides acceleration for three major consoles (PS4, Switch, Xbox One) and foreign server PC games. This plug-in can achieve simultaneous acceleration of multiple devices and enjoy the wonderful experience of global online connection!/g' "$ENDICT_DST" || { echo "[FAIL] Edit EN.dict gagal. Reboot router agar file kembali default."; exit 1; }
    echo "[OK] EN.dict dimodifikasi dan disimpan di $TARGET"
else
    echo "[FAIL] Copy EN.dict gagal. Reboot router agar file kembali default."
    exit 1
fi

# 3. menuTree.js
if cp -f "$MENUTREE_SRC" "$MENUTREE_DST"; then
    sed -i 's/网易UU加速器/UU Accelerator/g' "$MENUTREE_DST" || { echo "[FAIL] Edit menuTree.js gagal. Reboot router agar file kembali default."; exit 1; }
    echo "[OK] menuTree.js dimodifikasi dan disimpan di $TARGET"
else
    echo "[FAIL] Copy menuTree.js gagal. Reboot router agar file kembali default."
    exit 1
fi

# Update atau buat /jffs/scripts/services-start
SERVICE_START="/jffs/scripts/services-start"
BIND_SCRIPT="
# [modwebui.sh] Bind mount file modifikasi WebUI otomatis
BIND_LIST=\"/www/device-map/router.asp $ROUTERASP_DST
/www/EN.dict $ENDICT_DST
/www/require/modules/menuTree.js $MENUTREE_DST\"

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

# Tanya ke user
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

echo
echo "=== Modifikasi WebUI selesai dan sukses! ==="
exit 0
