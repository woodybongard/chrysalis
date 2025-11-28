const { query, body } = require('express-validator');

exports.getMessagesValidator = [
  query('type')
    .notEmpty()
    .withMessage('Type is required')
    .isIn(['conversation', 'group'])
    .withMessage('Type must be either "conversation" or "group"'),
  query('id')
    .notEmpty()
    .withMessage('ID is required')
    .isString()
    .withMessage('ID must be a string'),
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),
];

exports.messageValidation = [
  body('recipientId').optional(),
  body('content').notEmpty().withMessage('Message content is required'),
  body('type')
    .isIn(['TEXT', 'IMAGE', 'FILE', 'VIDEO', 'AUDIO'])
    .withMessage('Invalid message type'),
  body('groupId').optional({ checkFalsy: true }).isUUID(),
];
