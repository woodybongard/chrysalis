const prisma = require('../config/database'); // import prisma
const admin = require('../config/firebase'); // initializeApp is already done here

// Lazy import to avoid circular dependency
const getIO = () => require('../socket').getIO();
async function sendPushNotification(
  tokens,
  message,
  group = null,
  unreadCounts = [],
  version = 1,
  envelopeMap = {},
  singleRecipientId = null,
) {
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
      // tokens param may be an array of token strings
      const memberTokens = Array.isArray(tokens) ? tokens.filter(Boolean) : [];
      if (memberTokens.length === 0) return;

      const payload = {
        tokens: memberTokens,
        notification: {
          title: name || 'New Message',
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
          version: String(version || 1),
          groupKey: envelopeMap[singleRecipientId] || '',
        },
      };

      const response = await admin.messaging().sendEachForMulticast(payload);
      // Process response similar to group flow (mark delivered etc.)
      for (let i = 0; i < response.responses.length; i++) {
        const resp = response.responses[i];
        if (resp.success) {
          console.log(`✔️ Delivered push to ${singleRecipientId}`);

          const now = new Date();

          // Mark deliveredAt for this recipient in MessageRead
          await prisma.messageRead.updateMany({
            where: {
              messageId: message.id,
              userId: singleRecipientId,
              deliveredAt: null,
            },
            data: { deliveredAt: now },
          });

          // Update MessageDelivery record with PUSH channel
          await prisma.messageDelivery.updateMany({
            where: { messageId: message.id, recipientId: singleRecipientId },
            data: {
              status: 'DELIVERED',
              lastChannel: 'PUSH',
              deliveredAt: now,
            },
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

    // ------------- Group handling -------------
    if (isGroup && group && group.members && group.members.length > 0) {
      console.log(`📤 Group push: senderId=${message.senderId}, members=${group.members.map(m => m.userId).join(',')}`);

      for (const member of group.members) {
        const uid = member.userId;

        // Skip sender
        if (uid === message.senderId) {
          console.log(`Skipping push for user ${uid} — is the sender`);
          continue;
        }

        // Skip members who have notifications disabled
        if (member.user?.isNotification === false) {
          console.log(
            `Skipping push for user ${uid} — notifications disabled`,
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
            title: name || 'New Message',
            body: 'You have a new message',
          },
          data: {
            id: chatId || '',
            type: 'group',
            title: name || '',
            isGroup: 'true',
            avatar: avatar || '',
            route: 'chat_detail',
            unreadCount: String(userUnreadCount || 0),
            version: String(version || 1),
            groupKey: aesKeyEncB64Url || '',
          },
        };

        const response = await admin.messaging().sendEachForMulticast(payload);

        for (let i = 0; i < response.responses.length; i++) {
          const resp = response.responses[i];
          if (resp.success) {
            console.log(`✔️ Delivered push to ${uid}`);

            const now = new Date();

            // Mark deliveredAt in MessageRead
            await prisma.messageRead.updateMany({
              where: {
                messageId: message.id,
                userId: uid,
                deliveredAt: null,
              },
              data: { deliveredAt: now },
            });

            // Update MessageDelivery record with PUSH channel
            await prisma.messageDelivery.updateMany({
              where: { messageId: message.id, recipientId: uid },
              data: {
                status: 'DELIVERED',
                lastChannel: 'PUSH',
                deliveredAt: now,
              },
            });

            // Fetch participants of the group and current message reads
            const participants = (
              await prisma.group.findUnique({
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
                  type: 'group',
                  lastMessageId: message.id,
                  lastMessageStatus: 'DELIVERED',
                });

                io.to(`user_${dbMessage.senderId}`).emit(
                  'messages_update_status',
                  {
                    chatId,
                    type: 'group',
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
      }
    }
  } catch (err) {
    console.error('❌ Error sending push notification:', err);
  }
}

exports.sendPushNotification = sendPushNotification;

/**
 * Send push notification for message reactions
 * @param {string} messageOwnerId - The user who sent the original message
 * @param {string} reactorId - The user who reacted
 * @param {string} reactorName - Name of the user who reacted
 * @param {string} emoji - The emoji used
 * @param {string} chatId - Conversation or group ID
 * @param {boolean} isGroup - Whether this is a group chat
 * @param {string} chatName - Name of the chat/group
 */
async function sendReactionPushNotification({
  messageOwnerId,
  reactorId,
  reactorName,
  emoji,
  chatId,
  isGroup,
  chatName,
}) {
  try {
    // Don't notify if user reacted to their own message
    if (messageOwnerId === reactorId) {
      console.log('Skipping reaction push: user reacted to their own message');
      return;
    }

    // Get message owner's notification preference and FCM tokens
    const messageOwner = await prisma.user.findUnique({
      where: { id: messageOwnerId },
      select: {
        isNotification: true,
        fcmTokens: { select: { token: true } },
      },
    });

    if (!messageOwner) {
      console.log('Skipping reaction push: message owner not found');
      return;
    }

    // Check notification preference
    if (messageOwner.isNotification === false) {
      console.log(
        `Skipping reaction push: user ${messageOwnerId} has notifications disabled`,
      );
      return;
    }

    const tokens = messageOwner.fcmTokens.map((t) => t.token).filter(Boolean);
    if (tokens.length === 0) {
      console.log('Skipping reaction push: no FCM tokens');
      return;
    }

    const payload = {
      tokens,
      notification: {
        title: isGroup ? chatName : reactorName,
        body: `${reactorName} reacted ${emoji} to your message`,
      },
      data: {
        id: chatId,
        type: isGroup ? 'group' : 'conversation',
        route: 'chat_detail',
        isGroup: String(isGroup),
        notificationType: 'reaction',
        emoji: emoji,
        reactorId: reactorId,
        reactorName: reactorName,
      },
    };

    const response = await admin.messaging().sendEachForMulticast(payload);

    response.responses.forEach((resp, i) => {
      if (resp.success) {
        console.log(`✔️ Reaction push delivered to ${messageOwnerId}`);
      } else {
        console.error(`❌ Reaction push failed for token ${tokens[i]}:`, resp.error);
      }
    });
  } catch (err) {
    console.error('❌ Error sending reaction push notification:', err);
  }
}

exports.sendReactionPushNotification = sendReactionPushNotification;
