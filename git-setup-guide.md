# Hướng dẫn thiết lập và đẩy code lên Git

## 1. Cấu hình thông tin cá nhân
```bash
git config --global user.name "Tên của bạn"
git config --global user.email "email@example.com"
```

## 2. Kiểm tra repository hiện tại
```bash
cd d:\HOC_NAM_BON\HK1\KLTN-2025
git status
git remote -v
```

## 3. Nếu đã có remote repository trước đó

### Nếu remote vẫn còn:
```bash
# Thêm tất cả file thay đổi
git add .

# Commit với message
git commit -m "Update: Mô tả thay đổi"

# Đẩy lên branch chính (thường là main hoặc master)
git push origin main
# hoặc
git push origin master
```

### Nếu mất kết nối remote:
```bash
# Thêm lại remote (thay URL bằng URL repository của bạn)
git remote add origin https://github.com/username/repository.git

# Hoặc nếu đã có remote nhưng sai URL
git remote set-url origin https://github.com/username/repository.git

# Sau đó push
git push -u origin main
```

## 4. Nếu chưa có repository Git

### Khởi tạo Git repository mới:
```bash
# Khởi tạo Git trong thư mục dự án
git init

# Thêm tất cả file
git add .

# Commit đầu tiên
git commit -m "Initial commit"

# Tạo repository mới trên GitHub/GitLab, sau đó thêm remote
git remote add origin https://github.com/username/repository.git

# Đẩy code lên (lần đầu)
git branch -M main
git push -u origin main
```

## 5. Các lệnh Git thường dùng

```bash
# Xem trạng thái
git status

# Xem lịch sử commit
git log --oneline

# Xem các remote
git remote -v

# Pull code mới nhất từ remote
git pull origin main

# Tạo branch mới
git checkout -b ten-branch-moi

# Chuyển branch
git checkout ten-branch

# Push branch mới
git push -u origin ten-branch
```

## 6. Xử lý xung đột khi push

Nếu gặp lỗi khi push (ví dụ: remote có code mới hơn):
```bash
# Pull code mới nhất trước
git pull origin main --rebase

# Hoặc merge
git pull origin main

# Sau đó push lại
git push origin main
```

## 7. Lưu ý quan trọng

- **Luôn pull trước khi push** để tránh xung đột
- **Commit thường xuyên** với message rõ ràng
- **Không commit file nhạy cảm** (API keys, passwords, etc.)
- **Sử dụng .gitignore** để loại trừ file không cần thiết (node_modules, build files, etc.)

## 8. File .gitignore cho Flutter project

Đảm bảo file `.gitignore` có các dòng sau:
```
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
*.iml
*.lock

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
```
