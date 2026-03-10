# 🐛 Debug Guide - Sửa lỗi "App quay về Home khi chọn ảnh"

## ✅ Đã sửa các vấn đề sau:

### 1. **SnapController không đúng cách**

**Vấn đề:** Controller dùng `@riverpod` annotation nhưng không implement đúng
**Giải pháp:** Đổi sang `StateNotifier` pattern chuẩn

**Code cũ (Sai):**

```dart
@riverpod
class SnapController extends _$SnapController {
  @override
  SnapState build() {
    return const SnapState();
  }
}
```

**Code mới (Đúng):**

```dart
class SnapController extends StateNotifier<SnapState> {
  final GeminiApiService _geminiService;

  SnapController(this._geminiService) : super(const SnapState());
}

// Provider
final snapControllerProvider = StateNotifierProvider<SnapController, SnapState>((ref) {
  final geminiService = ref.watch(geminiApiServiceProvider);
  return SnapController(geminiService);
});
```

---

### 2. **Không hiển thị Error State**

**Vấn đề:** Khi có lỗi, UI không hiển thị thông báo lỗi
**Giải pháp:** Thêm error view trong build method

**Code mới:**

```dart
body: SafeArea(
  child: snapState.isLoading
      ? _buildLoadingView()
      : snapState.error != null
          ? _buildErrorView(snapState.error!, snapController)  // ✅ Thêm error view
          : snapState.result != null
              ? _buildResultView(snapState, snapController)
              : _buildInitialView(snapController),
),
```

---

### 3. **Thêm Logging để Debug**

Thêm print statements chi tiết để tracking flow:

```dart
print('🖼️ [SnapController] Starting pickFromGallery...');
print('✅ [SnapController] Image selected: ${imageFile.path}');
print('🤖 [SnapController] Analyzing image with Gemini...');
print('✅ [SnapController] Analysis complete!');
```

---

## 📱 Cách test lại

### 1. Hot Reload/Restart

```bash
# Trong terminal đang chạy app, nhấn:
r  # Hot reload
R  # Hot restart (recommended)
```

### 2. Chọn ảnh và xem logs

1. Tap "Chọn từ thư viện"
2. Chọn một ảnh
3. Xem terminal logs để tracking:

**Logs mong đợi (Success):**

```
🖼️ [SnapController] Starting pickFromGallery with language: vi
📁 [SnapController] Opening image picker...
✅ [SnapController] Image selected: C:/Users/.../image.jpg
✅ [SnapController] Image validation passed
🤖 [SnapController] Starting AI analysis...
🔄 [SnapController] Converting image to bytes...
✅ [SnapController] Image converted: 123456 bytes
🔍 [SnapController] Validating image with AI...
📊 [SnapController] Image validation result: true
🤖 [SnapController] Analyzing image with Gemini...
✅ [SnapController] Analysis complete!
   Keyword: apple
   Translation: táo
🎉 [SnapController] State updated with result!
```

**Logs khi có lỗi:**

```
🖼️ [SnapController] Starting pickFromGallery with language: vi
📁 [SnapController] Opening image picker...
❌ [SnapController] No image selected
```

---

## 🔍 Các lỗi có thể gặp

### Lỗi 1: "No image selected"

**Nguyên nhân:** User hủy chọn ảnh
**Giải pháp:** Không cần fix, đây là hành vi bình thường

### Lỗi 2: "Failed to parse Gemini response"

**Nguyên nhân:**

- API key sai
- Gemini trả về format không đúng JSON
- Network error

**Giải pháp:**

1. Kiểm tra API key trong `app_constants.dart`
2. Kiểm tra internet connection
3. Xem full error trong logs

### Lỗi 3: "Image not suitable for learning"

**Nguyên nhân:** AI không nhận diện được vật thể rõ ràng

**Giải pháp:** Chọn ảnh khác với vật thể rõ ràng hơn

### Lỗi 4: App crash hoặc quay về Home

**Nguyên nhân:** Exception không được catch

**Giải pháp:** Check logs, tìm stack trace:

```
❌ [SnapController] Error in pickFromGallery: ...
Stack trace: ...
```

---

## 🛠️ Các file đã sửa

1. **`lib/features/snap_and_learn/controllers/snap_controller.dart`**
   - Đổi từ `@riverpod` sang `StateNotifier`
   - Thêm logging chi tiết
   - Thêm error handling tốt hơn

2. **`lib/features/snap_and_learn/screens/snap_and_learn_screen.dart`**
   - Thêm `_buildErrorView()` method
   - Sửa logic hiển thị error state

---

## 🧪 Test Cases

### Test Case 1: Chọn ảnh thành công

1. Tap "Chọn từ thư viện"
2. Chọn ảnh có vật thể rõ ràng (ví dụ: táo, bàn, ghế)
3. **Expected:** Hiển thị loading → Hiển thị kết quả

### Test Case 2: Hủy chọn ảnh

1. Tap "Chọn từ thư viện"
2. Nhấn Cancel/Back
3. **Expected:** Hiển thị error "Không có ảnh nào được chọn"

### Test Case 3: Chọn ảnh quá lớn

1. Tap "Chọn từ thư viện"
2. Chọn ảnh > 5MB
3. **Expected:** Hiển thị error "Ảnh quá lớn"

### Test Case 4: Network error

1. Tắt internet
2. Tap "Chọn từ thư viện" và chọn ảnh
3. **Expected:** Hiển thị error về network

---

## 📊 State Flow Diagram

```
[Initial View]
     ↓
   Tap "Chọn từ thư viện"
     ↓
  pickFromGallery()
     ↓
   [Loading State]
     ↓
  Image selected?
   Yes ↓         No → [Error State: "Không có ảnh"]
     ↓
  Validate size/format
     ↓
   Valid?
   Yes ↓         No → [Error State: "Ảnh không hợp lệ"]
     ↓
  _analyzeImage()
     ↓
  Call Gemini AI
     ↓
   Success?
   Yes ↓         No → [Error State: "Lỗi phân tích"]
     ↓
  [Result View] ✅
```

---

## 🎯 Điều kiện để hiển thị kết quả

```dart
// Trong SnapAndLearnScreen
snapState.error != null       → Show Error View
snapState.isLoading == true   → Show Loading View
snapState.result != null      → Show Result View
else                          → Show Initial View
```

---

## 🚀 Nếu vẫn không work

### Bước 1: Xóa cache và rebuild

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows
```

### Bước 2: Check logs kỹ hơn

Tìm các dòng log sau:

- `🖼️ Starting pickFromGallery`
- `❌ Error in ...`
- `✅ Analysis complete`

### Bước 3: Test với ảnh đơn giản

Dùng ảnh PNG/JPG nhỏ, rõ ràng (ví dụ: icon, emoji)

### Bước 4: Check Gemini API

Test API key trực tiếp:

```dart
// Trong main.dart, thêm test
void testGemini() async {
  final service = GeminiApiService._();
  // Test với ảnh mẫu
}
```

---

## 📞 Checklist Debug

- [ ] Hot restart app (`R` trong terminal)
- [ ] Xem logs trong terminal khi chọn ảnh
- [ ] Kiểm tra error state có hiển thị không
- [ ] Test với ảnh khác nhau
- [ ] Kiểm tra internet connection
- [ ] Verify API key đúng

---

**Nếu làm theo hướng dẫn trên mà vẫn lỗi, hãy:**

1. Copy toàn bộ logs trong terminal
2. Screenshot màn hình error
3. Gửi để được hỗ trợ thêm

**Good luck! 🎉**
