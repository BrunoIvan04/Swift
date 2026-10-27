#!/usr/bin/env bash
# Escribe un GoogleService-Info.plist de PRUEBA (proyecto demo-mis-tareas).
# Con un proyecto "demo-*" la app se conecta sola al emulador local de
# Firebase, así que las pruebas de CI nunca tocan el proyecto real.
set -euo pipefail
cat > SwiftTodoApp/GoogleService-Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>AIzaSyDemoKeyParaElEmuladorLocal0000000</string>
	<key>GCM_SENDER_ID</key>
	<string>123456789012</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>com.brunoivan.SwiftTodoApp</string>
	<key>PROJECT_ID</key>
	<string>demo-mis-tareas</string>
	<key>STORAGE_BUCKET</key>
	<string>demo-mis-tareas.appspot.com</string>
	<key>IS_ADS_ENABLED</key>
	<false/>
	<key>IS_ANALYTICS_ENABLED</key>
	<false/>
	<key>IS_APPINVITE_ENABLED</key>
	<false/>
	<key>IS_GCM_ENABLED</key>
	<false/>
	<key>IS_SIGNIN_ENABLED</key>
	<true/>
	<key>GOOGLE_APP_ID</key>
	<string>1:123456789012:ios:0000000000000000000000</string>
</dict>
</plist>
PLIST
echo "Configuración de prueba escrita (demo-mis-tareas)."
