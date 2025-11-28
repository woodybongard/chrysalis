const { validationResult } = require('express-validator');
const messageService = require('../services/chat.service');
const { uploadToS3 } = require('../utils/s3Upload');
const { scanAndUploadFile } = require('../utils/scanAndUploadFile');

exports.sendMessage = async (req, res, next) => {
  // const errors = validationResult(req);
  // if (!errors.isEmpty()) {
  //   return res.status(400).json({
  //     success: false,
  //     error: { message: 'Validation failed', details: errors.array() },
  //   });
  // }

  try {
    let fileData = null;
    if (req.file) {
      fileData = await scanAndUploadFile(
        req.file,
        req.body.groupId,
        req.body.iv,
      );
    }

    const message = await messageService.sendMessage(req.user.id, {
      ...req.body,
      fileUrl: fileData ? fileData.fileUrl : null,
    });

    res.status(201).json({
      success: true,
      message: 'Message sent successfully',
      data: { message },
    });
  } catch (error) {
    next(error);
  }
};

exports.getMessages = async (req, res) => {
  try {
    const { type, id, page, limit } = req.query;
    const userId = req.user.id;
    console.log(userId);
    const result = await messageService.fetchMessages({
      type,
      id,
      page,
      limit,
      userId,
    });
    return res.json(result);
  } catch (err) {
    console.error('Error fetching messages:', err.message);
    return res.status(400).json({ message: err.message });
  }
};

exports.getChatList = async (req, res) => {
  const { page, limit } = req.query;
  const userId = req.user.id;

  console.info('userId==>', userId);

  try {
    const result = await messageService.getChatListService({
      userId,
      page: parseInt(page || '1'),
      limit: parseInt(limit || '10'),
    });

    return res.status(200).json(result);
  } catch (err) {
    console.error('Get Chat List Error:', err);
    return res
      .status(err.status || 500)
      .json({ message: err.message || 'Internal server error' });
  }
};

exports.markAllAsRead = async (req, res) => {
  try {
    const { type, chatId } = req.body;
    const userId = req.user.id;

    if (!userId || !type || !chatId) {
      return res
        .status(400)
        .json({ message: 'userId, type, and chatId are required' });
    }

    const result = await messageService.markAllAsRead(userId, type, chatId);

    return res.status(200).json({
      message: `${result.updated} messages marked as read`,
    });
  } catch (error) {
    console.error('Error marking messages as read:', error);
    return res
      .status(500)
      .json({ message: 'Internal Server Error', error: error.message });
  }
};

exports.ackDelivery = async (req, res) => {
  try {
    const { type, chatId } = req.body;
    const userId = req.user.id;

    if (!userId || !type || !chatId) {
      return res
        .status(400)
        .json({ message: 'userId, type, and chatId are required' });
    }

    const result = await messageService.ackDelivery(userId, type, chatId);

    return res.status(200).json({
      message: `${result.updated} messages marked as delivered`,
    });
  } catch (error) {
    console.error('Error marking messages as delivered:', error);
    return res
      .status(500)
      .json({ message: 'Internal Server Error', error: error.message });
  }
};
