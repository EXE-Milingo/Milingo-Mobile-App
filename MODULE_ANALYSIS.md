# MILINGO — PHÂN TÍCH MODULE & TRẠNG THÁI KẾT NỐI BACKEND

> Cập nhật lần cuối: dựa trên snapshot codebase hiện tại.
> Dùng file này để theo dõi tiến độ và ưu tiên công việc.

---

## SƠ ĐỒ TỔNG QUAN

```
┌─────────────────────────────────────────────────────────────────────┐
│                          MILINGO APP                                │
├──────────────┬───────────────┬──────────────┬───────────────────────┤
│  1. Auth     │ 2. Snap &     │ 3. Flash-    │  4. Gamification      │
│              │    Learn      │    cards     │                       │
├──────────────┼───────────────┼──────────────┼───────────────────────┤
│  5. Home     │  6. Profile   │ 7. Leader-   │  8. Premium /         │
│  Dashboard   │               │    board     │     Paywall           │
└──────────────┴───────────────┴──────────────┴───────────────────────┘
```

---

## LEGEND

| Ký hiệu | Ý nghĩa |
|---------|---------|
| ✅ | Đã kết nối backend, hoạt động đúng |
| ⚠️ | Một phần kết nối, phần còn lại vẫn giả / hardcode |
| ❌ | Toàn bộ frontend xử lý hoặc hardcode, chưa có backend |
| 🔴 | Ưu tiên cao — ảnh hưởng trực tiếp đến luồng chính |
| 🟡 | Ưu tiên trung — tính năng quan trọng nhưng không block |
| 🟢 | Ưu tiên thấp — có thể làm sau |

---

## MODULE 1 — AUTH 🔴

**Trạng thái tổng: ⚠️ 50% hoàn chỉnh**

Backend không có endpoint đăng ký / đăng nhập riêng.
Toàn bộ auth qua Firebase, sau đó gửi JWT lên backend.

### Chi tiết từng màn hình

| File | Trạng thái | Vấn đề cụ thể |
|------|-----------|---------------|
| `register_screen.dart` | ✅ | Đã có `createUserWithEmailAndPassword` thật |
| `choose_language_screen.dart` | ✅ | Fetch ngôn ngữ từ backend, gọi `initProfile` |
| `login_screen.dart` | ❌ | Nút "Đăng nhập" chỉ `context.go()` thẳng, **không gọi Firebase** |
| `splash_screen.dart` | ❌ | Luôn redirect về `/auth`, không kiểm tra session đã tồn tại |
| Auth Guard (router) | ❌ | Code bị comment trong `app_router.dart`, mọi route đều truy cập được |

### Việc cần làm

```
□ login_screen.dart    → Implement signInWithEmailAndPassword + xử lý lỗi Firebase
□ splash_screen.dart   → Kiểm tra FirebaseAuth.instance.currentUser trước khi redirect
□ app_router.dart      → Bỏ comment auth guard, redirect về /auth nếu chưa đăng nhập
□ Quên mật khẩu        → Nút "Quên mật khẩu?" hiện onTap: () {} — chưa làm gì
```

---

## MODULE 2 — SNAP & LEARN ✅

**Trạng thái tổng: ✅ Hoàn chỉnh nhất trong toàn bộ app**

### Luồng hoạt động (đã đúng)

```
User chụp ảnh
  → Flutter gửi POST /api/v1/snap/analyze (multipart, Idempotency-Key)
  → Backend: YOLO detect object → Gemini AI phân tích ngôn ngữ
  → Trả về SnapAnalysisResponse { vocabItems[], coinsAwarded, snapGroupId }
  → snap_provider.dart map sang MilingoResult[]
  → UI hiển thị (shape MilingoResult không thay đổi)
```

### Tính năng đã có

```
✅ Chụp từ camera
✅ Chọn từ thư viện ảnh
✅ Validate file size (max 5MB)
✅ Idempotency-Key tự động (UUID v4)
✅ Nhiều từ vựng / ảnh (allVocabItems, nextVocabItem, prevVocabItem)
✅ Lưu vào flashcard từ màn hình snap (save_flashcard_sheet.dart)
✅ Loading / error state
```

### Vấn đề nhỏ còn lại

```
□ coinsAwarded được nhận từ backend nhưng KHÔNG được lưu vào user profile
  → Hiển thị xong là mất, không cộng vào tổng xu của user
□ uuid package cần thêm vào pubspec.yaml: uuid: ^4.4.0
```

---

## MODULE 3 — FLASHCARDS ⚠️

**Trạng thái tổng: ⚠️ Backend sẵn sàng, UI vẫn dùng data giả**

Đây là **vấn đề lớn nhất** hiện tại. Có 2 lớp song song không kết nối với nhau.

### Lớp Provider — ✅ Đã kết nối backend

```dart
// flashcard_provider.dart (AsyncNotifier)
✅ build()           → GET /api/v1/decks
✅ addDeck()         → POST /api/v1/decks        + optimistic update
✅ updateDeck()      → PATCH /api/v1/decks/{id}  + optimistic update
✅ deleteDeck()      → DELETE /api/v1/decks/{id} + rollback on error
✅ loadCardsForDeck()→ GET /api/v1/decks/{id}/cards
✅ addCardToDeck()   → POST /api/v1/decks/{id}/cards
✅ deleteCard()      → DELETE /api/v1/decks/{id}/cards/{cardId}
```

### Lớp UI — ❌ Vẫn dùng data hardcode

**`flashcards_screen.dart`** — không gọi `flashcardProvider` lần nào:
```dart
// Tất cả đều hardcode, không lấy từ backend
const _kRecentCards = [
  _RecentCard(imagePath: 'assets/images/dog_beach.png', word: '犬', ...),
  _RecentCard(imagePath: '...', word: 'Dog', ...),
];
const Text('428')         // WORDS LEARNED — giả
const Text('#4th')        // HẠNG — giả
const Text('3,540')       // ĐIỂM — giả
const Text('Chuỗi · 14') // STREAK — giả
const Text('Top 12%')     // giả
```

**`deck_screen.dart`** — toàn bộ từ vựng hardcode trong file:
```dart
// 50+ từ vựng hardcode, không lấy từ API
const _kSampleVocab = <String, List<VocabItem>>{
  'nouns': [VocabItem(word: 'Pen', reading: 'コーヒーカップ...'), ...],
  'nha-bep': [VocabItem(word: 'Knife', ...), ...],
  // ... 8 deck với hàng chục từ hardcode
};
```

### Việc cần làm

```
□ flashcards_screen.dart → ref.watch(flashcardProvider) để lấy decks thật
□ flashcards_screen.dart → Xóa _kRecentCards, thay bằng cards từ provider
□ flashcards_screen.dart → Kết nối số liệu thống kê với API
□ deck_screen.dart       → Xóa _kSampleVocab, gọi loadCardsForDeck(deckId)
□ all_categories_screen  → Hiển thị danh sách decks thật từ provider
□ exam_screen.dart       → Lấy cards từ provider thay vì hardcode
```

---

## MODULE 4 — GAMIFICATION ❌

**Trạng thái tổng: ❌ Toàn bộ frontend xử lý / hardcode**

### Hiện trạng

```dart
// simple_home_screen.dart — header stats
_StatChip(value: '0',  ...)  // 🔥 Streak   — hardcode
_StatChip(value: '10', ...)  // 💎 Đá quý   — hardcode (tại sao lại là 10?)
_StatChip(value: '0',  ...)  // 🏆 Trophy   — hardcode

// Weekly streak row — tính bằng DateTime.now().weekday
// Mỗi ngày trong tuần đều hiển thị là "đã học" (isPast = true)
// nhưng không có dữ liệu thật — chỉ dựa vào ngày hôm nay
final today = DateTime.now().weekday;
```

### Dữ liệu backend đã có nhưng chưa được dùng

```
✅ coinsAwarded   → Backend trả về trong mỗi snap response
                    nhưng frontend KHÔNG lưu lại đâu cả
❌ streak         → Backend chưa có endpoint
❌ totalPoints    → Backend chưa có endpoint
❌ weeklyProgress → Backend chưa có endpoint
```

### Việc cần làm

```
□ Lưu coinsAwarded vào SharedPreferences hoặc tạo endpoint user stats
□ Tạo UserStatsProvider để quản lý xu, streak, điểm
□ Kết nối header stats trong HomeScreen với provider thật
□ Streak cần backend endpoint hoặc logic local với SharedPreferences
```

---

## MODULE 5 — HOME DASHBOARD ❌

**Trạng thái tổng: ❌ Không gọi bất kỳ API nào**

### Hiện trạng

```dart
// simple_home_screen.dart
'0/2 bài học miễn phí hôm nay'  // hardcode — không đếm thật
// Gamification card: "Coming soon!" — chưa làm
// Không import bất kỳ provider nào
```

### Việc cần làm

```
□ Hiển thị tên user từ FirebaseAuth.instance.currentUser?.displayName
□ Kết nối số liệu streak / xu / điểm với UserStatsProvider
□ Đếm số lần snap thật trong ngày (cần backend endpoint hoặc local count)
□ Weekly streak dựa trên dữ liệu thật
```

---

## MODULE 6 — PROFILE 🟡

**Trạng thái tổng: 🟡 Frontend profile đã được nối dữ liệu thật/fallback; backend profile endpoint cần bổ sung để đồng bộ đầy đủ.**

### Đã implement ở frontend

```dart
// profile_screen.dart + profile_provider.dart

✅ UserProfileNotifier đọc GET /api/v1/users/me nếu backend có sẵn
✅ Fallback về FirebaseAuth.instance.currentUser khi backend chưa có endpoint
✅ Hiển thị displayName, email, photoURL/local avatar path
✅ Cho sửa displayName, update FirebaseAuth + PATCH /api/v1/users/me nếu server hỗ trợ
✅ Stats row dùng UserStatsProvider: totalPoints, coins, currentStreak
✅ Language picker dùng supportedLanguagesProvider + fallback local list
✅ Language picker lưu SharedPreferences và thử PATCH /api/v1/users/me
✅ Avatar edit đã tích hợp image_picker và cache local path
✅ Settings sheet đã có: account info, refresh profile/stats, sign out
✅ Proficiency không còn hardcode hoàn toàn:
   - vocabulary progress lấy từ backend nếu có
   - fallback local tính từ saved flashcards hoặc totalPoints
   - pronunciation/grammar chờ backend trả về score thật
✅ Nút nâng cấp trong profile card mở upgrade modal
```

### Còn chưa xong / phụ thuộc backend

```
□ Backend chưa chắc đã có GET /api/v1/users/me
□ Backend chưa chắc đã có PATCH /api/v1/users/me
□ Avatar hiện chỉ cache local file path; cần upload endpoint/storage URL để đồng bộ nhiều thiết bị
□ Proficiency pronunciation/grammar cần backend tính toán từ dữ liệu học thật
□ Tab "Thành tích" vẫn là placeholder
□ Tab "Xếp hạng" vẫn là placeholder, phụ thuộc Module 7
□ Premium vẫn chỉ là UI modal, phụ thuộc Module 8
```

### Backend cần trả về để khớp UI hiện tại

#### GET `/api/v1/users/me`

Frontend đang map cả camelCase và snake_case, nhưng backend nên chuẩn hóa camelCase:

```json
{
  "status": "success",
  "data": {
    "id": "firebase_uid",
    "displayName": "Nguyen Van A",
    "email": "user@example.com",
    "photoUrl": "https://cdn.example.com/avatars/firebase_uid.jpg",
    "nativeLanguage": "vi",
    "targetLanguage": "en",
    "cefrLevel": "A1",
    "isPremium": false,
    "planName": "Miễn phí",
    "proficiency": {
      "vocabulary": 0.42,
      "pronunciation": 0.18,
      "grammar": 0.25
    }
  }
}
```

Field rules:

```
displayName: string, required, fallback từ Firebase Auth nếu rỗng
email: string, required
photoUrl: string|null, URL public; không trả local file path
nativeLanguage: string, ví dụ "vi"
targetLanguage: string, ví dụ "en"
cefrLevel: string, ví dụ "A1", "A2", "B1"
isPremium: bool
planName: string|null, ví dụ "Miễn phí", "Premium"
proficiency.vocabulary/pronunciation/grammar: number 0..1 hoặc 0..100 đều đọc được, khuyến nghị 0..1
```

#### PATCH `/api/v1/users/me`

Request body cho các field có thể sửa:

```json
{
  "displayName": "Nguyen Van A",
  "nativeLanguage": "vi",
  "targetLanguage": "ja",
  "photoUrl": "https://cdn.example.com/avatars/firebase_uid.jpg"
}
```

Backend nên:

```
□ Cho phép gửi partial body; field nào thiếu thì giữ nguyên
□ Validate displayName length 1..80
□ Validate nativeLanguage/targetLanguage nằm trong supported languages
□ Return lại cùng shape với GET /api/v1/users/me sau khi update
□ Nếu photoUrl được dùng, chỉ nhận URL đã upload lên storage/CDN, không nhận local path
```

#### Avatar upload cần thêm

UI hiện chỉ chọn ảnh bằng `image_picker` và lưu local path. Để đồng bộ thật, backend cần một trong hai hướng:

```
Option A:
POST /api/v1/users/me/avatar multipart image
→ upload Firebase Storage / Cloud Storage
→ update users/{uid}.photo_url
→ return UserProfileResponse

Option B:
Frontend upload trực tiếp Firebase Storage
→ lấy download URL
→ PATCH /api/v1/users/me { photoUrl }
```

Khuyến nghị Option A để backend kiểm soát size, content type, quota và URL.

---

## MODULE 7 — LEADERBOARD ❌

**Trạng thái tổng: ❌ Chưa làm gì**

```dart
// leaderboard_screen.dart
const Scaffold(
  body: Center(child: Text('Leaderboard Screen - TODO')),
);
```

Backend chưa có endpoint leaderboard.

### Việc cần làm

```
□ Backend: tạo GET /api/v1/leaderboard
□ Frontend: xây dựng UI leaderboard từ đầu
□ Kết nối với dữ liệu user thật
```

---

## MODULE 8 — PREMIUM / PAYWALL ❌

**Trạng thái tổng: ❌ UI có, logic không**

### Hiện trạng

```dart
// profile_screen.dart — _UpgradeModal
GestureDetector(
  onTap: () {},  // ← Nút "Nâng cấp lên PRO" không làm gì
  child: Container(...),
)

// Nút "Xem quảng cáo 30s" — cũng không làm gì
```

```dart
// dio_client.dart — DioClient cho PayOS đã có
// Nhưng chưa kết nối với bất kỳ màn hình nào
```

### Việc cần làm

```
□ Tích hợp PayOS flow vào nút "Nâng cấp lên PRO"
□ Tích hợp rewarded ads (xem quảng cáo đổi lượt scan)
□ Backend: endpoint kiểm tra trạng thái subscription
□ Frontend: kiểm tra subscription trước khi cho phép scan
□ Giới hạn 2 lượt scan/ngày cho free user (hiện không enforce)
```

---

## BẢNG TỔNG KẾT — ƯU TIÊN

| # | Module | Trạng thái | Ưu tiên | Lý do |
|---|--------|-----------|---------|-------|
| 1 | **Auth** | ⚠️ 50% | 🔴 Cao | Luồng đăng nhập bị bỏ qua hoàn toàn |
| 2 | **Snap & Learn** | ✅ 95% | 🔴 Cao | Sửa nốt coinsAwarded + uuid |
| 3 | **Flashcards UI** | ⚠️ 30% | 🔴 Cao | Provider xong nhưng UI vẫn dùng data giả |
| 4 | **Gamification** | ❌ 5% | 🟡 Trung | Backend có coins, chưa lưu |
| 5 | **Profile** | 🟡 70% | 🟡 Trung | Frontend đã nối Firebase/stats/language/avatar; backend cần /users/me + avatar upload |
| 6 | **Home Dashboard** | ❌ 10% | 🟡 Trung | Phụ thuộc vào UserStats |
| 7 | **Leaderboard** | ❌ 0% | 🟢 Thấp | Cần backend endpoint trước |
| 8 | **Premium** | ❌ 5% | 🟢 Thấp | PayOS sẵn sàng, cần tích hợp |

---

## LỘ TRÌNH ĐỀ XUẤT

### Giai đoạn 1 — Luồng chính hoạt động (ưu tiên ngay)

```
1. login_screen.dart      → signInWithEmailAndPassword
2. splash_screen.dart     → check Firebase session
3. app_router.dart        → bật auth guard
4. flashcards_screen.dart → đọc từ flashcardProvider
5. deck_screen.dart       → gọi loadCardsForDeck()
6. pubspec.yaml           → thêm uuid: ^4.4.0
```

### Giai đoạn 2 — Dữ liệu thật (sau khi luồng chính xong)

```
7. UserStatsProvider      → quản lý coins, streak, điểm
8. Lưu coinsAwarded       → cộng dồn sau mỗi snap
9. Profile screen         → DONE frontend; backend cần GET/PATCH /users/me + avatar upload
10. Home dashboard        → kết nối với UserStatsProvider
```

### Giai đoạn 3 — Tính năng phụ

```
11. Language picker       → lưu vào SharedPreferences
12. Leaderboard           → sau khi backend có endpoint
13. Premium / PayOS       → tích hợp rewarded ads + subscription
14. Proficiency system    → thiết kế và implement
```

---

## GHI CHÚ KỸ THUẬT

### Packages cần thêm ngay vào `pubspec.yaml`
```yaml
uuid: ^4.4.0              # Đang dùng trong milingo_api_service.dart nhưng chưa khai báo
shared_preferences: ^2.2.3 # Đã có — dùng để lưu stats local
```

### Pattern đúng khi kết nối UI với flashcardProvider
```dart
// ĐÚNG — trong widget
final asyncState = ref.watch(flashcardProvider);
final state = asyncState.valueOrNull ?? FlashcardState(decks: []);

// Hoặc dùng shim (nhanh hơn, không có loading state riêng)
final state = ref.watch(flashcardStateProvider);
```

### Lấy thông tin user từ Firebase (không cần API)
```dart
final user = FirebaseAuth.instance.currentUser;
final name  = user?.displayName ?? 'Người dùng';
final email = user?.email ?? '';
final photo = user?.photoURL; // null nếu chưa set
```
