// routes/keys.routes.js
const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const userController = require('../controller/user.controller');
const upload = require('../middleware/upload');

router.get('/', authenticate, userController.getlist);
router.get('/user-details/:id', authenticate, userController.getUserById);
router.put(
  '/update-profile',
  authenticate,
  upload.single('file'),
  userController.updateProfile,
);
router.patch(
  '/update-user-profile',
  authenticate,
  upload.single('file'),
  userController.updateUserProfile,
);
router.patch(
  '/toggle-notifications',
  authenticate,
  userController.toggleNotifications,
);

router.put('/update-password', authenticate, userController.updatePassword);

module.exports = router;
