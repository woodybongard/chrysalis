const prisma = require('../config/database'); // import prisma
const admin = require('../config/firebase'); // initializeApp is already done here
const { getIO } = require('../socket');
async function sendPushNotification(
  tokens,
  message,
  group = null,
  unreadCounts = [],
  version = 1,
  envelopeMap = {},
  liveUserIds = new Set(), // Set of userIds currently in the chat (if provided)
  singleRecipientId = null, // optional: for 1:1 flows
) {
  // Normalize liveUserIds (accept array or Set)
  if (Array.isArray(liveUserIds)) liveUserIds = new Set(liveUserIds || []);
  if (!liveUserIds) liveUserIds = new Set();

  try {
    const isGroup = !!message.groupId;
    const chatId = isGroup ? message.groupId : message.conversationId;
    const avatar = isGroup ? group?.avatar : message.sender?.avatar;
    const name = isGroup
      ? group?.name
      : `${message?.sender?.firstName || ''} ${
          message?.sender?.lastName || ''
        }`.trim();

    // Map userId -> unreadCount
    const unreadCountMap = {};
    (unreadCounts || []).forEach((u) => {
      unreadCountMap[u.userId] = u.unreadCount;
    });

    // ------------- Single recipient (1:1) handling -------------
    if (!isGroup && singleRecipientId) {
      // If the recipient is live in the conversation, skip sending push entirely
      if (liveUserIds.has(singleRecipientId)) {
        console.log(
          `Skipping push: recipient ${singleRecipientId} is currently in conversation ${chatId}`,
        );
        return;
      }

      // tokens param may be an array of token strings
      const memberTokens = Array.isArray(tokens) ? tokens.filter(Boolean) : [];
      if (memberTokens.length === 0) return;

      const payload = {
        tokens: memberTokens,
        notification: {
          title: name,
          body: 'You have a new message',
        },
        data: {
          id: chatId || '',
          type: 'conversation',
          title: name || '',
          isGroup: 'false',
          avatar: avatar || '',
          route: 'chat_detail',
          unreadCount: String(unreadCountMap[singleRecipientId] || 0),
          version: String(version),
          groupKey: envelopeMap[singleRecipientId] || '',
        },
      };

      const response = await admin.messaging().sendEachForMulticast(payload);
      // Process response similar to group flow (mark delivered etc.)
      for (let i = 0; i < response.responses.length; i++) {
        const resp = response.responses[i];
        if (resp.success) {
          console.log(`✔️ Delivered push to ${singleRecipientId}`);

          // Mark deliveredAt for this recipient
          await prisma.messageRead.updateMany({
            where: {
              messageId: message.id,
              userId: singleRecipientId,
              deliveredAt: null,
            },
            data: { deliveredAt: new Date() },
          });

          // Check if all delivered and update status & notify sender (reuse existing logic)
          const participants = (
            await prisma.conversation.findUnique({
              where: { id: chatId },
              include: { members: true },
            })
          ).members.map((m) => m.userId);

          const dbMessage = await prisma.message.findUnique({
            where: { id: message.id },
            include: { reads: true },
          });

          const allDelivered = participants.every((pid) =>
            dbMessage.reads.some(
              (r) => r.userId === pid && r.deliveredAt !== null,
            ),
          );

          const io = getIO();

          if (allDelivered) {
            if (dbMessage.status !== 'READ') {
              await prisma.message.update({
                where: { id: message.id },
                data: { status: 'DELIVERED' },
              });

              io.to(`user_${dbMessage.senderId}`).emit('chatlist_update', {
                chatId,
                type: 'conversation',
                lastMessageId: message.id,
                lastMessageStatus: 'DELIVERED',
              });

              io.to(`user_${dbMessage.senderId}`).emit(
                'messages_update_status',
                {
                  chatId,
                  type: 'conversation',
                  messages: [
                    {
                      id: message.id,
                      status: 'DELIVERED',
                      senderId: dbMessage.senderId,
                    },
                  ],
                },
              );
            }

            io.to(`chat_${chatId}`).emit('message:all_delivered', {
              messageId: message.id,
              status: 'DELIVERED',
            });
          }
        } else {
          console.error(
            `❌ Push failed for token ${memberTokens[i]}:`,
            resp.error,
          );
        }
      }

      return;
    }

    // ------------- Group handling (optimized) -------------
    if (isGroup && group && group.members && group.members.length > 0) {
      // Collect all push notification promises to send in parallel
      const pushPromises = [];
      const memberPushMap = []; // Track which members we're sending to

      for (const member of group.members) {
        const uid = member.userId;

        // Skip sender
        if (uid === message.senderId) continue;

        // Skip members who are currently live in the group chat
        if (liveUserIds.has(uid)) {
          console.log(
            `Skipping push for user ${uid} — currently live in group ${chatId}`,
          );
          continue;
        }

        const memberTokens = (member.user?.fcmTokens || [])
          .map((t) => t.token)
          .filter(Boolean);
        if (memberTokens.length === 0) continue;

        const userUnreadCount = unreadCountMap[uid] || 0;
        const aesKeyEncB64Url = envelopeMap[uid] || null;

        const payload = {
          tokens: memberTokens,
          notification: {
            title: name,
            body: 'You have a new message',
          },
          data: {
            id: chatId || '',
            type: 'group',
            title: name || '',
            isGroup: 'true',
            avatar: avatar || '',
            route: 'chat_detail',
            unreadCount: String(userUnreadCount),
            version: String(version),
            groupKey: aesKeyEncB64Url || '',
          },
        };

        // Queue the push notification
        pushPromises.push(admin.messaging().sendEachForMulticast(payload));
        memberPushMap.push({ uid, tokens: memberTokens });
      }

      // Send all push notifications in parallel
      const responses = await Promise.all(pushPromises);

      // Collect successfully delivered user IDs
      const deliveredUserIds = [];
      for (let i = 0; i < responses.length; i++) {
        const response = responses[i];
        const { uid, tokens } = memberPushMap[i];

        for (let j = 0; j < response.responses.length; j++) {
          const resp = response.responses[j];
          if (resp.success) {
            console.log(`✔️ Delivered push to ${uid}`);
            deliveredUserIds.push(uid);
            break; // At least one token succeeded for this user
          } else {
            console.error(`❌ Push failed for token ${tokens[j]}:`, resp.error);
          }
        }
      }

      // Batch update all MessageRead records at once
      if (deliveredUserIds.length > 0) {
        await prisma.messageRead.updateMany({
          where: {
            messageId: message.id,
            userId: { in: deliveredUserIds },
            deliveredAt: null,
          },
          data: { deliveredAt: new Date() },
        });

        // Fetch message with reads ONCE after all updates
        const [groupData, dbMessage] = await Promise.all([
          prisma.group.findUnique({
            where: { id: chatId },
            select: { members: { select: { userId: true } } },
          }),
          prisma.message.findUnique({
            where: { id: message.id },
            include: { reads: true },
          }),
        ]);

        const participants = groupData.members.map((m) => m.userId);
        const allDelivered = participants.every((pid) =>
          dbMessage.reads.some(
            (r) => r.userId === pid && r.deliveredAt !== null,
          ),
        );

        if (allDelivered && dbMessage.status !== 'READ') {
          await prisma.message.update({
            where: { id: message.id },
            data: { status: 'DELIVERED' },
          });

          const io = getIO();

          io.to(`user_${dbMessage.senderId}`).emit('chatlist_update', {
            chatId,
            type: 'group',
            lastMessageId: message.id,
            lastMessageStatus: 'DELIVERED',
          });

          io.to(`user_${dbMessage.senderId}`).emit('messages_update_status', {
            chatId,
            type: 'group',
            messages: [
              {
                id: message.id,
                status: 'DELIVERED',
                senderId: dbMessage.senderId,
              },
            ],
          });

          io.to(`chat_${chatId}`).emit('message:all_delivered', {
            messageId: message.id,
            status: 'DELIVERED',
          });
        }
      }
    }
  } catch (err) {
    console.error('❌ Error sending push notification:', err);
  }
}

exports.sendPushNotification = sendPushNotification;
