// routes/auditRoutes.js
const express = require('express');
const router = express.Router();
const prisma = require('../config/database');

// GET /api/audit-logs
router.get('/', async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      actorUserId,
      recipientUserId,
      eventType,
      messageId,
      conversationId,
      groupId,
    } = req.query;

    const skip = (Number(page) - 1) * Number(limit);
    const take = Number(limit);

    // Build dynamic filter
    const where = {};
    if (actorUserId) where.actorUserId = actorUserId;
    if (recipientUserId) where.recipientUserId = recipientUserId;
    if (eventType) where.eventType = eventType;
    if (messageId) where.messageId = messageId;
    if (conversationId) where.conversationId = conversationId;
    if (groupId) where.groupId = groupId;

    const [logs, total] = await Promise.all([
      prisma.auditLog.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          actor: true, // Full User object
          recipient: true, // Full User object
          //   message: true, // Full Message object
          conversation: true, // Full Conversation object
          group: true, // Full Group object
        },
      }),
      prisma.auditLog.count({ where }),
    ]);

    res.json({
      success: true,
      page: Number(page),
      limit: Number(limit),
      total,
      logs,
    });
  } catch (error) {
    console.error('Error fetching audit logs:', error);
    res
      .status(500)
      .json({ success: false, error: 'Failed to fetch audit logs' });
  }
});

module.exports = router;
