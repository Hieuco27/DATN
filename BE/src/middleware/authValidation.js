const validator = require('validator');

// Sanitize input to prevent XSS
const sanitizeInput = (input) => {
  if (typeof input === 'string') {
    return validator.escape(input.trim());
  }
  return input;
};

// Validate registration data
const validateRegister = (req, res, next) => {
  try {
    const { email, password, phoneNumber, fullName, dateOfBirth, gender, cccd, address, note } = req.body;

    const errors = [];

    // Email validation
    if (!email) {
      errors.push({ field: 'email', message: 'Email là bắt buộc' });
    } else if (!validator.isEmail(email)) {
      errors.push({ field: 'email', message: 'Email không hợp lệ' });
    } else if (email.length > 100) {
      errors.push({ field: 'email', message: 'Email không được vượt quá 100 ký tự' });
    }

    // Password validation
    if (!password) {
      errors.push({ field: 'password', message: 'Mật khẩu là bắt buộc' });
    } else if (password.length < 6) {
      errors.push({ field: 'password', message: 'Mật khẩu phải có ít nhất 6 ký tự' });
    } else if (password.length > 100) {
      errors.push({ field: 'password', message: 'Mật khẩu không được vượt quá 100 ký tự' });
    }

    // Full name validation
    if (!fullName) {
      errors.push({ field: 'fullName', message: 'Họ tên là bắt buộc' });
    } else if (fullName.trim().length < 2) {
      errors.push({ field: 'fullName', message: 'Họ tên phải có ít nhất 2 ký tự' });
    } else if (fullName.length > 100) {
      errors.push({ field: 'fullName', message: 'Họ tên không được vượt quá 100 ký tự' });
    }

    // Phone number validation (optional)
    if (phoneNumber) {
      const phoneRegex = /^[0-9]{10,11}$/;
      if (!phoneRegex.test(phoneNumber)) {
        errors.push({ field: 'phoneNumber', message: 'Số điện thoại không hợp lệ (10-11 chữ số)' });
      }
    }

    // Date of birth validation (optional)
    if (dateOfBirth) {
      if (!validator.isDate(dateOfBirth)) {
        errors.push({ field: 'dateOfBirth', message: 'Ngày sinh không hợp lệ' });
      } else {
        const dob = new Date(dateOfBirth);
        const today = new Date();
        const age = today.getFullYear() - dob.getFullYear();
        
        if (age < 13 || age > 120) {
          errors.push({ field: 'dateOfBirth', message: 'Tuổi phải từ 13 đến 120' });
        }
      }
    }

    // Gender validation (optional)
    if (gender !== undefined && gender !== null) {
      if (![0, 1].includes(Number(gender))) {
        errors.push({ field: 'gender', message: 'Giới tính không hợp lệ (0: Nữ, 1: Nam)' });
      }
    }

    // CCCD validation (optional)
    if (cccd) {
      const cccdRegex = /^[0-9]{9,12}$/;
      if (!cccdRegex.test(cccd)) {
        errors.push({ field: 'cccd', message: 'CCCD không hợp lệ (9-12 chữ số)' });
      }
    }

    // Address validation (optional)
    if (address && address.length > 200) {
      errors.push({ field: 'address', message: 'Địa chỉ không được vượt quá 200 ký tự' });
    }

    // Note validation (optional)
    if (note && note.length > 500) {
      errors.push({ field: 'note', message: 'Ghi chú không được vượt quá 500 ký tự' });
    }

    if (errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Dữ liệu không hợp lệ',
        errors
      });
    }

    // Sanitize inputs
    req.body.email = email.toLowerCase().trim();
    req.body.fullName = sanitizeInput(fullName);
    if (phoneNumber) req.body.phoneNumber = phoneNumber.trim();
    if (address) req.body.address = sanitizeInput(address);
    if (note) req.body.note = sanitizeInput(note);
    if (cccd) req.body.cccd = cccd.trim();

    next();
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi xử lý dữ liệu',
      error: error.message
    });
  }
};

// Validate login data
const validateLogin = (req, res, next) => {
  try {
    const { email, password } = req.body;

    const errors = [];

    // Email validation
    if (!email) {
      errors.push({ field: 'email', message: 'Email là bắt buộc' });
    } else if (!validator.isEmail(email)) {
      errors.push({ field: 'email', message: 'Email không hợp lệ' });
    }

    // Password validation
    if (!password) {
      errors.push({ field: 'password', message: 'Mật khẩu là bắt buộc' });
    } else if (password.length < 6) {
      errors.push({ field: 'password', message: 'Mật khẩu phải có ít nhất 6 ký tự' });
    }

    if (errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Dữ liệu không hợp lệ',
        errors
      });
    }

    // Sanitize email
    req.body.email = email.toLowerCase().trim();

    next();
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi xử lý dữ liệu',
      error: error.message
    });
  }
};

// Validate refresh token
const validateRefreshToken = (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token là bắt buộc'
      });
    }

    if (typeof refreshToken !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Refresh token không hợp lệ'
      });
    }

    if (refreshToken.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token không được để trống'
      });
    }

    next();
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi xử lý dữ liệu',
      error: error.message
    });
  }
};

// Rate limiting helper (stored in memory - for production use Redis)
const loginAttempts = new Map();

const checkRateLimit = (req, res, next) => {
  const identifier = req.body.email || req.ip;
  const now = Date.now();
  const windowMs = 15 * 60 * 1000; // 15 minutes
  const maxAttempts = 5;

  if (!loginAttempts.has(identifier)) {
    loginAttempts.set(identifier, []);
  }

  const attempts = loginAttempts.get(identifier);
  
  // Remove old attempts outside the window
  const recentAttempts = attempts.filter(time => now - time < windowMs);
  loginAttempts.set(identifier, recentAttempts);

  if (recentAttempts.length >= maxAttempts) {
    return res.status(429).json({
      success: false,
      message: 'Quá nhiều lần đăng nhập thất bại. Vui lòng thử lại sau 15 phút'
    });
  }

  // Add current attempt
  recentAttempts.push(now);
  loginAttempts.set(identifier, recentAttempts);

  next();
};

// Clean up old rate limit data periodically
setInterval(() => {
  const now = Date.now();
  const windowMs = 15 * 60 * 1000;
  
  for (const [identifier, attempts] of loginAttempts.entries()) {
    const recentAttempts = attempts.filter(time => now - time < windowMs);
    if (recentAttempts.length === 0) {
      loginAttempts.delete(identifier);
    } else {
      loginAttempts.set(identifier, recentAttempts);
    }
  }
}, 5 * 60 * 1000); // Clean up every 5 minutes

module.exports = {
  validateRegister,
  validateLogin,
  validateRefreshToken,
  checkRateLimit
};