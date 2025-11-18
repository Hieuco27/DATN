# Giải Thích Chi Tiết: Hệ Thống Thông Báo Call API

Tài liệu này giải thích chi tiết cách hệ thống thông báo trong ứng dụng Flutter gọi API từ UI layer xuống Data layer.

## 📋 Mục Lục

1. [Kiến Trúc Tổng Quan](#kiến-trúc-tổng-quan)
2. [Luồng Dữ Liệu](#luồng-dữ-liệu)
3. [Chi Tiết Từng Layer](#chi-tiết-từng-layer)
4. [Các API Endpoints](#các-api-endpoints)
5. [Ví Dụ Cụ Thể](#ví-dụ-cụ-thể)

---

## 🏗️ Kiến Trúc Tổng Quan

Hệ thống thông báo sử dụng **Clean Architecture** với 3 layer chính:

```
┌─────────────────────────────────────────┐
│         UI Layer (Presentation)          │
│  - NotificationsPage                    │
│  - NotificationDetailPage                │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│      Domain Layer (Repository)          │
│  - NotificationRepository               │
│  - NotificationRepositoryImpl           │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│      Data Layer (Data Source)           │
│  - NotificationRemoteDataSource          │
│  - NotificationRemoteDataSourceImpl      │
│  - NotificationModel                     │
└─────────────────┬───────────────────────┘
                  │
                  ▼
            [Backend API]
```

---

## 🔄 Luồng Dữ Liệu

### Luồng khi User mở trang thông báo:

```
1. User mở NotificationsPage
   ↓
2. initState() gọi _loadNotifications()
   ↓
3. _loadNotifications() gọi _repository.getNotifications()
   ↓
4. Repository gọi remoteDataSource.getNotifications()
   ↓
5. DataSource tạo HTTP request với Dio
   ↓
6. Backend API trả về JSON response
   ↓
7. DataSource parse JSON → NotificationListResponse
   ↓
8. Repository trả về response
   ↓
9. UI nhận response và update state
   ↓
10. Widget rebuild với dữ liệu mới
```

---

## 📦 Chi Tiết Từng Layer

### 1. **UI Layer - NotificationsPage**

**File:** `notifications_page.dart`

#### 1.1. Khởi Tạo Repository

```dart
final NotificationRepositoryImpl _repository = NotificationRepositoryImpl(
  remoteDataSource: NotificationRemoteDataSourceImpl(),
);
```

**Giải thích:**

- Tạo instance của `NotificationRepositoryImpl`
- Inject `NotificationRemoteDataSourceImpl` vào repository
- Repository này sẽ được dùng để gọi tất cả các API

#### 1.2. State Management

```dart
List<NotificationModel> _notifications = [];  // Danh sách thông báo
bool _isLoading = false;                      // Trạng thái loading
bool _hasMore = true;                         // Còn dữ liệu để load thêm?
int _currentPage = 1;                         // Trang hiện tại
final int _limit = 20;                        // Số lượng mỗi trang
String? _selectedType;                        // Filter theo loại
bool? _selectedIsRead;                       // Filter theo trạng thái đọc
```

#### 1.3. Load Danh Sách Thông Báo

```dart
Future<void> _loadNotifications({bool refresh = false}) async {
  // 1. Kiểm tra đang loading thì return
  if (_isLoading) return;

  // 2. Set loading state
  setState(() {
    _isLoading = true;
    if (refresh) {
      _currentPage = 1;
      _notifications = [];
      _hasMore = true;
    }
  });

  try {
    // 3. Lấy access token từ AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated ||
        authState.account.accessToken?.isEmpty == true) {
      throw Exception('User not authenticated');
    }

    // 4. GỌI API QUA REPOSITORY
    final response = await _repository.getNotifications(
      accessToken: authState.account.accessToken!,
      page: _currentPage,
      limit: _limit,
      type: _selectedType,      // Filter: SYSTEM, LOAN_PENDING, etc.
      isRead: _selectedIsRead,  // Filter: true/false/null
    );

    // 5. Xử lý response
    if (mounted) {
      setState(() {
        if (refresh) {
          _notifications = response.data;  // Refresh: thay thế toàn bộ
        } else {
          _notifications.addAll(response.data);  // Load more: thêm vào
        }
        _hasMore = response.data.length == _limit;  // Còn dữ liệu?
        _isLoading = false;
      });
    }
  } catch (e) {
    // 6. Xử lý lỗi
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      NotificationService.showError(
        context,
        message: 'Lỗi tải thông báo: ${e.toString()}',
      );
    }
  }
}
```

**Giải thích từng bước:**

1. **Kiểm tra loading**: Tránh gọi API nhiều lần đồng thời
2. **Set state**: Bật loading indicator
3. **Lấy token**: Từ AuthBloc để authenticate request
4. **Gọi API**: Qua repository với các tham số:
   - `accessToken`: JWT token để xác thực
   - `page`: Số trang (pagination)
   - `limit`: Số lượng mỗi trang (20)
   - `type`: Lọc theo loại (optional)
   - `isRead`: Lọc theo trạng thái đọc (optional)
5. **Xử lý response**:
   - Nếu refresh: thay thế toàn bộ list
   - Nếu load more: thêm vào list hiện có
   - Kiểm tra còn dữ liệu: `_hasMore = response.data.length == _limit`
6. **Error handling**: Hiển thị thông báo lỗi cho user

#### 1.4. Load More (Pagination)

```dart
void _onScroll() {
  // Khi scroll đến 80% chiều cao danh sách
  if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8 &&
      !_isLoading &&
      _hasMore) {
    _loadMore();
  }
}

Future<void> _loadMore() async {
  if (!_hasMore || _isLoading) return;
  _currentPage++;  // Tăng số trang
  await _loadNotifications();  // Load trang tiếp theo
}
```

**Giải thích:**

- Lắng nghe scroll event
- Khi scroll đến 80% → tự động load trang tiếp theo
- Tăng `_currentPage` và gọi lại `_loadNotifications()`

#### 1.5. Đánh Dấu Đã Đọc

```dart
Future<void> _markAllAsRead() async {
  try {
    // 1. Lấy token
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated ||
        authState.account.accessToken?.isEmpty == true) {
      throw Exception('User not authenticated');
    }

    // 2. GỌI API
    final response = await _repository.markAllAsRead(
      accessToken: authState.account.accessToken!,
    );

    // 3. Hiển thị thông báo và refresh
    if (mounted) {
      NotificationService.showSuccess(
        context,
        message: 'Đã đánh dấu ${response.updated} thông báo là đã đọc',
      );
      _loadNotifications(refresh: true);  // Refresh danh sách
    }
  } catch (e) {
    // Error handling
    if (mounted) {
      NotificationService.showError(context, message: 'Lỗi: ${e.toString()}');
    }
  }
}
```

---

### 2. **Domain Layer - Repository**

**File:** `notification_repository_impl.dart`

#### 2.1. Abstract Repository Interface

```dart
abstract class NotificationRepository {
  Future<NotificationListResponse> getNotifications({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  });

  Future<NotificationDetailResponse> getNotificationDetail({
    required String accessToken,
    required int notificationId,
  });

  Future<MarkReadResponse> markAsRead({
    required String accessToken,
    required int notificationId,
  });

  Future<MarkReadResponse> markAsUnread({
    required String accessToken,
    required int notificationId,
  });

  Future<MarkAllReadResponse> markAllAsRead({required String accessToken});
}
```

**Giải thích:**

- Định nghĩa contract (interface) cho repository
- Chỉ định nghĩa method signatures, không có implementation
- Giúp dễ dàng test và thay đổi implementation

#### 2.2. Repository Implementation

```dart
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<NotificationListResponse> getNotifications({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  }) {
    // Chỉ đơn giản delegate cho data source
    return remoteDataSource.getNotifications(
      accessToken: accessToken,
      page: page,
      limit: limit,
      type: type,
      isRead: isRead,
    );
  }

  // ... các methods khác tương tự
}
```

**Giải thích:**

- Repository chỉ là **wrapper** cho DataSource
- Không có business logic phức tạp ở đây
- Có thể thêm caching, error handling, logging ở layer này trong tương lai

---

### 3. **Data Layer - Remote Data Source**

**File:** `notification_remote_data_source.dart`

#### 3.1. Cấu Hình Dio Client

```dart
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  static const String baseUrl = 'https://kltn-2025-ehsx.onrender.com/api';
  static const Duration timeoutDuration = Duration(seconds: 60);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,                    // Base URL của API
      connectTimeout: timeoutDuration,     // Timeout khi kết nối
      receiveTimeout: timeoutDuration,     // Timeout khi nhận dữ liệu
      sendTimeout: timeoutDuration,        // Timeout khi gửi dữ liệu
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
}
```

**Giải thích:**

- **Dio**: HTTP client library cho Flutter (tương tự axios trong JS)
- **BaseOptions**: Cấu hình chung cho tất cả requests
- **baseUrl**: URL gốc, các endpoint sẽ được append vào
- **timeout**: Thời gian chờ tối đa (60 giây)

#### 3.2. GET - Lấy Danh Sách Thông Báo

```dart
@override
Future<NotificationListResponse> getNotifications({
  required String accessToken,
  int page = 1,
  int limit = 20,
  String? type,
  bool? isRead,
}) async {
  try {
    // 1. Tạo query parameters
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    // 2. Thêm filter nếu có
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;  // VD: 'SYSTEM', 'LOAN_PENDING'
    }

    if (isRead != null) {
      queryParams['isRead'] = isRead ? 1 : 0;  // Convert bool → int
    }

    // 3. GỬI HTTP GET REQUEST
    final response = await dio.get(
      '/notifications',                    // Endpoint (sẽ thành: baseUrl + '/notifications')
      queryParameters: queryParams,        // Query params: ?page=1&limit=20&type=SYSTEM
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',  // JWT token trong header
        },
      ),
    );

    // 4. Kiểm tra status code
    if (response.statusCode == 200) {
      // 5. Parse JSON → Model
      return NotificationListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to get notifications: ${response.statusCode}');
    }
  } catch (e) {
    // 6. Xử lý lỗi
    throw Exception('Error getting notifications: $e');
  }
}
```

**Request thực tế được gửi:**

```
GET https://kltn-2025-ehsx.onrender.com/api/notifications?page=1&limit=20&type=SYSTEM&isRead=0
Headers:
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  Content-Type: application/json
  Accept: application/json
```

**Response từ Backend:**

```json
{
  "success": true,
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 12,
    "totalPages": 1
  },
  "data": [
    {
      "notificationID": 101,
      "readerId": 12,
      "type": "SYSTEM",
      "title": "Thông báo bảo trì thư viện",
      "content": "Thư viện đóng cửa vào thứ 7",
      "isRead": 0,
      "priority": "HIGH",
      "created_at": "2025-11-10T08:00:00Z"
    }
  ]
}
```

#### 3.3. GET - Lấy Chi Tiết Thông Báo

```dart
@override
Future<NotificationDetailResponse> getNotificationDetail({
  required String accessToken,
  required int notificationId,
}) async {
  try {
    // GET /notifications/{id}
    final response = await dio.get(
      '/notifications/$notificationId',  // Path parameter
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    if (response.statusCode == 200) {
      return NotificationDetailResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to get notification detail: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error getting notification detail: $e');
  }
}
```

**Request:**

```
GET https://kltn-2025-ehsx.onrender.com/api/notifications/101
Headers:
  Authorization: Bearer {token}
```

#### 3.4. PUT - Đánh Dấu Đã Đọc

```dart
@override
Future<MarkReadResponse> markAsRead({
  required String accessToken,
  required int notificationId,
}) async {
  try {
    // PUT /notifications/{id}/mark-read
    final response = await dio.put(
      '/notifications/$notificationId/mark-read',
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    if (response.statusCode == 200) {
      // Parse response
      return MarkReadResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to mark as read: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error marking as read: $e');
  }
}
```

**Request:**

```
PUT https://kltn-2025-ehsx.onrender.com/api/notifications/101/mark-read
Headers:
  Authorization: Bearer {token}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "notificationID": 101,
    "isRead": 1,
    "readAt": "2025-11-11T09:12:00Z"
  }
}
```

#### 3.5. PUT - Đánh Dấu Tất Cả Đã Đọc

```dart
@override
Future<MarkAllReadResponse> markAllAsRead({
  required String accessToken,
}) async {
  try {
    // PUT /notifications/mark-all-read
    final response = await dio.put(
      '/notifications/mark-all-read',
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    if (response.statusCode == 200) {
      return MarkAllReadResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to mark all as read: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error marking all as read: $e');
  }
}
```

**Request:**

```
PUT https://kltn-2025-ehsx.onrender.com/api/notifications/mark-all-read
Headers:
  Authorization: Bearer {token}
```

**Response:**

```json
{
  "success": true,
  "updated": 8
}
```

---

### 4. **Model Layer - Data Parsing**

**File:** `notification_model.dart`

#### 4.1. NotificationModel

```dart
class NotificationModel {
  final int notificationID;
  final int readerId;
  final String type;
  final String title;
  final String content;
  final bool isRead;
  final String priority;
  final DateTime? readAt;
  final DateTime createdAt;

  // Constructor
  NotificationModel({...});

  // Parse từ JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationID: json['notificationID'] as int,
      readerId: json['readerId'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      isRead: (json['isRead'] as int? ?? 0) == 1,  // Convert int → bool
      priority: json['priority'] as String,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)  // Parse ISO string → DateTime
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
```

**Giải thích:**

- **fromJson**: Factory constructor để parse JSON từ API
- **Type conversion**:
  - `isRead`: Backend trả về `int` (0/1), convert sang `bool`
  - `readAt`, `createdAt`: Backend trả về ISO string, parse sang `DateTime`

#### 4.2. NotificationListResponse

```dart
class NotificationListResponse {
  final bool success;
  final PaginationInfo? pagination;
  final List<NotificationModel> data;

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      success: json['success'] == true,
      pagination: json['pagination'] != null
          ? PaginationInfo.fromJson(json['pagination'])
          : null,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),  // Parse từng item trong array
    );
  }
}
```

**Giải thích:**

- Parse response từ API
- Convert array `data` thành `List<NotificationModel>`
- Parse `pagination` info nếu có

---

## 🔌 Các API Endpoints

### 1. GET `/api/notifications`

**Mô tả:** Lấy danh sách thông báo (có phân trang và filter)

**Query Parameters:**

- `page` (int): Số trang (default: 1)
- `limit` (int): Số lượng mỗi trang (default: 20)
- `type` (string, optional): Lọc theo loại (SYSTEM, LOAN_PENDING, etc.)
- `isRead` (int, optional): Lọc theo trạng thái (0 = chưa đọc, 1 = đã đọc)

**Headers:**

```
Authorization: Bearer {access_token}
```

**Response:**

```json
{
  "success": true,
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 12,
    "totalPages": 1
  },
  "data": [...]
}
```

### 2. GET `/api/notifications/:id`

**Mô tả:** Lấy chi tiết 1 thông báo

**Path Parameters:**

- `id` (int): ID của thông báo

**Response:**

```json
{
  "success": true,
  "data": {
    "notificationID": 101,
    "readerId": 12,
    "type": "SYSTEM",
    "title": "...",
    "content": "...",
    "isRead": 0,
    "readAt": null,
    "created_at": "2025-11-10T08:00:00Z"
  }
}
```

### 3. PUT `/api/notifications/:id/mark-read`

**Mô tả:** Đánh dấu 1 thông báo là đã đọc

**Response:**

```json
{
  "success": true,
  "data": {
    "notificationID": 101,
    "isRead": 1,
    "readAt": "2025-11-11T09:12:00Z"
  }
}
```

### 4. PUT `/api/notifications/:id/mark-unread`

**Mô tả:** Đánh dấu 1 thông báo là chưa đọc

### 5. PUT `/api/notifications/mark-all-read`

**Mô tả:** Đánh dấu tất cả thông báo là đã đọc

**Response:**

```json
{
  "success": true,
  "updated": 8
}
```

---

## 📝 Ví Dụ Cụ Thể

### Ví Dụ 1: User mở trang thông báo

```
1. User click vào icon thông báo trong ProfilePage
   ↓
2. Navigator.push → NotificationsPage
   ↓
3. initState() được gọi
   ↓
4. _loadNotifications() được gọi
   ↓
5. Lấy accessToken từ AuthBloc
   ↓
6. Gọi _repository.getNotifications(
     accessToken: "eyJhbGc...",
     page: 1,
     limit: 20,
     type: null,
     isRead: null
   )
   ↓
7. Repository delegate cho remoteDataSource.getNotifications()
   ↓
8. DataSource tạo Dio request:
   GET https://kltn-2025-ehsx.onrender.com/api/notifications?page=1&limit=20
   Headers: Authorization: Bearer eyJhbGc...
   ↓
9. Backend xử lý và trả về JSON
   ↓
10. DataSource parse JSON → NotificationListResponse
   ↓
11. Response được trả về qua Repository → UI
   ↓
12. UI update state: _notifications = response.data
   ↓
13. Widget rebuild và hiển thị danh sách thông báo
```

### Ví Dụ 2: User click vào 1 thông báo

```
1. User click vào notification item
   ↓
2. onTap() được gọi
   ↓
3. Kiểm tra: if (!notification.isRead)
   ↓
4. Gọi API markAsRead():
   PUT /api/notifications/101/mark-read
   ↓
5. Backend update isRead = true, readAt = now
   ↓
6. Response trả về: { success: true, data: {...} }
   ↓
7. UI update local state: notification.copyWith(isRead: true)
   ↓
8. Navigate đến NotificationDetailPage
   ↓
9. NotificationDetailPage tự động load chi tiết
```

### Ví Dụ 3: User scroll để load more

```
1. User scroll xuống danh sách
   ↓
2. _onScroll() được trigger
   ↓
3. Kiểm tra: scroll >= 80% && !_isLoading && _hasMore
   ↓
4. Gọi _loadMore()
   ↓
5. _currentPage++ (từ 1 → 2)
   ↓
6. Gọi lại _loadNotifications()
   ↓
7. API request: GET /api/notifications?page=2&limit=20
   ↓
8. Response trả về 20 items mới
   ↓
9. UI append vào list: _notifications.addAll(response.data)
   ↓
10. Widget rebuild với danh sách dài hơn
```

---

## 🔍 Các Điểm Quan Trọng

### 1. **Error Handling**

Mỗi API call đều có try-catch:

```dart
try {
  // API call
} catch (e) {
  // Hiển thị lỗi cho user
  NotificationService.showError(context, message: 'Lỗi: ${e.toString()}');
}
```

### 2. **Authentication**

Tất cả API calls đều cần access token:

```dart
final authState = context.read<AuthBloc>().state;
if (authState is! AuthAuthenticated ||
    authState.account.accessToken?.isEmpty == true) {
  throw Exception('User not authenticated');
}
```

### 3. **State Management**

- Sử dụng `setState()` để update UI
- Kiểm tra `mounted` trước khi setState để tránh lỗi khi widget đã dispose

### 4. **Pagination**

- Load từng trang (20 items/trang)
- Tự động load more khi scroll đến 80%
- Kiểm tra `_hasMore` để biết còn dữ liệu không

### 5. **Type Safety**

- Sử dụng strong typing với Dart
- Parse JSON một cách an toàn với type casting
- Handle null values với null safety

---

## 🎯 Tóm Tắt

1. **UI Layer** (NotificationsPage):

   - Quản lý state và UI
   - Gọi repository methods
   - Xử lý user interactions

2. **Repository Layer**:

   - Wrapper cho data source
   - Có thể thêm business logic sau

3. **Data Source Layer**:

   - Tạo HTTP requests với Dio
   - Parse JSON responses
   - Handle errors

4. **Model Layer**:
   - Định nghĩa data structures
   - Parse từ JSON
   - Type-safe data handling

**Luồng chính:** UI → Repository → DataSource → API → Parse → UI
