// middleware/roles.js
function authorizeRoles(...allowedRoles) {
  return (req, res, next) => {
    console.log(req.user.role);
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: { message: 'Forbidden: insufficient permissions' },
      });
    }
    next();
  };
}

module.exports = { authorizeRoles };
