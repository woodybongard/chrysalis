const express = require('express');
const { authenticate } = require('../middleware/auth');
const messageController = require('../controller/chat.controller');
const {
  getMessagesValidator,
  messageValidation,
} = require('../validations/chat.validator');
const upload = require('../middleware/upload');

const router = express.Router();

router.post(
  '/send',
  authenticate,
  upload.single('file'),
  messageValidation,
  messageController.sendMessage,
);

router.get(
  '/',
  authenticate,
  getMessagesValidator,
  messageController.getMessages,
);

router.get('/chat-list', authenticate, messageController.getChatList);
router.post('/mark-all-as-read', authenticate, messageController.markAllAsRead);
router.post('/ack-delivery', authenticate, messageController.ackDelivery);

module.exports = router;
