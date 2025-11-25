# Backend API Verification Checklist

## 🎯 Issue: availableCopies không giảm sau khi approve loan

### **Current Behavior:**
```
Frontend reload: ✅ Thành công
API response: availableCopies = 5 (không đổi)
Expected: availableCopies = 4 (giảm 1)
```

---

## 📋 API Spec - Approve Loan

### **Endpoint:**
```
POST /api/loans/{loanSlipId}/approve
```

### **Request Body:**
```json
{
  "librarianId": 1,
  "dueDate": "2025-12-01",
  "pricingMode": "AUTO_MIN",
  "assignments": [
    {
      "loanDetailId": 123,
      "documentCopyId": 456
    }
  ]
}
```

### **Expected Behavior:**

1. **Assign document copies:**
   - LoanDetail.documentCopyId = assignment.documentCopyId
   - DocumentCopy.status = 'RESERVED' hoặc 'BORROWED'

2. **Update document availability:**
   ```sql
   UPDATE documents 
   SET available_copies = available_copies - 1 
   WHERE id = ?
   ```
   **⚠️ CRITICAL: Dòng này có thể đang thiếu!**

3. **Calculate deposit:**
   - Based on pricingMode (AUTO_MIN/AUTO_MAX/MANUAL)

4. **Update loan status:**
   - Loan.status = 'WAITING_FOR_PICKUP'
   - Loan.approvedBy = librarianId
   - Loan.dueDate = dueDate

---

## 🔍 Cần check Backend code

### **File cần tìm:**
- `LoanController.java` / `loan_controller.py` / `loanRoutes.js`
- `LoanService.java` / `loan_service.py` / `loanService.js`
- Method: `approveLoan()` / `approve_loan()` / `approveLoanSlip()`

### **Tìm đoạn code này:**

```java
// Java example
@PostMapping("/api/loans/{loanSlipId}/approve")
public ResponseEntity<?> approveLoan(
    @PathVariable Long loanSlipId,
    @RequestBody ApproveLoanRequest request
) {
    // ... code ...
    
    // ❓ CÓ DÒNG NÀY KHÔNG?
    document.setAvailableCopies(document.getAvailableCopies() - 1);
    documentRepository.save(document);
    
    // ... rest of code ...
}
```

```python
# Python example
def approve_loan(loan_slip_id, request):
    # ... code ...
    
    # ❓ CÓ DÒNG NÀY KHÔNG?
    document.available_copies -= 1
    document.save()
    
    # ... rest of code ...
```

```javascript
// Node.js example
async function approveLoan(loanSlipId, request) {
    // ... code ...
    
    // ❓ CÓ DÒNG NÀY KHÔNG?
    document.availableCopies -= 1;
    await document.save();
    
    // ... rest of code ...
}
```

---

## ✅ Nếu KHÔNG có → Cần thêm code

### **Option 1: Update trong loop assignments**

```javascript
// Khi gán bản sao
for (const assignment of request.assignments) {
    const detail = await LoanDetail.findById(assignment.loanDetailId);
    const copy = await DocumentCopy.findById(assignment.documentCopyId);
    const document = await Document.findById(copy.documentId);
    
    // Gán copy
    detail.documentCopyId = assignment.documentCopyId;
    await detail.save();
    
    // Update copy status
    copy.status = 'RESERVED';
    await copy.save();
    
    // ✅ THÊM: Giảm availableCopies
    document.availableCopies -= 1;
    await document.save();
}
```

### **Option 2: Update sau khi gán xong**

```javascript
// Sau khi assign tất cả copies
const documentIds = [...new Set(assignments.map(a => a.documentId))];

for (const docId of documentIds) {
    const document = await Document.findById(docId);
    const count = assignments.filter(a => a.documentId === docId).length;
    
    // ✅ Giảm theo số lượng đã gán
    document.availableCopies -= count;
    await document.save();
}
```

### **Option 3: Dùng SQL transaction**

```sql
-- Atomic update
BEGIN TRANSACTION;

UPDATE documents 
SET available_copies = available_copies - 
    (SELECT COUNT(*) FROM loan_details 
     WHERE loan_slip_id = ? AND document_id = documents.id)
WHERE id IN (SELECT DISTINCT document_id FROM loan_details WHERE loan_slip_id = ?);

UPDATE loan_slips SET status = 'WAITING_FOR_PICKUP' WHERE id = ?;

COMMIT;
```

---

## 🧪 Test Cases

### **Test 1: Single document loan**

**Setup:**
```sql
-- Initial state
INSERT INTO documents (id, title, total_copies, available_copies) 
VALUES (1, 'Test Book', 5, 5);

INSERT INTO loan_slips (id, status) VALUES (1, 'PENDING');
INSERT INTO loan_details (id, loan_slip_id, document_id) VALUES (1, 1, 1);
```

**Execute:**
```bash
POST /api/loans/1/approve
{
  "librarianId": 1,
  "assignments": [{"loanDetailId": 1, "documentCopyId": 10}]
}
```

**Verify:**
```sql
SELECT available_copies FROM documents WHERE id = 1;
-- Expected: 4
-- Actual: ??? ← CHECK THIS
```

---

### **Test 2: Multiple documents loan**

**Setup:**
```sql
-- 2 documents
INSERT INTO documents (id, title, available_copies) VALUES 
(1, 'Book A', 5),
(2, 'Book B', 3);

-- 1 loan với 2 sách
INSERT INTO loan_slips (id, status) VALUES (2, 'PENDING');
INSERT INTO loan_details (id, loan_slip_id, document_id) VALUES 
(2, 2, 1),
(3, 2, 2);
```

**Execute:**
```bash
POST /api/loans/2/approve
{
  "librarianId": 1,
  "assignments": [
    {"loanDetailId": 2, "documentCopyId": 11},
    {"loanDetailId": 3, "documentCopyId": 21}
  ]
}
```

**Verify:**
```sql
SELECT id, available_copies FROM documents WHERE id IN (1, 2);
-- Expected: 
--   id=1, available_copies=4
--   id=2, available_copies=2
```

---

### **Test 3: Same document, multiple copies**

**Setup:**
```sql
-- User mượn 2 bản của cùng 1 sách
INSERT INTO loan_details (id, loan_slip_id, document_id) VALUES 
(4, 3, 1),
(5, 3, 1);  -- Same document
```

**Execute:**
```bash
POST /api/loans/3/approve
{
  "assignments": [
    {"loanDetailId": 4, "documentCopyId": 12},
    {"loanDetailId": 5, "documentCopyId": 13}
  ]
}
```

**Verify:**
```sql
SELECT available_copies FROM documents WHERE id = 1;
-- Expected: 3 (giảm 2)
```

---

## 🔄 Return Loan - Cũng cần check

### **API Return:**
```
POST /api/loans/{loanSlipId}/return
```

### **Must do:**
```javascript
async function returnLoan(loanSlipId) {
    const loan = await Loan.findById(loanSlipId);
    const details = await LoanDetail.find({ loanSlipId });
    
    for (const detail of details) {
        const copy = await DocumentCopy.findById(detail.documentCopyId);
        const document = await Document.findById(detail.documentId);
        
        // Update copy status
        copy.status = 'AVAILABLE';
        await copy.save();
        
        // ✅ TĂNG lại availableCopies
        document.availableCopies += 1;
        await document.save();
    }
    
    loan.status = 'RETURNED';
    loan.returnDate = new Date();
    await loan.save();
}
```

---

## 📊 Database Schema Check

### **Kiểm tra cấu trúc bảng:**

```sql
-- documents table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'documents';

-- Phải có:
-- available_copies (INTEGER/NUMBER)
-- total_copies (INTEGER/NUMBER)
```

### **Kiểm tra constraints:**

```sql
-- available_copies không được âm
ALTER TABLE documents 
ADD CONSTRAINT check_available_copies 
CHECK (available_copies >= 0);

-- available_copies <= total_copies
ALTER TABLE documents 
ADD CONSTRAINT check_copies_range 
CHECK (available_copies <= total_copies);
```

---

## 🐛 Common Issues

### **Issue 1: Race Condition**

**Problem:** 2 librarians approve cùng lúc

**Fix:** Use transaction + lock
```sql
BEGIN TRANSACTION;

SELECT available_copies FROM documents WHERE id = ? FOR UPDATE;
-- Lock row

UPDATE documents SET available_copies = available_copies - 1 WHERE id = ?;

COMMIT;
```

---

### **Issue 2: Inconsistent Data**

**Problem:** available_copies không khớp với DocumentCopy count

**Fix:** Rebuild từ DocumentCopy
```sql
UPDATE documents 
SET available_copies = (
    SELECT COUNT(*) 
    FROM document_copies 
    WHERE document_id = documents.id 
      AND status = 'AVAILABLE'
);
```

---

### **Issue 3: Trigger conflict**

**Problem:** Có trigger tự động update available_copies nhưng bị lỗi

**Check:**
```sql
-- MySQL
SHOW TRIGGERS FROM database_name;

-- PostgreSQL
SELECT * FROM information_schema.triggers;
```

---

## ✅ Final Checklist

### **Backend Developer:**
- [ ] Tìm file approve loan API
- [ ] Check có update availableCopies không
- [ ] Test với database thật
- [ ] Verify với SQL query trực tiếp
- [ ] Test với multiple documents
- [ ] Test concurrent approvals
- [ ] Implement return loan (tăng lại)
- [ ] Add constraints để validate
- [ ] Test full flow: approve → return

### **Frontend (Already done):**
- [x] Implement RouteAware reload
- [x] Add debug logs
- [x] Pull-to-refresh
- [x] Display calculation (totalCopies - availableCopies)

---

## 🎯 Quick SQL Debug

### **Run this in database:**

```sql
-- Before approve
SELECT 
    d.id,
    d.title,
    d.total_copies,
    d.available_copies,
    COUNT(dc.id) as total_copy_records,
    SUM(CASE WHEN dc.status = 'AVAILABLE' THEN 1 ELSE 0 END) as available_copy_count
FROM documents d
LEFT JOIN document_copies dc ON d.id = dc.document_id
WHERE d.id = 123  -- Replace with actual document ID
GROUP BY d.id;

-- Approve loan

-- After approve
SELECT 
    d.id,
    d.title,
    d.total_copies,
    d.available_copies,  -- ← PHẢI GIẢM
    COUNT(dc.id) as total_copy_records,
    SUM(CASE WHEN dc.status = 'AVAILABLE' THEN 1 ELSE 0 END) as available_copy_count
FROM documents d
LEFT JOIN document_copies dc ON d.id = dc.document_id
WHERE d.id = 123
GROUP BY d.id;
```

**Expected result:**
```
Before: available_copies = 5, available_copy_count = 5
After:  available_copies = 4, available_copy_count = 4
```

**If not matching:**
- available_copies không giảm → Backend chưa update
- available_copy_count giảm nhưng available_copies không → Backend chỉ update DocumentCopy, quên Document

---

**Created:** Nov 20, 2025  
**Priority:** 🔴 HIGH - Blocking feature  
**Status:** ⏳ Awaiting Backend Verification
