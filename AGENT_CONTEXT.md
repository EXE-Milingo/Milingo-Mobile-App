# MILINGO — AI AGENT CONTEXT FILE

> Đọc file này **trước tiên** trước mọi thay đổi code.  
> Cập nhật file này mỗi khi có thay đổi kiến trúc, endpoint, hoặc model mới.

---

## 1. TỔNG QUAN DỰ ÁN

**Milingo** là app học ngôn ngữ bằng AI, gồm 2 phần:

| Phần | Công nghệ | Vị trí |
|------|-----------|--------|
| Mobile App | Flutter + Riverpod + GoRouter | `Milingo-Mobile-App-MilingoUI/` |
| Backend API | ASP.NET Core + Firebase Admin + YOLO + Gemini | `Milingo-Backend-Yolo/` |

---

## 2. BACKEND API

### Base URL
```
Development (máy thật):     http://localhost:5098
Development (Android AVD):  http://10.0.2.2:5098
Swagger UI:                 http://localhost:5098/swagger/index.html
```

### Xác thực
- **Tất cả endpoint** (trừ `GET /supported-languages`) yêu cầu Firebase JWT:
  ```
  Authorization: Bearer <firebase_id_token>
  ```
- Backend **không có** endpoint đăng ký / đăng nhập riêng.  
- Đăng ký / đăng nhập hoàn toàn qua **Firebase Auth** phía client.  
- Sau đó client lấy `idToken` từ Firebase và gửi lên mọi request.

### Tất cả Endpoints

```
# User
POST  /api/v1/users/init-profile          Body: { displayName, targetLanguage }
GET   /api/v1/users/supported-languages   Không cần auth

# Snap & Learn
POST  /api/v1/snap/analyze                multipart/form-data, field "image"
                                          Header: Idempotency-Key: <uuid-v4>
                                          Max file: 10MB

# Decks
GET    /api/v1/decks
POST   /api/v1/decks                      Body: { name, emoji, description? }
PATCH  /api/v1/decks/{deckId}             Body: { name?, emoji?, description? }
DELETE /api/v1/decks/{deckId}             Không xóa được default deck

# Cards
GET    /api/v1/decks/{deckId}/cards
POST   /api/v1/decks/{deckId}/cards       Body: { term, translation, pronunciation,
                                                   partOfSpeech, sourceLangCode,
                                                   targetLangCode, sourceVocabId? }
DELETE /api/v1/decks/{deckId}/cards/{cardId}

# Saved Status
GET    /api/v1/flashcards/saved-status    Query: term, sourceLangCode, targetLangCode
```

### Chuẩn Response (mọi endpoint)
```json
{
  "status": "success" | "error",
  "message": "...",
  "data": <payload> | null
}
```

### Ngôn ngữ được hỗ trợ (server-side)
Backend chỉ chấp nhận các giá trị `targetLanguage` sau (dùng tên đầy đủ, không phải code):
```
"English", "Japanese", "Chinese", "Korean", "French", "German", "Spanish", "Italian"
```

---

## 3. FRONTEND — CẤU TRÚC THƯ MỤC

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   └── app_constants.dart          # Routes, base URLs, constants
│   ├── network/
│   │   ├── milingo_api_service.dart    # ✅ MilingoApiService + Dio interceptor + provider
│   │   ├── milingo_models.dart         # ✅ Tất cả response models (Dart)
│   │   ├── ai_service.dart             # (giữ nguyên, không xóa)
│   │   ├── ai_provider.dart            # (giữ nguyên, không xóa)
│   │   ├── gemini_api_service.dart     # (giữ nguyên, không xóa)
│   │   ├── openai_api_service.dart     # (giữ nguyên, không xóa)
│   │   └── dio_client.dart             # (giữ nguyên — dùng cho PayOS)
│   ├── providers/
│   │   └── firebase_providers.dart
│   ├── routing/
│   │   └── app_router.dart             # GoRouter, tất cả routes
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── auth/
│   │   ├── models/user_model.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart      # ✅ AuthService, supportedLanguagesProvider
│   │   ├── screens/
│   │   │   ├── login_screen.dart       # ⚠️ Chưa có Firebase Auth thật
│   │   │   ├── register_screen.dart    # ✅ Đã có Firebase createUserWithEmailAndPassword
│   │   │   └── choose_language_screen.dart  # ✅ Lấy ngôn ngữ từ backend, gọi initProfile
│   │   └── widgets/
│   │       └── social_buttons.dart
│   ├── snap_and_learn/
│   │   ├── models/
│   │   │   ├── milingo_result.dart     # MilingoResult (shape giữ nguyên cho UI)
│   │   │   └── vocabulary_item.dart
│   │   ├── providers/
│   │   │   └── snap_provider.dart      # ✅ Dùng MilingoApiService.analyzeSnap()
│   │   ├── screens/
│   │   │   └── snap_and_learn_screen.dart
│   │   └── widgets/
│   │       ├── save_flashcard_sheet.dart  # ✅ Dùng async flashcardProvider
│   │       ├── bottom_capture_bar.dart
│   │       └── vocab_bubble.dart
│   ├── flashcards/
│   │   ├── models/
│   │   │   ├── flashcard_models.dart   # ✅ DeckData, FlashcardEntry, FlashcardState
│   │   │   └── deck_arg.dart
│   │   ├── providers/
│   │   │   └── flashcard_provider.dart # ✅ AsyncNotifier, load từ API, optimistic update
│   │   ├── screens/
│   │   │   ├── flashcards_screen.dart
│   │   │   ├── all_categories_screen.dart
│   │   │   ├── deck_screen.dart
│   │   │   └── exam_screen.dart
│   │   └── widgets/
│   │       ├── deck_list_item.dart
│   │       ├── exam_banner.dart
│   │       ├── quick_card.dart
│   │       └── vocab_card.dart
│   ├── home/screens/simple_home_screen.dart
│   ├── leaderboard/screens/leaderboard_screen.dart
│   ├── profile/screens/profile_screen.dart
│   └── splash/screens/splash_screen.dart
├── shared/
│   ├── utils/
│   │   ├── extensions.dart
│   │   └── image_utils.dart
│   └── widgets/
│       ├── common_widgets.dart
│       └── floating_nav_button.dart
```

---

## 4. CÁC FILE QUAN TRỌNG — NỘI DUNG CỐT LÕI

### `app_constants.dart` — Routes & Config
```dart
static const String milingoBaseUrl = 'http://10.0.2.2:5098'; // Android AVD
// Routes
static const String splashRoute         = '/';
static const String authRoute           = '/auth';
static const String registerRoute       = '/register';
static const String chooseLanguageRoute = '/choose-language';
static const String homeRoute           = '/home';
static const String snapAndLearnRoute   = '/snap-and-learn';
static const String flashcardsRoute     = '/flashcards';
static const String deckRoute           = '/flashcards/deck';
static const String examRoute           = '/flashcards/exam';
static const String allCategoriesRoute  = '/flashcards/all-categories';
static const String profileRoute        = '/profile';
static const String leaderboardRoute    = '/leaderboard';
// Image
static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
```

### `milingo_models.dart` — Response Models
```dart
DeckResponse        { id, name, emoji, description, vocabCount, isDefault, createdAt }
CardResponse        { id, term, translation, pronunciation, partOfSpeech,
                      sourceLangCode, targetLangCode, createdAt, sourceVocabId? }
SnapVocabItem       { keyword, translation, pronunciation, exampleSentence,
                      detectionLabel?, detectionConfidence? }
SnapAnalysisResponse { vocabItems, coinsAwarded, snapGroupId, usedFallback }
SavedStatusResponse { isSaved, deckIds }
SupportedLanguage   { code, name, nativeName, flag }
```

### `flashcard_models.dart` — Local State Models
```dart
FlashcardEntry  { id, english, translation, pronunciation, partOfSpeech, langCode }
DeckData        { id, name, emoji, cards, isDefault }
FlashcardState  { decks }
```

### `milingo_result.dart` — Snap UI Model (KHÔNG thay đổi shape)
```dart
MilingoResult { keyword, translation, pronunciation, partOfSpeech,
                sentence, sentenceTranslation, relatedWords }
```

---

## 5. STATE MANAGEMENT — RIVERPOD

### Providers hiện có

| Provider | Loại | Mô tả |
|----------|------|-------|
| `milingoApiServiceProvider` | `Provider<MilingoApiService>` | Singleton Dio client |
| `authServiceProvider` | `Provider<AuthService>` | Gọi initProfile |
| `supportedLanguagesProvider` | `FutureProvider<List<SupportedLanguage>>` | Fetch từ backend |
| `snapControllerProvider` | `StateNotifierProvider<SnapController, SnapState>` | Snap & Learn |
| `flashcardProvider` | `AsyncNotifierProvider<FlashcardNotifier, FlashcardState>` | Decks + Cards |
| `flashcardStateProvider` | `Provider<FlashcardState>` | Shim sync cho UI cũ |
| `appRouterProvider` | Riverpod annotation | GoRouter |

### Lấy FlashcardState trong widget
```dart
// Cách mới (đầy đủ):
final asyncState = ref.watch(flashcardProvider);
final state = asyncState.valueOrNull ?? FlashcardState(decks: []);

// Cách shim (nhanh hơn, không có loading state):
final state = ref.watch(flashcardStateProvider);
```

---

## 6. LUỒNG AUTH (QUAN TRỌNG)

```
1. User nhập email + password
2. Flutter gọi FirebaseAuth.instance.createUserWithEmailAndPassword() HOẶC
                  FirebaseAuth.instance.signInWithEmailAndPassword()
3. Firebase trả về UserCredential
4. User được navigate sang ChooseLanguageScreen
5. ChooseLanguageScreen gọi GET /api/v1/users/supported-languages (hiển thị danh sách)
6. User chọn ngôn ngữ → bấm Tiếp tục
7. ChooseLanguageScreen gọi POST /api/v1/users/init-profile
   Body: { displayName: user.displayName, targetLanguage: "English" } ← tên đầy đủ!
8. Navigate sang /snap-and-learn
```

**Lưu ý quan trọng:**
- `targetLanguage` trong `initProfile` phải là **tên đầy đủ** (e.g. `"English"`), không phải code (`"en"`)
- `login_screen.dart` **chưa có** Firebase Auth thật — cần implement `signInWithEmailAndPassword`
- Token Firebase được tự động attach vào mọi request qua Dio interceptor trong `MilingoApiService`

---

## 7. PACKAGES (pubspec.yaml)

```yaml
flutter_riverpod: ^2.5.1
go_router: ^14.2.0
firebase_core: ^3.3.0
firebase_auth: ^5.1.4
cloud_firestore: ^5.2.1
camera: ^0.11.0+2
image_picker: ^1.1.2
google_generative_ai: ^0.4.6
flutter_tts: ^4.0.2
dio: ^5.5.0+1
flutter_svg: ^2.0.10+1
shared_preferences: ^2.2.3
flutter_dotenv: ^5.2.1
# uuid chưa có trong pubspec — cần thêm nếu dùng
```

> ⚠️ Package `uuid` đang được dùng trong `milingo_api_service.dart` nhưng **chưa có trong pubspec.yaml**.  
> Cần thêm: `uuid: ^4.4.0`

---

## 8. NHỮNG GÌ ĐÃ LÀM ✅ VÀ CHƯA LÀM ⚠️

### Đã làm ✅
- `milingo_api_service.dart` — Dio client + Firebase JWT interceptor + tất cả methods
- `milingo_models.dart` — Tất cả response models khớp với backend C#
- `snap_provider.dart` — Dùng `MilingoApiService.analyzeSnap()`, hỗ trợ multi-object
- `flashcard_provider.dart` — AsyncNotifier, load từ API, optimistic update + rollback
- `flashcard_models.dart` — Thêm `isDefault`, `partOfSpeech`
- `auth_provider.dart` — `AuthService`, `supportedLanguagesProvider`
- `choose_language_screen.dart` — Fetch ngôn ngữ từ backend, gọi `initProfile`
- `register_screen.dart` — Firebase `createUserWithEmailAndPassword`
- `save_flashcard_sheet.dart` — Tương thích với async `flashcardProvider`
- `app_constants.dart` — Thêm `milingoBaseUrl`
- `launchSettings.json` backend — Đổi sang `0.0.0.0:5098`

### Chưa làm ⚠️
- `login_screen.dart` — **Chưa có** `signInWithEmailAndPassword` thật
- `uuid` package — **Chưa thêm** vào `pubspec.yaml`
- `app_router.dart` — Auth guard (redirect về `/auth` nếu chưa đăng nhập) đang bị comment
- `profile_screen.dart` — Chưa kết nối API user data
- `leaderboard_screen.dart` — Chưa có API tương ứng
- `simple_home_screen.dart` — Chưa kết nối API

---

## 9. NGUYÊN TẮC BẮT BUỘC KHI CODE

### PHẢI làm
- Luôn dùng `MilingoApiService` cho mọi call API (không gọi Dio trực tiếp trong widget/screen)
- Luôn dùng Riverpod (`ref.watch` / `ref.read`) — không dùng `setState` cho global state
- Dùng `AsyncNotifier` cho state có async init (decks, cards)
- Dùng `StateNotifier` cho state đơn giản (snap)
- Xử lý lỗi bằng `MilingoApiException` — hiển thị message tiếng Việt cho user
- Optimistic update + rollback cho mọi mutation (create/update/delete)
- Import model qua `export` chain: widget → provider → `milingo_api_service.dart` → `milingo_models.dart`

### KHÔNG được làm
- ❌ Không gọi Gemini/OpenAI API trực tiếp từ frontend nữa (đã chuyển sang backend)
- ❌ Không xóa `ai_service.dart`, `gemini_api_service.dart`, `openai_api_service.dart` (giữ để không break imports cũ)
- ❌ Không dùng `localhost` trong `milingoBaseUrl` khi chạy trên Android emulator (dùng `10.0.2.2`)
- ❌ Không hardcode API key trong source code (dùng `.env`)
- ❌ Không throw exception raw lên UI — luôn bắt và convert sang message thân thiện
- ❌ Không break shape của `MilingoResult` (snap UI widget phụ thuộc vào nó)
- ❌ Không tạo Dio instance mới ngoài `MilingoApiService`
- ❌ Không quản lý Firebase token thủ công — interceptor đã xử lý tự động

---

## 10. LỖI THƯỜNG GẶP VÀ CÁCH FIX

| Lỗi | Nguyên nhân | Fix |
|-----|-------------|-----|
| `The system cannot find milingo_models.dart` | File chưa được copy vào đúng thư mục | Copy vào `lib/core/network/milingo_models.dart` |
| `401 Unauthorized` | Firebase token không được gửi | Kiểm tra user đã đăng nhập Firebase chưa; interceptor chỉ hoạt động khi có `currentUser` |
| `Connection refused` trên emulator | Dùng `localhost` thay vì `10.0.2.2` | Đổi `milingoBaseUrl = 'http://10.0.2.2:5098'` |
| `Type 'DeckResponse' not found` | `milingo_models.dart` thiếu hoặc chưa export | Kiểm tra `export` statement trong `milingo_api_service.dart` |
| `List<dynamic> can't be assigned to List<DeckData>` | Thiếu import model | Đảm bảo `milingo_models.dart` được import đúng |
| `uuid` package not found | Chưa thêm vào pubspec | Thêm `uuid: ^4.4.0` vào pubspec.yaml, chạy `flutter pub get` |
| Backend trả về 400 cho `initProfile` | `targetLanguage` dùng code (`"en"`) thay vì tên (`"English"`) | Dùng `language.name` không phải `language.code` |

---

## 11. QUY TRÌNH KHI CÓ THAY ĐỔI

### Thêm endpoint mới
1. Thêm model vào `milingo_models.dart`
2. Thêm method vào `MilingoApiService`
3. Tạo/cập nhật provider trong feature tương ứng
4. Cập nhật file này (section 2 và 8)

### Debug API
1. Mở Swagger: `http://localhost:5098/swagger/index.html`
2. Lấy token: Flutter console log hoặc `FirebaseAuth.instance.currentUser?.getIdToken()`
3. Test thủ công trong Swagger với token đó

### Khi build lỗi
```bash
flutter clean
flutter pub get
flutter run
```

---

## 12. MÔIT TRƯỜNG CHẠY

| Thiết bị | `milingoBaseUrl` |
|----------|------------------|
| Android Emulator (AVD) | `http://10.0.2.2:5098` |
| Thiết bị thật (USB) | `http://<IP-LAN-máy-tính>:5098` |
| iOS Simulator | `http://localhost:5098` |

Backend phải chạy với `--urls "http://0.0.0.0:5098"` hoặc `applicationUrl: "http://0.0.0.0:5098"` trong `launchSettings.json`.
