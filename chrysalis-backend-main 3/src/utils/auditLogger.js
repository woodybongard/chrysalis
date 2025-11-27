// // utils/auditLogger.js
// const crypto = require('crypto');
// const prisma = require('../config/database');

// const isClient = (c) => c && typeof c.auditEvent?.create === 'function';

// // * Compute a SHA-256 hash of a plain JS object.
// function sha256(obj) {
//   return crypto.createHash('sha256').update(JSON.stringify(obj)).digest('hex');
// }

// async function getPrevHash() {
//   const last = await prisma.auditEvent.findFirst({
//     orderBy: { occurredAt: 'desc' },
//     select: { hash: true },
//   });
//   return last?.hash || null;
// }

// // * Get the previous hash in the audit chain (most recent event).
// async function logAudit(clientOrPayload, maybePayload) {
//   const client = isClient(clientOrPayload) ? clientOrPayload : prisma;
//   const payload = isClient(clientOrPayload) ? maybePayload : clientOrPayload;

//   const {
//     action,
//     channel = null,
//     actorUserId = null,
//     recipientUserId = null,
//     messageId = null,
//     conversationId = null,
//     groupId = null,
//     ip = null,
//     userAgent = null,
//     deviceId = null,
//     metadata = {},
//   } = payload;

//   try {
//     const occurredAt = new Date();
//     const prevHash = await getPrevHash(client);

//     const body = {
//       action,
//       channel,
//       actorUserId,
//       recipientUserId,
//       messageId,
//       conversationId,
//       groupId,
//       ip,
//       userAgent,
//       deviceId,
//       metadata,
//       occurredAt,
//       prevHash,
//     };

//     const hash = sha256(body);

//     return await client.auditEvent.create({
//       data: { ...body, hash },
//     });
//   } catch (err) {
//     console.error('Audit log failed:', err);
//     return null;
//   }
// }

// // async function logAudit({
// //   action,
// //   channel = null,
// //   actorUserId = null,
// //   recipientUserId = null,
// //   messageId = null,
// //   conversationId = null,
// //   groupId = null,
// //   ip = null,
// //   userAgent = null,
// //   deviceId = null,
// //   metadata = {},
// // }) {
// //   console.log('action===>', action);
// //   try {
// //     const occurredAt = new Date();
// //     const prevHash = await getPrevHash();

// //     // Build the payload we will hash & store
// //     const body = {
// //       action,
// //       channel,
// //       actorUserId,
// //       recipientUserId,
// //       messageId,
// //       conversationId,
// //       groupId,
// //       ip,
// //       userAgent,
// //       deviceId,
// //       metadata,
// //       occurredAt,
// //       prevHash,
// //     };

// //     const hash = sha256(body);

// //     return await prisma.auditEvent.create({
// //       data: { ...body, hash },
// //     });
// //   } catch (error) {
// //     // Do not throw to avoid breaking the main flow; just log.
// //     console.error('Audit log failed:', error);
// //     return null;
// //   }
// // }

// /**
//  * Convenience helper: pulls IP, UA, deviceId from Express req
//  * and merges with your payload.
//  */
// async function logAuditFromReq(req, payload) {
//   const ip =
//     req.headers['x-forwarded-for']?.toString().split(',')[0]?.trim() ||
//     req.socket?.remoteAddress ||
//     null;

//   const userAgent = req.headers['user-agent'] || null;
//   const deviceId = req.headers['x-device-id'] || null;

//   return logAudit({
//     ip,
//     userAgent,
//     deviceId,
//     ...payload,
//   });
// }

// /* ------------------- Convenience wrappers for common actions ------------------- */

// const logMessageCreated = (clientOrPayload, payload) =>
//   isClient(clientOrPayload)
//     ? logAudit(clientOrPayload, { action: 'MESSAGE_CREATED', ...payload })
//     : logAudit({ action: 'MESSAGE_CREATED', ...clientOrPayload });

// async function logDeliveryAttempted({
//   messageId,
//   conversationId = null,
//   groupId = null,
//   channel = 'SOCKET',
// }) {
//   return logAudit({
//     action: 'DELIVERY_ATTEMPTED',
//     channel,
//     messageId,
//     conversationId,
//     groupId,
//   });
// }

// async function logDelivered({
//   recipientUserId,
//   messageId,
//   channel = 'SOCKET',
//   ip = null,
//   userAgent = null,
//   deviceId = null,
// }) {
//   return logAudit({
//     action: 'DELIVERED',
//     recipientUserId,
//     messageId,
//     channel,
//     ip,
//     userAgent,
//     deviceId,
//   });
// }

// async function logRead({ recipientUserId, messageId }) {
//   return logAudit({
//     action: 'READ',
//     recipientUserId,
//     messageId,
//   });
// }

// async function logBulkRead({ actorUserId, count, type, chatId }) {
//   return logAudit({
//     action: 'BULK_READ',
//     actorUserId,
//     metadata: { count, type, chatId },
//   });
// }

// async function logDeleteMessage({ actorUserId, messageId, reason = null }) {
//   return logAudit({
//     action: 'DELETE',
//     actorUserId,
//     messageId,
//     metadata: { reason },
//   });
// }

// async function logArchiveGroup({ actorUserId, groupId, reason = null }) {
//   return logAudit({
//     action: 'ARCHIVE',
//     actorUserId,
//     groupId,
//     metadata: { reason },
//   });
// }

// module.exports = {
//   logAudit,
//   logAuditFromReq,
//   logMessageCreated,
//   logDeliveryAttempted,
//   logDelivered,
//   logRead,
//   logBulkRead,
//   logDeleteMessage,
//   logArchiveGroup,
// };

// utils/auditLogger.js
const prisma = require('../config/database');

exports.logMessageCreated = async (
  tx,
  { actorUserId, messageId, isGroup, conversationId, groupId, metadata },
) => {
  return tx.auditLog.create({
    data: {
      actorUserId,
      recipientUserId: null,
      eventType: 'MESSAGE_CREATED',
      messageId,
      conversationId,
      groupId,
      // isGroup,
      metadata,
    },
  });
};

exports.logDeliveryAttempted = async ({
  messageId,
  conversationId,
  groupId,
  channel,
}) => {
  return prisma.auditLog.create({
    data: {
      eventType: 'DELIVERY_ATTEMPTED',
      messageId,
      conversationId,
      groupId,
      metadata: { channel },
    },
  });
};
