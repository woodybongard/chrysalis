// routes/keys.routes.js
const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const keyController = require('../controller/keys.controller');

router.post(
  '/devices/register-key',
  authenticate,
  keyController.uploadKeyBundle,
);

module.exports = router;
