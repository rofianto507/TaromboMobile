# Run app di browser (web) - BASE_URL = localhost:8069
# Buka Chrome dengan: chrome.exe --disable-web-security --user-data-dir=C:\temp\chrome_dev_flutter http://localhost:8080
flutter run -d web-server --dart-define-from-file=env.web.json --web-port=8080
