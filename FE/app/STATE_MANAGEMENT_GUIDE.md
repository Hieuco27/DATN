# 🎯 State Management trong Dự án - BLoC vs Provider

**Ngày:** 24/11/2025  
**Trạng thái:** Đang sử dụng **HYBRID approach** (BLoC + Provider)

---

## 📊 Tổng quan

Dự án của bạn đang sử dụng **2 patterns** quản lý state:
1. **BLoC (Business Logic Component)** - Cho logic nghiệp vụ phức tạp
2. **Provider (ChangeNotifier)** - Cho UI state đơn giản

### ✅ Hiện trạng trong main.dart

```dart
MultiProvider(
  providers: [
    // 🔷 BLoC - Authentication (Complex business logic)
    BlocProvider(
      create: (context) => AuthBloc(authRepository: authRepository)
        ..add(const AuthCheckLoginStatus()),
    ),
    
    // 🔶 Provider - UI State (Simple state)
    ChangeNotifierProvider(create: (_) => SearchProvider(...)),
    ChangeNotifierProvider(create: (_) => DocumentProvider(...)),
    ChangeNotifierProvider(create: (_) => CartProvider()),
    ChangeNotifierProvider(create: (_) => WishlistProvider()),
    ChangeNotifierProvider(create: (_) => ReadingProvider()),
  ],
)
```

---

## 🔷 BLoC Pattern - Khi nào dùng?

### 📌 Đặc điểm BLoC

**Architecture:**
```
UI → Events → BLoC → States → UI
```

**Flow:**
1. UI trigger **Event** (e.g., `AuthLoginRequested`)
2. BLoC nhận Event, xử lý business logic
3. BLoC emit **State** mới (e.g., `AuthAuthenticated`)
4. UI rebuild theo State mới

### ✅ Dùng BLoC cho:

#### 1. **Complex Business Logic** ✨
- Authentication/Authorization
- Payment processing
- Multi-step workflows
- State machines

#### 2. **Features cần Clean Architecture**
- Tách biệt UI và Business Logic
- Testability cao
- Repository pattern
- Use cases

#### 3. **Async Operations phức tạp**
- Multiple API calls
- Retry logic
- Queue management
- Error handling sophisticated

### 📂 BLoC trong dự án của bạn

#### **AuthBloc** - Authentication Logic

**Location:** `lib/features/auth/presentations/bloc/auth_bloc.dart`

**Events:**
```dart
- AuthLoginRequested        // User click login
- AuthRegisterRequested     // User click register
- AuthLogoutRequested       // User click logout
- AuthTokenRefreshRequested // Token expired
- AuthCheckLoginStatus      // App startup
- AuthClearError           // Clear error state
```

**States:**
```dart
- AuthInitial         // App khởi động
- AuthLoading         // Đang xử lý
- AuthAuthenticated   // Đăng nhập thành công
- AuthError          // Có lỗi xảy ra
- AuthUnauthenticated // Chưa đăng nhập
```

**Code Example:**
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthenticationRepository _authRepository;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;

  AuthBloc({required authRepository})
      : _authRepository = authRepository,
        _loginUseCase = LoginUseCase(authRepository),
        _registerUseCase = RegisterUseCase(authRepository),
        super(const AuthInitial()) {
    
    // Map Events to Handlers
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading()); // 1. Emit loading state
    
    final result = await _loginUseCase(
      LoginParams(email: event.email, password: event.password),
    ); // 2. Execute business logic
    
    if (result.isSuccess) {
      emit(AuthAuthenticated(account: result.value!)); // 3. Emit success
    } else {
      emit(AuthError(message: result.error.message)); // 3. Emit error
    }
  }
}
```

**Sử dụng trong UI:**
```dart
// Trigger event
context.read<AuthBloc>().add(
  AuthLoginRequested(email: email, password: password),
);

// Listen to state
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthError) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
    if (state is AuthAuthenticated) {
      // Navigate to home
      Navigator.pushReplacement(context, ...);
    }
  },
  builder: (context, state) {
    if (state is AuthLoading) {
      return CircularProgressIndicator();
    }
    return LoginForm();
  },
);
```

**✅ Tại sao dùng BLoC cho Auth?**
- ✅ Business logic phức tạp (login, register, token refresh)
- ✅ Clean Architecture (UseCases, Repository)
- ✅ Testability cao (dễ test events & states)
- ✅ Predictable state flow
- ✅ Có retry logic, error handling

---

## 🔶 Provider Pattern - Khi nào dùng?

### 📌 Đặc điểm Provider

**Architecture:**
```
UI → Method Call → Provider → notifyListeners() → UI rebuild
```

**Flow:**
1. UI gọi method của Provider (e.g., `cartProvider.addItem()`)
2. Provider update internal state
3. Provider call `notifyListeners()`
4. UI tự động rebuild

### Dùng Provider cho:

#### 1. **Simple UI State** 🎨
- Cart items
- Favorites/Wishlist
- Search results
- Form state

#### 2. **Local State không cần Clean Architecture**
- UI toggles
- Temporary data
- View state

#### 3. **Shared State giữa widgets**
- Theme
- Locale
- User preferences

### 📂 Providers trong dự án của bạn

#### **1. CartProvider** - Shopping Cart

**Location:** `lib/features/auth/presentations/providers/cart_provider.dart`

**Code:**
```dart
class CartProvider with ChangeNotifier {
  final List<CartItemModel> _items = [];

  // Getters
  List<CartItemModel> get items => List.unmodifiable(_items);
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  
  // Methods
  void addItem(CartItemModel item) {
    final existingIndex = _items.indexWhere(
      (i) => i.documentId == item.documentId,
    );
    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + item.quantity,
      );
    } else {
      _items.add(item);
    }
    notifyListeners(); // ✅ Trigger UI rebuild
  }

  void removeItem(int documentId) {
    _items.removeWhere((item) => item.documentId == documentId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
```

**Sử dụng:**
```dart
// Add item
context.read<CartProvider>().addItem(cartItem);

// Listen to changes
Consumer<CartProvider>(
  builder: (context, cart, child) {
    return Text('Total: ${cart.totalItems}');
  },
);

// Or use context.watch
final cart = context.watch<CartProvider>();
return Text('Total: ${cart.totalItems}');
```

**✅ Tại sao dùng Provider cho Cart?**
- ✅ Simple CRUD operations (add, remove, clear)
- ✅ Pure UI state (không cần API calls phức tạp)
- ✅ Shared state giữa nhiều pages
- ✅ Lightweight, dễ implement

---

#### **2. SearchProvider** - Search State

**Location:** `lib/features/auth/presentations/providers/search_provider.dart`

**Features:**
- Search query management
- Search results caching
- Search history
- Loading state

**Code:**
```dart
class SearchProvider with ChangeNotifier {
  final DocumentRepository repository;
  
  bool _isLoading = false;
  String? _error;
  List<DocumentEntity> _searchResults = [];
  String _currentQuery = '';
  List<String> _searchHistory = [];

  // Getters
  bool get isLoading => _isLoading;
  List<DocumentEntity> get searchResults => _searchResults;
  List<String> get searchHistory => _searchHistory;

  // Search method
  Future<void> searchDocuments(String query, BuildContext context) async {
    _currentQuery = query.trim();
    _isLoading = true;
    _error = null;
    notifyListeners(); // Show loading

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        throw Exception('User not authenticated');
      }

      // API call
      List<DocumentEntity> results = await repository.searchDocuments(
        accessToken: authState.account.accessToken!,
        query: query,
      );

      _searchResults = results;
      _addToSearchHistory(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // Hide loading, show results
    }
  }
}
```

**✅ Tại sao dùng Provider cho Search?**
- ✅ Simple async operations
- ✅ UI state (loading, results, error)
- ✅ Search history (local state)
- ⚠️ **NOTE:** Có thể refactor sang BLoC nếu logic phức tạp hơn

---

#### **3. DocumentProvider** - Document Data Management

**Location:** `lib/features/auth/presentations/providers/document_provider.dart`

**Features:**
- Fetch documents by genre
- Cache management (memory + disk)
- Loading states by genre

**Code:**
```dart
class DocumentProvider with ChangeNotifier {
  final DocumentRepository _documentRepository;
  
  Map<int, List<DocumentEntity>> _documentsByGenre = {};
  Map<int, bool> _isLoadingByGenre = {};

  Future<List<DocumentEntity>> getDocumentsByGenre({
    required String accessToken,
    required int genreId,
    bool useCache = true,
  }) async {
    // 1. Check memory cache
    if (useCache && _documentsByGenre.containsKey(genreId)) {
      return _documentsByGenre[genreId]!;
    }

    // 2. Set loading state
    _isLoadingByGenre[genreId] = true;
    notifyListeners();

    try {
      // 3. Try disk cache
      if (useCache) {
        final cachedDocs = await CacheService.getDocumentsByGenre(genreId);
        if (cachedDocs != null) {
          _documentsByGenre[genreId] = cachedDocs;
          notifyListeners();
          return cachedDocs;
        }
      }

      // 4. Load from server
      final documents = await _documentRepository.getDocumentsByGenre(...);
      _documentsByGenre[genreId] = documents;
      
      // 5. Save to cache
      await CacheService.saveDocumentsByGenre(genreId, documents);
      
      return documents;
    } finally {
      _isLoadingByGenre[genreId] = false;
      notifyListeners();
    }
  }
}
```

**✅ Tại sao dùng Provider cho Documents?**
- ✅ Data fetching with cache
- ✅ Multiple loading states (per genre)
- ⚠️ **WARNING:** Logic đang phức tạp, nên consider refactor sang BLoC

---

#### **4. WishlistProvider & ReadingProvider**

**Simple state management cho:**
- Wishlist: List of favorite documents
- Reading: Current reading state, progress

**Pattern tương tự CartProvider:**
```dart
class WishlistProvider with ChangeNotifier {
  final List<DocumentEntity> _wishlist = [];
  
  void addToWishlist(DocumentEntity doc) {
    _wishlist.add(doc);
    notifyListeners();
  }
  
  void removeFromWishlist(int docId) {
    _wishlist.removeWhere((d) => d.id == docId);
    notifyListeners();
  }
}
```

---

## ⚖️ BLoC vs Provider - Decision Matrix

| Criteria | BLoC | Provider |
|----------|------|----------|
| **Complexity** | High | Low-Medium |
| **Business Logic** | ✅ Complex | ❌ Simple only |
| **Clean Architecture** | ✅ Yes | ❌ No |
| **Testability** | ✅ Excellent | ⚠️ Good |
| **Async Operations** | ✅ Complex flows | ⚠️ Simple only |
| **Boilerplate** | ⚠️ More | ✅ Less |
| **Learning Curve** | ⚠️ Steep | ✅ Easy |
| **State Predictability** | ✅ Very high | ⚠️ Medium |
| **Use Cases** | ✅ Required | ❌ Optional |
| **Repository** | ✅ Required | ⚠️ Can use directly |

---

## 🎯 Khi nào dùng cái gì?

### ✅ Dùng BLoC khi:

1. **Authentication/Authorization**
   ```dart
   ✅ Login, Register, Logout, Token Refresh
   ✅ Multiple states, complex flows
   ✅ Need UseCases, Repository pattern
   ```

2. **Payment/Transaction**
   ```dart
   ✅ Payment processing
   ✅ Multi-step checkout
   ✅ Need rollback logic
   ```

3. **Complex Data Fetching**
   ```dart
   ✅ Pagination + Filtering + Sorting
   ✅ Multiple data sources
   ✅ Offline-first architecture
   ```

4. **State Machines**
   ```dart
   ✅ Booking flow (Draft → Pending → Confirmed → Completed)
   ✅ Order status tracking
   ```

### ✅ Dùng Provider khi:

1. **Simple UI State**
   ```dart
   ✅ Shopping cart
   ✅ Wishlist
   ✅ Search query/results
   ✅ Theme toggle
   ```

2. **Local State**
   ```dart
   ✅ Form validation
   ✅ UI toggles (show/hide)
   ✅ Temporary data
   ```

3. **Shared Widget State**
   ```dart
   ✅ Tab selection
   ✅ Scroll position
   ✅ Expansion state
   ```

---

## 🚨 Issues trong dự án hiện tại

### ⚠️ 1. SearchProvider - Quá phức tạp

**Vấn đề:**
```dart
// SearchProvider đang làm quá nhiều việc:
- API calls với authentication
- Error handling
- Search history persistence
- Filtering with compute (isolate)
```

**Giải pháp:** Nên migrate sang **SearchBloc**
```dart
// Events
SearchQueryChanged(String query)
SearchHistoryRequested()
SearchHistoryCleared()

// States
SearchInitial()
SearchLoading()
SearchSuccess(List<DocumentEntity> results)
SearchError(String message)
```

### ⚠️ 2. DocumentProvider - Quá phức tạp

**Vấn đề:**
```dart
// DocumentProvider đang handle:
- Multiple cache layers (memory + disk)
- Background data refresh
- Genre-specific loading states
```

**Giải pháp:** Consider **DocumentBloc** hoặc ít nhất là tách logic:
```dart
// Tách thành services
class DocumentCacheService {
  Future<List<Doc>> getFromCache(int genreId);
  Future<void> saveToCache(int genreId, List<Doc> docs);
}

// Provider chỉ lo UI state
class DocumentProvider with ChangeNotifier {
  final DocumentCacheService _cacheService;
  final DocumentRepository _repository;
  
  // Simpler, more focused
}
```

### ⚠️ 3. Mixed Responsibilities

**Vấn đề:**
```dart
// SearchProvider truy cập AuthBloc
final authState = context.read<AuthBloc>().state;
```

**Giải pháp:** Inject token qua constructor hoặc method parameter:
```dart
Future<void> searchDocuments({
  required String query,
  required String accessToken, // ✅ Explicit dependency
}) async {
  // No need to read AuthBloc
}
```

---

## 📋 Best Practices

### 1. **Separation of Concerns**

```dart
❌ BAD - Provider làm quá nhiều việc
class MyProvider with ChangeNotifier {
  Future<void> fetchData() async {
    // API call
    // Transform data
    // Cache data
    // Update UI
  }
}

✅ GOOD - Tách logic ra services
class DataService {
  Future<Data> fetchFromAPI();
}

class CacheService {
  Future<void> cache(Data data);
}

class MyProvider with ChangeNotifier {
  final DataService _dataService;
  final CacheService _cacheService;
  
  Future<void> fetchData() async {
    final data = await _dataService.fetchFromAPI();
    await _cacheService.cache(data);
    _data = data;
    notifyListeners();
  }
}
```

### 2. **Error Handling**

```dart
✅ BLoC - Type-safe error states
sealed class MyState {}
class MyLoading extends MyState {}
class MySuccess extends MyState { final Data data; }
class MyError extends MyState { final String message; }

⚠️ Provider - Manual error handling
class MyProvider with ChangeNotifier {
  String? _error;
  bool _isLoading = false;
  
  // Need to manually check _error != null
}
```

### 3. **Testing**

```dart
✅ BLoC - Easy to test
test('emits AuthAuthenticated when login succeeds', () {
  blocTest<AuthBloc, AuthState>(
    'login success',
    build: () => AuthBloc(mockRepository),
    act: (bloc) => bloc.add(AuthLoginRequested(...)),
    expect: () => [AuthLoading(), AuthAuthenticated(...)],
  );
});

⚠️ Provider - More setup required
test('cart adds item correctly', () {
  final provider = CartProvider();
  provider.addItem(item);
  expect(provider.items.length, 1);
});
```

---

## 🔄 Migration Plan (Optional)

Nếu muốn cải thiện architecture:

### Phase 1: Keep current (ưu tiên)
- ✅ AuthBloc: Keep as-is
- ✅ CartProvider: Keep (simple enough)
- ✅ WishlistProvider: Keep
- ✅ ReadingProvider: Keep

### Phase 2: Refactor complex Providers (tuỳ chọn)
- ⚠️ SearchProvider → SearchBloc
- ⚠️ DocumentProvider → DocumentBloc hoặc tách services

### Phase 3: Add ProfileBloc (nếu cần)
- User profile management
- Settings management

---

## 📚 Tài liệu tham khảo

1. **BLoC Pattern:**
   - https://bloclibrary.dev/
   - Event-driven, predictable state management
   
2. **Provider Pattern:**
   - https://pub.dev/packages/provider
   - Simple, InheritedWidget-based state management

3. **When to use what:**
   - BLoC: Complex business logic, Clean Architecture
   - Provider: Simple UI state, shared widget state

---

## 💡 Recommendations

### ✅ Current approach is OK for:
- Learning Flutter state management
- Medium-sized projects
- Mixed complexity requirements

### 🔄 Consider refactoring if:
- Team is growing
- More complex features coming
- Need better testability
- Code is becoming hard to maintain

### 🎯 My suggestion:
**Keep hybrid approach, but:**
1. ✅ Use BLoC for **business logic** (Auth, Payment, etc.)
2. ✅ Use Provider for **simple UI state** (Cart, Wishlist)
3. ⚠️ Refactor SearchProvider & DocumentProvider (too complex)
4. ✅ Add services layer to reduce Provider complexity

---

**Kết luận:** Dự án đang dùng **hybrid approach hợp lý**, nhưng cần refactor một số Providers quá phức tạp để maintain được lâu dài.
