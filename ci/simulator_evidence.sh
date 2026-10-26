#!/usr/bin/env bash
# Compila SwiftTodoApp, la abre en un simulador de iPhone y guarda capturas
# y un video en la carpeta evidencias/. Lo ejecuta GitHub Actions en una Mac
# en la nube (ver .github/workflows/ios.yml), así que no se necesita una Mac propia.
set -euo pipefail

OUT="evidencias"
BUNDLE_ID="com.brunoivan.SwiftTodoApp"
DEFAULTS_KEY="com.promoselect.todo.tasks"   # clave que usa UserDefaultsTaskPersistence
mkdir -p "$OUT"

# 1. Elegir el iPhone del runtime de iOS más reciente instalado
UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys, re
data = json.load(sys.stdin)["devices"]
def ver(rt):
    m = re.search(r"iOS-(\d+)-(\d+)", rt)
    return (int(m.group(1)), int(m.group(2))) if m else (0, 0)
for rt in sorted((r for r in data if "iOS" in r), key=ver, reverse=True):
    phones = [d for d in data[rt] if d["name"].startswith("iPhone") and "SE" not in d["name"]]
    if phones:
        pick = next((d for d in phones if re.fullmatch(r"iPhone \d+", d["name"])), phones[0])
        print(pick["udid"]); break
')
echo "Simulador elegido: $UDID"
xcrun simctl list devices | grep "$UDID" || true

xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl ui "$UDID" appearance light
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true

# 2. Compilar la app para el simulador
xcodebuild -project SwiftTodoApp.xcodeproj -scheme SwiftTodoApp \
  -sdk iphonesimulator -destination "id=$UDID" \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build | tee "$OUT/build-log.txt" | tail -n 25
APP="build/Build/Products/Debug-iphonesimulator/SwiftTodoApp.app"
test -d "$APP"

shot() { sleep 4; xcrun simctl io "$UDID" screenshot "$OUT/$1.png"; echo "Captura: $1.png"; }
launch() { xcrun simctl launch "$UDID" "$BUNDLE_ID" >/dev/null; }
stop()  { xcrun simctl terminate "$UDID" "$BUNDLE_ID" || true; sleep 1; }

# 3. Grabar video de toda la demostración
xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$OUT/demo-simulador.mp4" &
VIDEO_PID=$!
sleep 2

# 4. Primera apertura: lista vacía
xcrun simctl install "$UDID" "$APP"
launch; shot "01_lista_vacia"; stop

# 5. Reinstalar y precargar tareas de ejemplo en UserDefaults (mismo formato
#    JSON que genera la app con Codable), una de ellas completada.
xcrun simctl uninstall "$UDID" "$BUNDLE_ID"
xcrun simctl install "$UDID" "$APP"
CONTAINER=$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)
mkdir -p "$CONTAINER/Library/Preferences"
python3 - "$CONTAINER/Library/Preferences/$BUNDLE_ID.plist" "$DEFAULTS_KEY" <<'PY'
import json, plistlib, sys, uuid
path, key = sys.argv[1], sys.argv[2]
tasks = [
    ("Estudiar Swift", True),
    ("Entregar el plan del proyecto integrador", False),
    ("Repasar UITableView y celdas personalizadas", True),
    ("Grabar el video demostrativo de la app", False),
    ("Comprar leche", False),
]
data = json.dumps([{"id": str(uuid.uuid4()).upper(), "title": t, "isCompleted": c} for t, c in tasks]).encode()
with open(path, "wb") as f:
    plistlib.dump({key: data}, f, fmt=plistlib.FMT_BINARY)
PY

launch; shot "02_lista_con_tareas_y_completadas"; stop

# 6. Persistencia: se cierra la app y se vuelve a abrir
launch; shot "03_persistencia_tras_reabrir"; stop

# 7. Modo oscuro
xcrun simctl ui "$UDID" appearance dark
launch; shot "04_modo_oscuro"; stop
xcrun simctl ui "$UDID" appearance light

# 8. Texto grande (Dynamic Type)
xcrun simctl ui "$UDID" content_size extra-extra-extra-large
launch; shot "05_texto_grande"; stop
xcrun simctl ui "$UDID" content_size large

# 9. Pruebas de interfaz (XCUITest) sobre una instalación limpia:
#    agregan, completan, eliminan deslizando y reabren la app.
xcrun simctl uninstall "$UDID" "$BUNDLE_ID" || true
set +e
TEST_RUNNER_SCREENSHOT_DIR="$PWD/$OUT" xcodebuild test \
  -project SwiftTodoApp.xcodeproj -scheme SwiftTodoApp \
  -destination "id=$UDID" -derivedDataPath build \
  -resultBundlePath build/UITests.xcresult \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tee "$OUT/ui-tests-log.txt" | grep -E "Test (Case|Suite)|error:|failed|passed|XCTAssert" | tail -n 40
UI_STATUS=${PIPESTATUS[0]}
set -e
echo "Resultado XCUITest: $UI_STATUS" | tee "$OUT/resultado-pruebas-ui.txt"
grep -E "Test Case .*(passed|failed)|Executed" "$OUT/ui-tests-log.txt" >> "$OUT/resultado-pruebas-ui.txt" || true

sleep 1
kill -INT "$VIDEO_PID" || true
wait "$VIDEO_PID" || true

# Datos del entorno de prueba para el reporte
{
  echo "Fecha (UTC): $(date -u '+%Y-%m-%d %H:%M')"
  sw_vers | sed 's/^/macOS /'
  xcodebuild -version
  xcrun simctl list devices | grep "$UDID"
  xcrun simctl list runtimes | grep -i ios | tail -n 3
} > "$OUT/entorno.txt"
ls -la "$OUT"
exit "$UI_STATUS"
