const passport = require('../config/passport');

// Middleware to require authentication using JWT
const requireAuth = (req, res, next) => {
  passport.authenticate('jwt', { session: false }, (err, user, info) => {
    if (err) {
      return res.status(500).json({
        success: false,
        message: 'Đã có lỗi xảy ra',
        error: err.message
      });
    }

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized - Token không hợp lệ hoặc đã hết hạn'
      });
    }

    req.user = user;
    next();
  })(req, res, next);
};

// Middleware to require specific roles
const requireRole = (allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized'
      });
    }

    if (!allowedRoles.includes(req.user.roleId)) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden - Bạn không có quyền truy cập'
      });
    }

    next();
  };
};

module.exports = {
  requireAuth,
  requireRole
};