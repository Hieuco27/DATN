# 🎯 RemoteDataSource nên dùng Entity hay ResponseModel?

## 📊 Câu trả lời ngắn gọn

### ✅ **RemoteDataSource nên trả về ResponseModel**

**Lý do:**

- RemoteDataSource ở **Data Layer** (outermost layer)
- Nó làm việc trực tiếp với **API response (JSON)**
- Nó đại diện cho **API response format**
- Repository sẽ convert ResponseModel → Entity

## 🏗️ Clean Architecture Flow

```
┌─────────────────────────────────────┐
│   Presentation Layer (Outer)        │
│         ↓                           │
│   Domain Layer (Inner)              │
│         ↓                           │
│   Data Layer (Outer)                │
│   ┌─────────────────────────────┐   │
│   │  Repository                 │   │
│   │  (ResponseModel → Entity)    │   │
│   └─────────────────────────────┘   │
│   ┌─────────────────────────────┐   │
│   │  RemoteDataSource           │   │
│   │  (JSON → ResponseModel)     │   │
│   └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## 📋 Chi tiết từng layer

### 1. RemoteDataSource (Data Layer - Outermost)

```dart
// ✅ ĐÚNG: Trả về ResponseModel
abstract class DocumentRemoteDataSource {
  Future<List<DocumentResponseModel>> getNewDocuments({
    required String accessToken,
    int page = 1,
    int limit = 20,
  });
}

class DocumentRemoteDataSourceImpl implements DocumentRemoteDataSource {
  @override
  Future<List<DocumentResponseModel>> getNewDocuments(...) async {
    // 1. Gọi API
    final response = await http.get(uri, headers: {...});

    // 2. Parse JSON
    final responseData = json.decode(response.body);

    // 3. Convert JSON → ResponseModel
    return responseData['data']
        .map((item) => DocumentResponseModel.fromJson(item))
        .toList();
  }
}
```

**Tại sao ResponseModel?**

- ✅ **Phụ thuộc vào API format** - Đây là đúng vì DataSource ở outermost layer
- ✅ **Parse JSON trực tiếp** - ResponseModel.fromJson() xử lý JSON
- ✅ **Đại diện cho API response** - ResponseModel = hình dạng của API response
- ✅ **Không cần convert** - Trả về đúng format từ API

### 2. Repository (Data Layer - Middle)

```dart
// ✅ ĐÚNG: Nhận ResponseModel, trả về Entity
class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDataSource remoteDataSource;

  @override
  Future<List<DocumentEntity>> getNewDocuments(...) async {
    // 1. Nhận ResponseModel từ DataSource
    final documents = await remoteDataSource.getNewDocuments(...);

    // 2. Convert ResponseModel → Entity
    return documents.map((doc) => doc.toEntity()).toList();
  }
}
```

**Tại sao convert ở đây?**

- ✅ **Boundary layer** - Repository là ranh giới giữa Data và Domain
- ✅ **Convert format** - ResponseModel (API format) → Entity (Business format)
- ✅ **Abstraction** - Che giấu API format khỏi Domain layer

### 3. Presentation Layer (Outermost)

```dart
// ✅ ĐÚNG: Chỉ dùng Entity
class LatestDocumentsPage {
  List<DocumentEntity> _documents = [];

  Future<void> _loadDocuments() async {
    final repository = Provider.of<DocumentRepository>(context, listen: false);
    final documents = await repository.getNewDocuments(...);
    // documents là List<DocumentEntity> ✅
  }
}
```

## ❌ Pattern sai (nếu DataSource trả về Entity)

### Vấn đề 1: Vi phạm Single Responsibility

```dart
// ❌ SAI: DataSource không nên convert
class DocumentRemoteDataSourceImpl {
  Future<List<DocumentEntity>> getNewDocuments(...) async {
    final response = await http.get(uri);
    final responseData = json.decode(response.body);

    // ❌ DataSource đang làm công việc của Repository
    return responseData['data']
        .map((item) => DocumentResponseModel.fromJson(item))
        .map((model) => model.toEntity()) // ❌ Không nên ở đây!
        .toList();
  }
}
```

**Vấn đề:**

- DataSource đang làm 2 việc: parse JSON + convert format
- Khó test vì phải test cả parsing và conversion
- Vi phạm Single Responsibility Principle

### Vấn đề 2: Mất thông tin từ API

```dart
// ❌ Nếu convert ResponseModel → Entity ngay
// → Mất thông tin: categoryName, documentType, etc.
final entity = responseModel.toEntity();
// entity không có categoryName, documentType ❌
```

## ✅ Pattern đúng (hiện tại trong codebase)

### Flow hoàn chỉnh:

```dart
// 1. RemoteDataSource: JSON → ResponseModel
class DocumentRemoteDataSourceImpl {
  Future<List<DocumentResponseModel>> getNewDocuments(...) async {
    final response = await http.get(uri);
    final responseData = json.decode(response.body);
    return responseData['data']
        .map((item) => DocumentResponseModel.fromJson(item))
        .toList(); // ✅ Trả về ResponseModel
  }
}

// 2. Repository: ResponseModel → Entity
class DocumentRepositoryImpl {
  Future<List<DocumentEntity>> getNewDocuments(...) async {
    final documents = await remoteDataSource.getNewDocuments(...);
    return documents.map((doc) => doc.toEntity()).toList(); // ✅ Convert
  }
}

// 3. Presentation: Chỉ dùng Entity
class LatestDocumentsPage {
  List<DocumentEntity> _documents = []; // ✅ Dùng Entity
}
```

## 📊 So sánh

| Layer                | Input         | Output            | Lý do                          |
| -------------------- | ------------- | ----------------- | ------------------------------ |
| **RemoteDataSource** | JSON (API)    | **ResponseModel** | Đại diện cho API format        |
| **Repository**       | ResponseModel | **Entity**        | Convert format, boundary layer |
| **Presentation**     | Entity        | UI                | Chỉ dùng business concept      |

## 🎯 Best Practices

### 1. RemoteDataSource chỉ parse JSON

```dart
// ✅ ĐÚNG
Future<List<DocumentResponseModel>> getNewDocuments(...) {
  final response = await http.get(uri);
  final json = json.decode(response.body);
  return json['data'].map((item) => DocumentResponseModel.fromJson(item)).toList();
}
```

### 2. Repository convert format

```dart
// ✅ ĐÚNG
Future<List<DocumentEntity>> getNewDocuments(...) {
  final models = await remoteDataSource.getNewDocuments(...);
  return models.map((m) => m.toEntity()).toList();
}
```

### 3. Presentation chỉ dùng Entity

```dart
// ✅ ĐÚNG
List<DocumentEntity> _documents = [];
```

## 💡 Kết luận

### RemoteDataSource nên dùng gì?

**✅ ResponseModel** vì:

1. Đại diện cho API response format
2. Parse JSON trực tiếp (fromJson)
3. Ở outermost layer, được phép phụ thuộc vào API format
4. Repository sẽ convert sang Entity

### Quy tắc vàng:

> **RemoteDataSource trả về ResponseModel, Repository convert sang Entity**

### Flow đúng:

```
API (JSON)
  ↓
RemoteDataSource.parse() → ResponseModel
  ↓
Repository.convert() → Entity
  ↓
Presentation.use() → UI ✅
```

## 📝 Checklist

- [ ] RemoteDataSource trả về ResponseModel? ✅
- [ ] Repository convert ResponseModel → Entity? ✅
- [ ] Presentation chỉ dùng Entity? ✅
- [ ] Không convert ở RemoteDataSource? ✅
- [ ] Không dùng ResponseModel ở Presentation? ✅
