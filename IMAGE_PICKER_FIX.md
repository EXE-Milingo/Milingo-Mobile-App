# Fix l?i "Unsupported operation: _Namespace" khi ch?n hình ?nh

## Các thay ??i ?ã th?c hi?n:

### 1. Android - Thêm permissions vào AndroidManifest.xml
- ? CAMERA permission
- ? READ_EXTERNAL_STORAGE permission
- ? WRITE_EXTERNAL_STORAGE permission
- ? READ_MEDIA_IMAGES permission (Android 13+)

### 2. iOS - Thêm privacy keys vào Info.plist
- ? NSCameraUsageDescription
- ? NSPhotoLibraryUsageDescription
- ? NSPhotoLibraryAddUsageDescription

### 3. Android - C?p nh?t minSdk
- ? ??t minSdk = 21 (thay vì flutter.minSdkVersion)

### 4. C?i thi?n error handling trong ImageUtils
- ? Thêm logging chi ti?t
- ? Ki?m tra file existence
- ? Better error messages

## Các b??c ?? test:

1. **Clean và rebuild app:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Ch?y trên Android:**
   ```bash
   flutter run
   ```
   - App s? yêu c?u quy?n camera và storage l?n ??u
   - Nh?n "Allow" ?? c?p quy?n

3. **Ch?y trên iOS:**
   ```bash
   flutter run
   ```
   - iOS s? hi?n th? dialog xin quy?n v?i message ?ã config

4. **Test các tính n?ng:**
   - ? Ch?p ?nh t? camera
   - ? Ch?n ?nh t? th? vi?n
   - ? Ki?m tra error messages

## L?u ý:

- N?u v?n g?p l?i trên Android, hãy uninstall app và cài l?i ?? permissions ???c c?p nh?t
- Trên iOS simulator, camera không ho?t ??ng - c?n test trên thi?t b? th?c
- ??m b?o thi?t b? có k?t n?i internet ?? g?i Gemini API

## Troubleshooting:

### N?u v?n g?p l?i "_Namespace":
1. Uninstall app hoàn toàn
2. Ch?y: `flutter clean`
3. Ch?y: `flutter pub get`
4. Build l?i: `flutter run`

### N?u không hi?n dialog xin quy?n:
1. Vào Settings > Apps > Milingo
2. Manually enable Camera và Storage permissions
3. Restart app

### Check logs ?? debug:
```bash
flutter run --verbose
```

Các log messages s? giúp debug:
- ??? [ImageUtils] Starting pickFromGallery...
- ? [ImageUtils] Image picked: path
- ?? [SnapController] Starting AI analysis...
