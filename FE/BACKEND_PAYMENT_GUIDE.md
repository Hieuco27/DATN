# Hướng dẫn tích hợp thanh toán cho Backend

## 1. VNPay - Cổng thanh toán phổ biến nhất

### Tài liệu chính thức:

- **Sandbox**: https://sandbox.vnpayment.vn/apis/
- **Tài liệu API**: https://sandbox.vnpayment.vn/apis/docs/
- **SDK Node.js**: `npm install vnpay`

### Cài đặt:

```bash
npm install vnpay
# hoặc
yarn add vnpay
```

### Ví dụ code Node.js/Express:

```javascript
const vnpay = require("vnpay");
const crypto = require("crypto");

// Cấu hình VNPay
const vnpayConfig = {
  tmnCode: "YOUR_TMN_CODE", // Mã website của bạn
  secretKey: "YOUR_SECRET_KEY", // Secret key từ VNPay
  vnpUrl: "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html", // Sandbox URL
  returnUrl: "https://yourdomain.com/payment/return", // URL callback
};

// Tạo payment URL với QR code
function createPaymentUrl(orderId, amount, orderDescription) {
  const date = new Date();
  const createDate = date.toISOString().replace(/[-:]/g, "").split(".")[0];
  const expireDate = new Date(date.getTime() + 15 * 60 * 1000) // 15 phút
    .toISOString()
    .replace(/[-:]/g, "")
    .split(".")[0];

  const vnpParams = {
    vnp_Version: "2.1.0",
    vnp_Command: "pay",
    vnp_TmnCode: vnpayConfig.tmnCode,
    vnp_Amount: amount * 100, // VNPay yêu cầu số tiền nhân 100
    vnp_CurrCode: "VND",
    vnp_TxnRef: orderId,
    vnp_OrderInfo: orderDescription,
    vnp_OrderType: "other",
    vnp_Locale: "vn",
    vnp_ReturnUrl: vnpayConfig.returnUrl,
    vnp_IpAddr: "127.0.0.1",
    vnp_CreateDate: createDate,
    vnp_ExpireDate: expireDate,
  };

  // Sắp xếp params và tạo secure hash
  const sortedParams = Object.keys(vnpParams)
    .sort()
    .reduce((result, key) => {
      result[key] = vnpParams[key];
      return result;
    }, {});

  const signData = new URLSearchParams(sortedParams).toString();
  const hmac = crypto.createHmac("sha512", vnpayConfig.secretKey);
  const signed = hmac.update(signData, "utf-8").digest("hex");

  sortedParams["vnp_SecureHash"] = signed;

  const paymentUrl =
    vnpayConfig.vnpUrl + "?" + new URLSearchParams(sortedParams).toString();

  return paymentUrl;
}

// API endpoint tạo payment
app.post("/api/membership/payment", async (req, res) => {
  const { cardTypeId, paymentMethod } = req.body;
  const userId = req.user.id; // Từ JWT token

  // Lấy thông tin card type
  const cardType = await CardType.findById(cardTypeId);
  const amount = parseFloat(cardType.price);

  // Tạo order ID
  const orderId = `MEM${Date.now()}${userId}`;

  if (paymentMethod === "VNPAY") {
    const paymentUrl = createPaymentUrl(
      orderId,
      amount,
      `Thanh toan the thanh vien ${cardType.typeName}`
    );

    // Lưu transaction vào database
    await Transaction.create({
      userId,
      orderId,
      cardTypeId,
      amount,
      paymentMethod: "VNPAY",
      status: "PENDING",
    });

    return res.json({
      success: true,
      paymentUrl,
      transactionId: orderId,
      amount: amount.toString(),
    });
  }

  // Xử lý các payment method khác...
});
```

### Tạo QR Code từ Payment URL:

```javascript
const QRCode = require("qrcode");

// Tạo QR code từ payment URL
async function generateQRCode(paymentUrl) {
  try {
    const qrCodeDataURL = await QRCode.toDataURL(paymentUrl);
    return qrCodeDataURL; // Base64 image
  } catch (err) {
    console.error(err);
    throw err;
  }
}

// Hoặc tạo QR code file
async function generateQRCodeFile(paymentUrl, filePath) {
  await QRCode.toFile(filePath, paymentUrl);
}
```

---

## 2. MoMo - Ví điện tử

### Tài liệu:

- **Developer Portal**: https://developers.momo.vn/
- **API Documentation**: https://developers.momo.vn/v3/vi/docs/payment/api/quick-pay/

### Cài đặt:

```bash
npm install momo-payment
```

### Ví dụ code:

```javascript
const momo = require("momo-payment");

const momoConfig = {
  partnerCode: "YOUR_PARTNER_CODE",
  accessKey: "YOUR_ACCESS_KEY",
  secretKey: "YOUR_SECRET_KEY",
  environment: "sandbox", // hoặc 'production'
};

// Tạo payment request
async function createMoMoPayment(orderId, amount, orderInfo) {
  const requestId = orderId;
  const orderIdMoMo = orderId;
  const requestType = "captureWallet";
  const extraData = "";

  const rawSignature = `accessKey=${momoConfig.accessKey}&amount=${amount}&extraData=${extraData}&ipnUrl=${ipnUrl}&orderId=${orderIdMoMo}&orderInfo=${orderInfo}&partnerCode=${momoConfig.partnerCode}&redirectUrl=${redirectUrl}&requestId=${requestId}&requestType=${requestType}`;

  const signature = crypto
    .createHmac("sha256", momoConfig.secretKey)
    .update(rawSignature)
    .digest("hex");

  const requestBody = {
    partnerCode: momoConfig.partnerCode,
    partnerName: "Your Company Name",
    storeId: "Your Store ID",
    requestId: requestId,
    amount: amount,
    orderId: orderIdMoMo,
    orderInfo: orderInfo,
    redirectUrl: redirectUrl,
    ipnUrl: ipnUrl,
    lang: "vi",
    extraData: extraData,
    requestType: requestType,
    signature: signature,
  };

  const response = await axios.post(
    "https://test-payment.momo.vn/v2/gateway/api/create",
    requestBody
  );

  return response.data.payUrl; // URL để mở MoMo app hoặc web
}
```

---

## 3. VietQR - QR Code chuyển khoản ngân hàng

### Tài liệu:

- **API Documentation**: https://api.vietqr.io/
- **Website**: https://www.vietqr.io/

### Ưu điểm:

- Miễn phí
- Tạo QR code theo chuẩn VietQR
- Người dùng quét bằng app ngân hàng bất kỳ

### Ví dụ code:

```javascript
const axios = require("axios");
const QRCode = require("qrcode");

// Tạo VietQR
async function createVietQR(bankCode, accountNumber, amount, description) {
  const apiUrl = "https://api.vietqr.io/v2/generate";

  const requestData = {
    accountNo: accountNumber,
    accountName: "TEN CONG TY",
    acqId: bankCode, // Mã ngân hàng (970415, 970422, etc.)
    addInfo: description,
    amount: amount,
    template: "compact2", // hoặc 'compact', 'qr_only'
  };

  try {
    const response = await axios.post(apiUrl, requestData, {
      headers: {
        "x-client-id": "YOUR_CLIENT_ID", // Đăng ký tại vietqr.io
        "x-api-key": "YOUR_API_KEY",
      },
    });

    // Response có chứa QR code data URL
    return {
      qrDataURL: response.data.data.qrDataURL,
      qrCode: response.data.data.qrCode, // String QR code để tạo image
    };
  } catch (error) {
    console.error("VietQR Error:", error);
    throw error;
  }
}

// Sử dụng
app.post("/api/membership/payment", async (req, res) => {
  const { cardTypeId, paymentMethod } = req.body;

  if (paymentMethod === "BANK_TRANSFER") {
    const cardType = await CardType.findById(cardTypeId);
    const amount = parseFloat(cardType.price);

    const qrData = await createVietQR(
      "970415", // Ví dụ: Vietcombank
      "1234567890", // Số tài khoản của bạn
      amount,
      `Thanh toan the thanh vien ${cardType.typeName}`
    );

    return res.json({
      success: true,
      qrCode: qrData.qrDataURL, // Base64 image
      qrCodeString: qrData.qrCode, // String để tạo QR code
      amount: amount.toString(),
      accountNumber: "1234567890",
      accountName: "TEN CONG TY",
      bankName: "Vietcombank",
    });
  }
});
```

---

## 4. Thư viện tạo QR Code

### Cài đặt:

```bash
npm install qrcode
# hoặc
npm install qrcode-svg
```

### Ví dụ sử dụng:

```javascript
const QRCode = require("qrcode");

// Tạo QR code từ text/URL
async function generateQR(text) {
  // Tạo data URL (base64)
  const dataURL = await QRCode.toDataURL(text, {
    width: 300,
    margin: 2,
    color: {
      dark: "#000000",
      light: "#FFFFFF",
    },
  });

  // Hoặc tạo file
  await QRCode.toFile("qr.png", text);

  // Hoặc tạo SVG
  const svg = await QRCode.toString(text, { type: "svg" });

  return dataURL;
}
```

---

## 5. Tích hợp vào Backend API

### Cấu trúc API endpoint:

```javascript
// POST /api/membership/payment
app.post("/api/membership/payment", authenticateToken, async (req, res) => {
  try {
    const { cardTypeId, paymentMethod } = req.body;
    const userId = req.user.id;

    // Validate
    const cardType = await CardType.findById(cardTypeId);
    if (!cardType) {
      return res.status(400).json({ message: "Loại thẻ không tồn tại" });
    }

    const amount = parseFloat(cardType.price);
    const orderId = `MEM${Date.now()}${userId}`;

    let paymentResponse = {};

    switch (paymentMethod) {
      case "VNPAY":
        const vnpayUrl = createPaymentUrl(
          orderId,
          amount,
          `The ${cardType.typeName}`
        );
        const qrCode = await generateQRCode(vnpayUrl);

        paymentResponse = {
          paymentUrl: vnpayUrl,
          qrCode: qrCode, // Base64 image
          transactionId: orderId,
        };
        break;

      case "MOMO":
        const momoUrl = await createMoMoPayment(
          orderId,
          amount,
          `The ${cardType.typeName}`
        );
        const momoQR = await generateQRCode(momoUrl);

        paymentResponse = {
          paymentUrl: momoUrl,
          qrCode: momoQR,
          transactionId: orderId,
        };
        break;

      case "BANK_TRANSFER":
        const vietQR = await createVietQR(
          "970415",
          "YOUR_ACCOUNT",
          amount,
          `The ${cardType.typeName} - ${orderId}`
        );

        paymentResponse = {
          qrCode: vietQR.qrDataURL,
          accountNumber: "YOUR_ACCOUNT",
          accountName: "YOUR_NAME",
          bankName: "Vietcombank",
          transactionId: orderId,
        };
        break;

      case "CASH":
        // Thanh toán tiền mặt - tạo member card luôn
        const memberCard = await createMemberCard(userId, cardTypeId);
        return res.json({
          success: true,
          message: "Vui lòng thanh toán tại thư viện",
          memberCard,
        });
    }

    // Lưu transaction
    await Transaction.create({
      userId,
      orderId,
      cardTypeId,
      amount,
      paymentMethod,
      status: "PENDING",
    });

    res.json({
      success: true,
      ...paymentResponse,
      amount: amount.toString(),
    });
  } catch (error) {
    console.error("Payment Error:", error);
    res.status(500).json({ message: error.message });
  }
});

// POST /api/membership/member-cards (sau khi thanh toán thành công)
app.post(
  "/api/membership/member-cards",
  authenticateToken,
  async (req, res) => {
    try {
      const { cardTypeId, transactionId } = req.body;
      const userId = req.user.id;

      // Verify transaction
      const transaction = await Transaction.findOne({
        orderId: transactionId,
        userId,
        status: "COMPLETED", // Đã thanh toán thành công
      });

      if (!transaction) {
        return res.status(400).json({ message: "Giao dịch không hợp lệ" });
      }

      // Tạo member card
      const memberCard = await createMemberCard(userId, cardTypeId);

      res.json({
        success: true,
        memberCard,
      });
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }
);
```

---

## 6. Callback/Payment Verification

### VNPay IPN (Instant Payment Notification):

```javascript
// GET /api/payment/vnpay/return
app.get("/api/payment/vnpay/return", async (req, res) => {
  const vnpParams = req.query;
  const secureHash = vnpParams["vnp_SecureHash"];

  delete vnpParams["vnp_SecureHash"];
  delete vnpParams["vnp_SecureHashType"];

  // Verify signature
  const signData = new URLSearchParams(
    Object.keys(vnpParams)
      .sort()
      .reduce((result, key) => {
        result[key] = vnpParams[key];
        return result;
      }, {})
  ).toString();

  const hmac = crypto.createHmac("sha512", vnpayConfig.secretKey);
  const signed = hmac.update(signData, "utf-8").digest("hex");

  if (secureHash === signed) {
    const orderId = vnpParams["vnp_TxnRef"];
    const rspCode = vnpParams["vnp_ResponseCode"];

    if (rspCode === "00") {
      // Thanh toán thành công
      await Transaction.updateOne(
        { orderId },
        { status: "COMPLETED", vnpayResponse: vnpParams }
      );

      // Tạo member card
      const transaction = await Transaction.findOne({ orderId });
      await createMemberCard(transaction.userId, transaction.cardTypeId);

      return res.redirect("https://yourapp.com/payment/success");
    } else {
      // Thanh toán thất bại
      await Transaction.updateOne(
        { orderId },
        { status: "FAILED", vnpayResponse: vnpParams }
      );
      return res.redirect("https://yourapp.com/payment/failed");
    }
  } else {
    return res.status(400).json({ message: "Invalid signature" });
  }
});
```

---

## 7. Package.json dependencies

```json
{
  "dependencies": {
    "vnpay": "^1.0.0",
    "qrcode": "^1.5.3",
    "axios": "^1.6.0",
    "crypto": "^1.0.1"
  }
}
```

---

## Tóm tắt:

1. **VNPay**: Phổ biến nhất, hỗ trợ đầy đủ, có sandbox
2. **MoMo**: Ví điện tử, dễ tích hợp
3. **VietQR**: Miễn phí, QR code chuyển khoản ngân hàng
4. **QRCode library**: Tạo QR code từ bất kỳ text/URL nào

**Khuyến nghị**: Sử dụng **VNPay** cho production vì:

- Hỗ trợ đầy đủ tính năng
- Có sandbox để test
- Tài liệu đầy đủ
- Hỗ trợ nhiều ngân hàng
- Có QR code động
