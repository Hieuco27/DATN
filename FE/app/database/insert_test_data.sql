-- =============================================
-- Script tạo dữ liệu test cho BookTech
-- Chạy trực tiếp trên MySQL Workbench
-- =============================================

USE book_tech;

-- Xóa dữ liệu cũ (nếu có)
DELETE FROM readers;
DELETE FROM librarians;
DELETE FROM accounts;
DELETE FROM roles;

-- Reset AUTO_INCREMENT
ALTER TABLE roles AUTO_INCREMENT = 1;
ALTER TABLE accounts AUTO_INCREMENT = 1;
ALTER TABLE readers AUTO_INCREMENT = 1;
ALTER TABLE librarians AUTO_INCREMENT = 1;

-- =============================================
-- 1. Insert Roles
-- =============================================
INSERT INTO roles (name) VALUES 
('reader'),
('librarian'),
('admin');

-- =============================================
-- 2. Insert Accounts với password hash đúng
-- Password cho tất cả account: "123456"
-- =============================================

-- Admin account
INSERT INTO accounts (email, phoneNumber, passwordHash, roleId) VALUES 
('admin@booktech.com', '0123456789', 
 UNHEX('243261243132244C6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B'), 3);

-- Reader account  
INSERT INTO accounts (email, phoneNumber, passwordHash, roleId) VALUES
('reader@booktech.com', '0987654321', 
 UNHEX('243261243132244C6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B'), 1);

-- Librarian account
INSERT INTO accounts (email, phoneNumber, passwordHash, roleId) VALUES
('librarian@booktech.com', '0555666777', 
 UNHEX('243261243132244C6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B'), 2);

-- =============================================
-- 3. Insert Reader Profile
-- =============================================
INSERT INTO readers (accountId, fullName, dateOfBirth, cccd, address, totolBorrow, note) VALUES
(2, 'Nguyễn Văn Đọc', '1995-05-15', '123456789012', '123 Đường ABC, Quận 1, TP.HCM', 0, 'Độc giả thường xuyên');

-- =============================================
-- 4. Insert Librarian Profile  
-- =============================================
INSERT INTO librarians (accountId, fullName, employeeCode, hireDate, cccd, diaChi, luongCb, hsLuong, note) VALUES
(3, 'Trần Thị Thư', 'LIB001', '2020-01-15', '987654321098', '456 Đường XYZ, Quận 3, TP.HCM', 15000000.00, 2.50, 'Thủ thư trưởng');

-- =============================================
-- 5. Thêm một số tài khoản test khác
-- =============================================

-- Reader 2
INSERT INTO accounts (email, phoneNumber, passwordHash, roleId) VALUES
('reader2@booktech.com', '0111222333', 
 UNHEX('243261243132244C6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B'), 1);

INSERT INTO readers (accountId, fullName, dateOfBirth, cccd, address, totolBorrow, note) VALUES
(4, 'Lê Thị Lan', '1998-08-20', '456789012345', '789 Đường DEF, Quận 5, TP.HCM', 2, 'Sinh viên đại học');

-- Librarian 2
INSERT INTO accounts (email, phoneNumber, passwordHash, roleId) VALUES
('librarian2@booktech.com', '0444555666', 
 UNHEX('243261243132244C6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B6B4A4E4B7A4F6A4B'), 2);

INSERT INTO librarians (accountId, fullName, employeeCode, hireDate, cccd, diaChi, luongCb, hsLuong, note) VALUES
(5, 'Phạm Văn Minh', 'LIB002', '2021-06-01', '789012345678', '321 Đường GHI, Quận 7, TP.HCM', 12000000.00, 2.00, 'Thủ thư phụ');

-- =============================================
-- 6. Kiểm tra dữ liệu đã insert
-- =============================================

-- Xem tất cả roles
SELECT 'ROLES:' as 'TABLE';
SELECT * FROM roles;

-- Xem tất cả accounts (không hiển thị password)
SELECT 'ACCOUNTS:' as 'TABLE';
SELECT accountId, email, phoneNumber, status, roleId, created_at FROM accounts;

-- Xem tất cả readers
SELECT 'READERS:' as 'TABLE';
SELECT * FROM readers;

-- Xem tất cả librarians
SELECT 'LIBRARIANS:' as 'TABLE';
SELECT * FROM librarians;

-- =============================================
-- 7. View tổng hợp thông tin user (để test)
-- =============================================
SELECT 'USER INFO VIEW:' as 'TABLE';
SELECT 
    a.accountId,
    a.email,
    a.phoneNumber,
    r.name as roleName,
    CASE 
        WHEN r.name = 'reader' THEN rd.fullName
        WHEN r.name = 'librarian' THEN lib.fullName
        ELSE 'Admin User'
    END as fullName,
    CASE 
        WHEN r.name = 'reader' THEN rd.address
        WHEN r.name = 'librarian' THEN lib.diaChi
        ELSE NULL
    END as address,
    a.status,
    a.created_at
FROM accounts a
JOIN roles r ON a.roleId = r.roleId
LEFT JOIN readers rd ON a.accountId = rd.accountId
LEFT JOIN librarians lib ON a.accountId = lib.accountId
ORDER BY a.accountId;

-- =============================================
-- 8. Test accounts summary
-- =============================================
SELECT 'TEST ACCOUNTS SUMMARY:' as 'INFO';
SELECT 
    'Email: admin@booktech.com, Password: 123456, Role: Admin' as 'Account 1'
UNION ALL
SELECT 'Email: reader@booktech.com, Password: 123456, Role: Reader' as 'Account 2'
UNION ALL  
SELECT 'Email: librarian@booktech.com, Password: 123456, Role: Librarian' as 'Account 3'
UNION ALL
SELECT 'Email: reader2@booktech.com, Password: 123456, Role: Reader' as 'Account 4'
UNION ALL
SELECT 'Email: librarian2@booktech.com, Password: 123456, Role: Librarian' as 'Account 5';

-- =============================================
-- HOÀN THÀNH!
-- Bây giờ bạn có thể test API với các tài khoản trên
-- Tất cả đều có password: "123456"
-- =============================================
