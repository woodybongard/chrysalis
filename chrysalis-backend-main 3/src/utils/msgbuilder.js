/**
 * Get the message status from the message object
 * Status is stored directly on the message and updated when:
 * - SENT: Message created
 * - DELIVERED: All recipients have received it (deliveredAt set for all)
 * - READ: All recipients have read it (readAt set for all)
 */
function getMessageStatus(message) {
  return message?.status || 'SENT';
}

function buildChatObject({
  conversation,
  group,
  message,
  userId,
  unreadCount,
  aesKeyEncB64Url,
  iv,
  version,
}) {
  if (conversation) {
    const otherUser = conversation.members.find(
      (m) => m.userId !== userId,
    )?.user;

    return {
      type: 'conversation',
      id: conversation.id,
      name: otherUser
        ? `${otherUser.firstName || ''} ${otherUser.lastName || ''}`.trim()
        : 'Chat',
      avatar: otherUser?.avatar || null,
      isGroup: false,
      lastMessage: message
        ? {
            id: message.id,
            type: message.type,
            content: message.encryptedText,
            createdAt: message.createdAt,
            isSenderYou: message.sender.id === userId,
            status: getMessageStatus(message),
            sender: {
              id: message.sender.id,
              name: `${message.sender.firstName || ''} ${
                message.sender.lastName || ''
              }`.trim(),
            },
          }
        : null,
      unreadCount: unreadCount || 0,
    };
  }

  if (group) {
    return {
      type: 'group',
      id: group.id,
      name: group.name,
      avatar: group.profileImg || null,
      isGroup: true,
      lastMessage: message
        ? {
            id: message.id,
            type: message.type,
            content: message.encryptedText,
            createdAt: message.createdAt,
            isSenderYou: message.sender.id === userId,
            status: getMessageStatus(message),
            sender: {
              id: message.sender.id,
              name: `${message.sender.firstName || ''} ${
                message.sender.lastName || ''
              }`.trim(),
            },
            aesKeyEncB64Url,
            iv,
          }
        : null,
      unreadCount: unreadCount || 0,
      groupKey: aesKeyEncB64Url,
      version,
    };
  }
}

const formatGroupMessage = (message, senderId, recipientId) => {
  const dateKey = new Date(message.createdAt).toLocaleDateString('en-US', {
    weekday: 'long', // e.g., Today, Yesterday (you can customize)
  });

  const timeKey = new Date(message.createdAt).toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
  });

  const isSenderYou = false;

  return {
    data: {
      ['Today']: [
        {
          sender: {
            id: message.sender.id,
            firstName: message.sender.firstName,
            lastName: message.sender.lastName,
            avatar: message.sender.avatar || null,
          },
          isSenderYou,
          times: [
            {
              time: timeKey,
              messages: [
                {
                  id: message.id,
                  conversationId: message.conversationId || null,
                  groupId: message.groupId,
                  senderId: message.sender.id,
                  encryptedText: message.encryptedText,
                  type: message.type,
                  status: message.status,
                  fileUrl: message.fileUrl,
                  createdAt: message.createdAt,
                  sender: {
                    id: message.sender.id,
                    firstName: message.sender.firstName,
                    lastName: message.sender.lastName,
                    avatar: message.sender.avatar || null,
                  },
                  reads: message.reads
                    ? message.reads.map((r) => ({ readAt: r.readAt }))
                    : [],
                  isRead:
                    message.reads?.some(
                      (r) => r.userId === recipientId && r.readAt,
                    ) || false,
                  isSenderYou,
                  avatar: message.sender.avatar || null,
                },
              ],
            },
          ],
        },
      ],
    },
  };
};

module.exports = {
  buildChatObject,
  formatGroupMessage,
};
