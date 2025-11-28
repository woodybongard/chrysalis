const prisma = require('../config/database');
const { getIO } = require('../socket');
const {
  logMessageCreated,
  logDeliveryAttempted,
} = require('../utils/auditLogger');
const { buildChatObject } = require('../utils/msgbuilder');
const { sendPushNotification } = require('../utils/pushNotification');

exports.sendMessage = async (
  senderId,
  {
    recipientId,
    groupId,
    content,
    type,
    fileUrl,
    iv,
    aesKeyEncB64Url,
    version,
    fileName = null,
    fileType = null,
    fileSize = null,
    filePages = null,
  },
) => {
  if (!recipientId && !groupId && !version) {
    console.error('Either recipientId or groupId is required');
    const err = new Error('Either recipientId or groupId is required');
    err.status = 400;
    throw err;
  }

  let sender, recipient;

  // ---------- 1:1 CONVERSATION ----------
  if (recipientId) {
    if (recipientId === senderId) {
      const err = new Error('Cannot send message to yourself');
      err.status = 400;
      throw err;
    }

    [sender, recipient] = await Promise.all([
      prisma.user.findUnique({ where: { id: senderId } }),
      prisma.user.findUnique({
        where: { id: recipientId },
        select: {
          id: true,
          fcmTokens: {
            select: { token: true },
          },
        },
      }),
    ]);

    if (!recipient) {
      const err = new Error('Recipient not found');
      err.status = 404;
      throw err;
    }

    // find or create 1:1 conversation
    let conversation = await prisma.conversation.findFirst({
      where: {
        isGroup: false,
        members: {
          every: {
            userId: { in: [senderId, recipientId] },
          },
        },
      },
      select: { id: true },
    });

    if (!conversation) {
      conversation = await prisma.conversation.create({
        data: {
          isGroup: false,
          members: {
            create: [{ userId: senderId }, { userId: recipientId }],
          },
        },
        select: { id: true },
      });
    }

    // Create message + seed delivery rows + create audit in a transaction
    const message = await prisma.$transaction(async (tx) => {
      const msg = await tx.message.create({
        data: {
          senderId,
          conversationId: conversation.id,
          encryptedText: content,
          type,
          fileUrl,
          status: 'SENT',
        },
        include: {
          sender: {
            select: { id: true, firstName: true, lastName: true, role: true },
          },
        },
      });

      // Seed MessageDelivery for the recipient (current-state table)
      await tx.messageDelivery.create({
        data: {
          messageId: msg.id,
          recipientId,
          status: 'QUEUED',
        },
      });

      // Audit: MESSAGE_CREATED
      // await logMessageCreated(tx, {
      //   actorUserId: senderId,
      //   messageId: msg.id,
      //   conversationId: conversation.id,
      //   metadata: { type: msg.type, hasFile: !!msg.fileUrl },
      // });

      return msg;
    });

    // Emit + audit delivery attempt
    const io = getIO();
    // await logDeliveryAttempted({
    //   messageId: message.id,
    //   conversationId: conversation.id,
    //   channel: 'SOCKET',
    // });

    io.to(conversation.id).emit('new_message', {
      id: message.id,
      encryptedText: message.encryptedText,
      type: message.type,
      conversationId: conversation.id,
      sender: message.sender,
      fileUrl: message.fileUrl,
      createdAt: message.createdAt,
    });

    const unreadCount = await prisma.message.count({
      where: {
        conversationId: conversation.id,
        senderId: { not: senderId },
        reads: { none: { senderId } },
      },
    });

    const chat = buildChatObject({
      conversation,
      group: null,
      message,
      userId: senderId,
      unreadCount,
    });

    io.to(`user_${recipientId}`).emit('conv_message', chat);

    if (recipient.fcmTokens && recipient.fcmTokens.length > 0) {
      const tokens = recipient.fcmTokens.map((t) => t.token).filter(Boolean);
      if (tokens.length > 0) {
        await sendPushNotification(
          tokens,
          message,
          null, // group
          [], // unreadCounts
          1, // version
          {}, // envelopeMap
          new Set(), // liveUserIds - TODO: pass actual live users
          recipientId, // singleRecipientId for 1:1 flow
        );
      }
    }

    return message;
  }

  // ---------- GROUP MESSAGE ----------
  const group = await prisma.group.findUnique({
    where: { id: groupId },
    include: {
      members: {
        select: {
          userId: true,
          user: {
            select: {
              fcmTokens: {
                select: { token: true },
              },
            },
          },
        },
      },
    },
  });

  if (!group) {
    const err = new Error('Group not found');
    err.status = 404;
    throw err;
  }

  const isMember = group.members.some((m) => m.userId === senderId);
  if (!isMember) {
    const err = new Error('You are not a member of this group');
    err.status = 403;
    throw err;
  }

  const recipientIds = group.members
    .map((m) => m.userId)
    .filter((uid) => uid !== senderId);

  const message = await prisma.$transaction(async (tx) => {
    const msg = await tx.message.create({
      data: {
        senderId,
        groupId,
        encryptedText: content,
        type,
        fileUrl,
        status: 'SENT',
        iv,
        aesKeyEncB64Url,
        version: parseInt(version),
        fileName,
        fileType,
        fileSize,
        filePages: parseInt(filePages),
      },
      include: {
        sender: {
          select: { id: true, firstName: true, lastName: true, role: true },
        },
      },
    });

    // Seed MessageDelivery for each recipient in the group
    if (recipientIds.length > 0) {
      await tx.messageDelivery.createMany({
        data: recipientIds.map((rid) => ({
          messageId: msg.id,
          recipientId: rid,
          status: 'QUEUED',
        })),
        skipDuplicates: true,
      });
    }

    await logMessageCreated(tx, {
      actorUserId: senderId,
      messageId: msg.id,
      isGroup: true,
      groupId: groupId,
      metadata: { type: msg.type, hasFile: !!msg.fileUrl },
    });

    return msg;
  });

  // Emit to group room + audit delivery attempt
  const io = getIO();
  // await logDeliveryAttempted({
  //   messageId: message.id,
  //   groupId,
  //   channel: 'SOCKET',
  // });

  const members = await prisma.groupMember.findMany({
    where: { groupId: groupId },
  });

  // Create read/delivery tracking rows
  await prisma.messageRead.createMany({
    data: members.map((m) => ({
      userId: m.userId,
      messageId: message.id,
      readAt: m.userId === senderId ? new Date() : null, // ✅ sender gets readAt
      deliveredAt: m.userId === senderId ? new Date() : null, // ✅ sender gets readAt
    })),
  });

  const envelopes = await prisma.groupKeyEnvelope.findMany({
    where: { groupId, version: message.version || 1 },
    select: { userId: true, aesKeyEncB64Url: true },
  });

  const envelopeMap = Object.fromEntries(
    envelopes.map((e) => [e.userId, e.aesKeyEncB64Url]),
  );

  const room = io.sockets.adapter.rooms.get(`group_${groupId}`);
  const liveUserIds = new Set();

  if (room) {
    for (const socketId of room) {
      const liveSocket = io.sockets.sockets.get(socketId);
      if (!liveSocket?.userId) continue;

      if (liveSocket?.userId) {
        liveUserIds.add(liveSocket.userId);
      }

      // Mark message as read instantly if user is in the chat
      const newupdate = await prisma.messageRead.upsert({
        where: {
          userId_messageId: {
            userId: liveSocket.userId,
            messageId: message.id,
          },
        },
        update: { readAt: new Date() },
        create: {
          userId: liveSocket.userId,
          messageId: message.id,
          readAt: new Date(),
        },
      });

      if (liveSocket.userId !== senderId) {
        liveSocket.emit('group_message', {
          id: message.id,
          conversationId: null,
          groupId,
          encryptedText: message.encryptedText,
          type: message.type,
          status: 'SENT',
          fileUrl: message.fileUrl,
          createdAt: message.createdAt,
          senderId,
          senderName: `${message.sender?.firstName || ''} ${
            message.sender?.lastName || ''
          }`.trim(),
          senderAvatar:
            message.sender?.avatar ||
            'https://www.gravatar.com/avatar/?d=mp&s=200',
          isSenderYou: false,
          aesKeyEncB64Url: envelopeMap[liveSocket.userId] || null,
          iv,
          thumbnail: fileName
            ? {
                fileName: message.fileName,
                fileType: message.fileType,
                fileSize: message.fileSize,
                filePages: message.filePages,
              }
            : null,
        });
      }
    }
  }

  // Fetch unread counts for all group members except sender
  const unreadRows = await prisma.messageRead.findMany({
    where: {
      message: { groupId: group.id },
      readAt: null,
    },
    select: {
      userId: true,
      messageId: true,
    },
  });

  const unreadCountsMap = {};
  unreadRows.forEach((row) => {
    if (row.userId === senderId) return; // skip sender
    unreadCountsMap[row.userId] = (unreadCountsMap[row.userId] || 0) + 1;
  });

  const unreadCounts = group.members.map((m) => ({
    userId: m.userId,
    unreadCount: m.userId === senderId ? 0 : unreadCountsMap[m.userId] || 0,
  }));

  group.members
    .filter((m) => m.userId !== senderId)
    .forEach((m) => {
      const userSpecificChat = buildChatObject({
        conversation: null,
        group,
        message,
        userId: m.userId,
        unreadCount:
          unreadCounts.find((u) => u.userId === m.userId)?.unreadCount || 0,
        aesKeyEncB64Url: envelopeMap[m.userId] || null,
        iv,
        version: parseInt(version),
      });

      io.to(`user_${m.userId}`).emit('new_message', userSpecificChat);
    });

  // Also send to the sender with isSenderYou: true
  const senderChat = buildChatObject({
    conversation: null,
    group,
    message,
    userId: senderId,
    unreadCount: 0,
    aesKeyEncB64Url: envelopeMap[senderId] || null,
    iv,
    version: parseInt(version),
  });

  io.to(`user_${senderId}`).emit('new_message', senderChat);

  // Fetch updated chat with latest message
  // const updatedChat = await prisma.chat.findUnique({
  //   where: { id: chatId },
  //   include: { lastMessage: true, participants: true },
  // });

  // // Emit to all users in that chat room
  // getIO().to(chatId).emit('chatUpdated', updatedChat);

  const fcmTokens = group.members
    .filter((m) => m.userId !== senderId) // skip sender
    .flatMap((m) => m.user.fcmTokens.map((t) => t.token)) // extract token strings
    .filter(Boolean); // remove null/undefined

  if (fcmTokens.length > 0) {
    await sendPushNotification(
      fcmTokens,
      message,
      group,
      unreadCounts,
      version,
      envelopeMap,
      liveUserIds, // pass the set you already built above
    );
  }

  return message;
};

exports.fetchMessages = async ({ type, id, page = 1, limit = 20, userId }) => {
  if (!type || !id) {
    throw new Error('Type and ID are required');
  }
  if (!userId) {
    throw new Error('Current user ID is required to check read status');
  }

  const skip = (parseInt(page) - 1) * parseInt(limit);
  const take = parseInt(limit);

  let whereClause = {};
  if (type === 'conversation') {
    whereClause = { conversationId: id };
  } else if (type === 'group') {
    const membership = await prisma.groupMember.findFirst({
      where: { userId, groupId: id },
      select: { joinedAt: true },
    });
    if (!membership) {
      throw new Error('User is not a member of this group');
    }

    // 2. Find when the user first got a group key envelope (if any)
    const keyEnvelope = await prisma.groupKeyEnvelope.findFirst({
      where: { userId, groupId: id },
      orderBy: { createdAt: 'asc' }, // first time they got a usable key
      select: { createdAt: true },
    });
    // 3. Effective "start date" is the later of joinedAt vs keyEnvelope.createdAt
    const effectiveStart = keyEnvelope
      ? new Date(
          Math.max(
            membership.joinedAt.getTime(),
            keyEnvelope.createdAt.getTime(),
          ),
        )
      : membership.joinedAt;

    // 4. Only fetch messages created after effectiveStart
    whereClause = {
      groupId: id,
      createdAt: { gte: effectiveStart },
    };
    // whereClause = { groupId: id };
  } else {
    throw new Error('Invalid type. Must be "conversation" or "group"');
  }

  const [messages, total, envelopes] = await Promise.all([
    prisma.message.findMany({
      where: whereClause,
      orderBy: { createdAt: 'desc' },
      skip,
      take,
      select: {
        id: true,
        conversationId: true,
        groupId: true,
        encryptedText: true,
        type: true,
        fileUrl: true,
        status: true,
        createdAt: true,
        iv: true,
        aesKeyEncB64Url: true,
        version: true,
        fileName: true,
        fileType: true,
        fileSize: true,
        filePages: true,
        sender: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatar: true,
          },
        },
        reactions: {
          select: {
            id: true,
            emoji: true,
            userId: true,
            createdAt: true,
            // user: {
            //   select: {
            //     id: true,
            //     firstName: true,
            //     lastName: true,
            //     avatar: true,
            //   },
            // },
          },
        },
      },
    }),
    prisma.message.count({ where: whereClause }),
    prisma.groupKeyEnvelope.findMany({
      where: { groupId: id, userId },
      select: { version: true, aesKeyEncB64Url: true },
    }),
  ]);
  const envelopeMap = Object.fromEntries(
    envelopes.map((e) => [e.version, e.aesKeyEncB64Url]),
  );

  const enrichedMessages = messages.map((msg) => ({
    id: msg.id,
    conversationId: msg.conversationId,
    groupId: msg.groupId,
    encryptedText: msg.encryptedText,
    type: msg.type,
    fileUrl: msg.fileUrl,
    createdAt: msg.createdAt,
    status: msg?.status,
    senderId: msg.sender?.id || null,
    senderName: `${msg.sender?.firstName || ''} ${
      msg.sender?.lastName || ''
    }`.trim(),
    senderAvatar:
      msg.sender?.avatar || 'https://www.gravatar.com/avatar/?d=mp&s=200',
    isSenderYou: msg.sender?.id === userId,
    iv: msg?.iv || null,
    aesKeyEncB64Url: envelopeMap[msg.version] || null,
    thumbnail: msg?.fileName
      ? {
          fileName: msg.fileName,
          fileType: msg.fileType,
          fileSize: msg.fileSize,
          filePages: msg.filePages,
        }
      : null,
    reactions: msg.reactions || [],
  }));

  // console.log('enrichedMessages===>', enrichedMessages);

  return {
    data: enrichedMessages,
    pagination: {
      total,
      page: parseInt(page),
      limit: parseInt(limit),
      totalPages: Math.ceil(total / limit),
    },
  };
};

// exports.getChatListService = async ({ userId, page = 1, limit = 10 }) => {
//   if (!userId) throw { status: 400, message: 'userId is required' };
//   const skip = (page - 1) * limit;

//   const [conversations, groups, groupKeyEnvelopes] = await Promise.all([
//     prisma.conversation.findMany({
//       where: { members: { some: { userId } } },
//       include: {
//         members: {
//           include: {
//             user: {
//               select: {
//                 id: true,
//                 firstName: true,
//                 lastName: true,
//                 avatar: true,
//               },
//             },
//           },
//         },
//       },
//     }),
//     prisma.group.findMany({
//       where: {
//         members: { some: { userId } },
//         archived: false,
//       },
//       select: { id: true, name: true, profileImg: true },
//     }),
//     prisma.groupKeyEnvelope.findMany({
//       where: { userId },
//       select: { groupId: true, aesKeyEncB64Url: true, version: true },
//     }),
//   ]);

//   const convIds = conversations.map((c) => c.id);
//   const groupIds = groups.map((g) => g.id);

//   const lastMessages = await prisma.message.findMany({
//     where: {
//       OR: [{ conversationId: { in: convIds } }, { groupId: { in: groupIds } }],
//     },
//     orderBy: { createdAt: 'desc' },
//     distinct: ['conversationId', 'groupId'],
//     include: {
//       sender: { select: { id: true, firstName: true, lastName: true } },
//     },
//   });

//   const lastMsgMap = Object.fromEntries(
//     lastMessages.map((m) => [
//       m.conversationId || m.groupId,
//       {
//         id: m.id,
//         type: m.type,
//         content: m.encryptedText,
//         createdAt: m.createdAt,
//         isSenderYou: m.senderId === userId,
//         status: m.status || 'SENT',
//         sender: {
//           id: m.sender.id,
//           name: `${m.sender.firstName || ''} ${m.sender.lastName || ''}`.trim(),
//         },
//         iv: m?.iv || null,
//         aesKeyEncB64Url: m?.aesKeyEncB64Url || null,
//       },
//     ]),
//   );

//   const unreadByChat = await prisma.message.groupBy({
//     by: ['conversationId', 'groupId'],
//     where: { reads: { some: { userId, readAt: null } } },
//     _count: { id: true },
//   });

//   const unreadMap = Object.fromEntries(
//     unreadByChat.map((row) => [
//       row.conversationId || row.groupId,
//       row._count.id,
//     ]),
//   );

//   const conversationWithUnread = conversations.map((c) => {
//     const otherUser = c.members.find((m) => m.user.id !== userId)?.user;
//     return {
//       type: 'conversation',
//       id: c.id,
//       name: otherUser
//         ? `${otherUser.firstName || ''} ${otherUser.lastName || ''}`.trim()
//         : 'Chat',
//       avatar: otherUser?.avatar || null,
//       isGroup: false,
//       lastMessage: lastMsgMap[c.id] || null,
//       unreadCount: unreadMap[c.id] || 0,
//     };
//   });

//   const groupWithUnread = groups.map((g) => {
//     const groupKey = groupKeyEnvelopes.find((key) => key.groupId === g.id);
//     return {
//       type: 'group',
//       id: g.id,
//       name: g.name,
//       avatar: g.profileImg || null,
//       isGroup: true,
//       lastMessage: lastMsgMap[g.id] || null,
//       unreadCount: unreadMap[g.id] || 0,
//       groupKey: groupKey?.aesKeyEncB64Url || null,
//       version: groupKey?.version || null,
//     };
//   });

//   const allChats = [...conversationWithUnread, ...groupWithUnread].sort(
//     (a, b) =>
//       new Date(b.lastMessage?.createdAt || 0) -
//       new Date(a.lastMessage?.createdAt || 0),
//   );

//   const paginated = allChats.slice(skip, skip + limit);

//   return {
//     data: paginated,
//     pagination: {
//       page,
//       limit,
//       total: allChats.length,
//       totalPages: Math.ceil(allChats.length / limit),
//     },
//   };
// };

exports.getChatListService = async ({ userId, page = 1, limit = 10 }) => {
  if (!userId) {
    throw { status: 400, message: 'userId is required' };
  }

  try {
    const skip = (page - 1) * limit;

    // Fetch conversations, groups, and group key envelopes in parallel
    const [conversations, groups, groupKeyEnvelopes] = await Promise.all([
      prisma.conversation.findMany({
        where: { members: { some: { userId } } },
        include: {
          members: {
            include: {
              user: {
                select: {
                  id: true,
                  firstName: true,
                  lastName: true,
                  avatar: true,
                },
              },
            },
          },
        },
      }),
      prisma.group.findMany({
        where: {
          members: { some: { userId } },
          archived: false,
        },
        select: { id: true, name: true, profileImg: true },
      }),
      prisma.groupKeyEnvelope.findMany({
        where: { userId },
        select: {
          groupId: true,
          aesKeyEncB64Url: true,
          version: true,
          userId: true,
          createdAt: true,
        },
      }),
    ]);

    const convIds = conversations.map((c) => c.id);
    const groupIds = groups.map((g) => g.id);

    // --- Compute effective start date per group ---
    const memberships = await prisma.groupMember.findMany({
      where: { userId, groupId: { in: groupIds } },
      select: { groupId: true, joinedAt: true },
    });

    const effectiveStartMap = {};
    memberships.forEach((m) => {
      const envelope = groupKeyEnvelopes.find((e) => e.groupId === m.groupId);
      effectiveStartMap[m.groupId] = envelope
        ? new Date(Math.max(m.joinedAt.getTime(), envelope.createdAt.getTime()))
        : m.joinedAt;
    });

    // --- Fetch last messages (respect effectiveStart for groups) ---
    const lastMessages = await prisma.message.findMany({
      where: {
        OR: [
          { conversationId: { in: convIds } },
          ...groupIds.map((gid) => ({
            groupId: gid,
            createdAt: { gte: effectiveStartMap[gid] },
          })),
        ],
      },
      orderBy: { createdAt: 'desc' },
      distinct: ['conversationId', 'groupId'],
      include: {
        sender: { select: { id: true, firstName: true, lastName: true } },
        reactions: {
          select: {
            id: true,
            emoji: true,
            userId: true,
            createdAt: true,
            // user: {
            //   select: {
            //     id: true,
            //     firstName: true,
            //     lastName: true,
            //     avatar: true,
            //   },
            // },
          },
        },
      },
    });

    const lastMsgMap = Object.fromEntries(
      lastMessages.map((m) => [
        m.conversationId || m.groupId,
        {
          id: m.id,
          type: m.type,
          content: m.encryptedText,
          createdAt: m.createdAt,
          isSenderYou: m.senderId === userId,
          status: m.status || 'SENT',
          sender: {
            id: m.sender.id,
            name: `${m.sender.firstName || ''} ${
              m.sender.lastName || ''
            }`.trim(),
          },
          iv: m?.iv || null,
          aesKeyEncB64Url: m?.aesKeyEncB64Url || null,
          reactions: m.reactions || [],
        },
      ]),
    );

    // --- Compute unread counts ---
    const unreadByChat = await prisma.message.groupBy({
      by: ['conversationId', 'groupId'],
      where: { reads: { some: { userId, readAt: null } } },
      _count: { id: true },
    });

    const unreadMap = Object.fromEntries(
      unreadByChat.map((row) => [
        row.conversationId || row.groupId,
        row._count.id,
      ]),
    );

    // --- Format conversations ---
    const conversationWithUnread = conversations.map((c) => {
      const otherUser = c.members.find((m) => m.user.id !== userId)?.user;
      return {
        type: 'conversation',
        id: c.id,
        name: otherUser
          ? `${otherUser.firstName || ''} ${otherUser.lastName || ''}`.trim()
          : 'Chat',
        avatar: otherUser?.avatar || null,
        isGroup: false,
        lastMessage: lastMsgMap[c.id] || null,
        unreadCount: unreadMap[c.id] || 0,
      };
    });

    // --- Format groups ---
    const groupWithUnread = groups.map((g) => {
      const envelopesForGroup = groupKeyEnvelopes.filter(
        (key) => key.groupId === g.id && key.userId === userId,
      );

      // Pick the one with the highest version
      const groupKey = envelopesForGroup.reduce((latest, current) => {
        if (!latest) return current;
        return current.version > latest.version ? current : latest;
      }, null);
      return {
        type: 'group',
        id: g.id,
        name: g.name,
        avatar: g.profileImg || null,
        isGroup: true,
        lastMessage: lastMsgMap[g.id] || null,
        unreadCount: unreadMap[g.id] || 0,
        groupKey: groupKey?.aesKeyEncB64Url || null,
        version: groupKey?.version || null,
      };
    });

    // --- Merge + Sort by last message ---
    const allChats = [...conversationWithUnread, ...groupWithUnread].sort(
      (a, b) =>
        new Date(b.lastMessage?.createdAt || 0) -
        new Date(a.lastMessage?.createdAt || 0),
    );

    const paginated = allChats.slice(skip, skip + limit);

    return {
      data: paginated,
      pagination: {
        page,
        limit,
        total: allChats.length,
        totalPages: Math.ceil(allChats.length / limit),
      },
    };
  } catch (err) {
    console.error('getChatListService error:', err);
    throw { status: 500, message: 'Failed to fetch chat list' };
  }
};

exports.markAllAsRead = async (userId, type, chatId) => {
  if (!userId || !type || !chatId) {
    throw new Error('userId, type, and chatId are required');
  }

  const messageFilter =
    type === 'conversation'
      ? { conversationId: chatId }
      : type === 'group'
      ? { groupId: chatId }
      : (() => {
          throw new Error('Invalid type');
        })();

  // ✅ Step 1: Bulk update this user's unread messages
  const result = await prisma.messageRead.updateMany({
    where: {
      userId,
      readAt: null,
      message: { ...messageFilter },
    },
    data: { readAt: new Date() },
  });

  // ✅ Step 2: Fetch participants
  const participants =
    type === 'conversation'
      ? (
          await prisma.conversation.findUnique({
            where: { id: chatId },
            include: { members: true },
          })
        ).members.map((m) => m.userId)
      : (
          await prisma.group.findUnique({
            where: { id: chatId },
            include: { members: true },
          })
        ).members.map((m) => m.userId);

  // ✅ Step 3: Fetch only messages that are not marked READ yet
  const messages = await prisma.message.findMany({
    where: { ...messageFilter, status: { not: 'READ' } },
    include: { reads: true },
  });

  // ✅ Step 4: Collect messages that just became fully read
  const fullyRead = messages
    .filter((message) =>
      participants.every((pid) =>
        message.reads.some((r) => r.userId === pid && r.readAt !== null),
      ),
    )
    .map((m) => ({ id: m.id, senderId: m.senderId, status: 'READ' }));

  // ✅ Step 5: Notify only message senders (if active in this chat)
  if (fullyRead.length > 0) {
    await prisma.message.updateMany({
      where: { id: { in: fullyRead.map((m) => m.id) } },
      data: { status: 'READ' },
    });

    const io = getIO();

    for (const msg of fullyRead) {
      // const lastMsg = await prisma.message.findFirst({
      //   where: { ...messageFilter },
      //   orderBy: { createdAt: 'desc' },
      //   select: { id: true, senderId: true },
      // });

      io.to(`user_${msg.senderId}`).emit('chatlist_update', {
        chatId,
        type,
        lastMessageStatus: 'READ',
        lastMessageId: msg.id,
      });

      // find sender sockets
      const senderRoom = io.sockets.adapter.rooms.get(`user_${msg.senderId}`);
      if (senderRoom) {
        for (const socketId of senderRoom) {
          const senderSocket = io.sockets.sockets.get(socketId);

          // check if sender is actually viewing this chat
          if (senderSocket?.currentChatId === chatId) {
            senderSocket.emit('messages_update_status', {
              chatId,
              type,
              messages: [msg], // only their messages
            });
          }
        }
      }
    }
  }

  return { updated: result.count, messagesMarkedRead: fullyRead.length };
};

exports.ackDelivery = async (userId, type, chatId) => {
  const messageFilter =
    type === 'conversation'
      ? { conversationId: chatId }
      : type === 'group'
      ? { groupId: chatId }
      : (() => {
          throw new Error('Invalid type');
        })();

  // ✅ Step 1: Bulk update this user's unread messages
  const result = await prisma.messageRead.updateMany({
    where: {
      userId,
      deliveredAt: null,
      message: { ...messageFilter },
    },
    data: { deliveredAt: new Date() },
  });

  // ✅ Step 2: Fetch participants
  const participants =
    type === 'conversation'
      ? (
          await prisma.conversation.findUnique({
            where: { id: chatId },
            include: { members: true },
          })
        ).members.map((m) => m.userId)
      : (
          await prisma.group.findUnique({
            where: { id: chatId },
            include: { members: true },
          })
        ).members.map((m) => m.userId);

  // ✅ Step 3: Fetch only messages that are not marked READ yet
  const messages = await prisma.message.findMany({
    where: { ...messageFilter, status: { not: 'DELIVERED' } },
    include: { reads: true },
  });

  const fullyRead = messages
    .filter((message) =>
      participants.every((pid) =>
        message.reads.some((r) => r.userId === pid && r.deliveredAt !== null),
      ),
    )
    .map((m) => ({ id: m.id, senderId: m.senderId, status: 'DELIVERED' }));

  if (fullyRead.length > 0) {
    await prisma.message.updateMany({
      where: { id: { in: fullyRead.map((m) => m.id) } },
      data: { status: 'DELIVERED' },
    });

    const io = getIO();

    for (const msg of fullyRead) {
      // const lastMsg = await prisma.message.findFirst({
      //   where: { ...messageFilter },
      //   orderBy: { createdAt: 'desc' },
      //   select: { id: true, senderId: true },
      // });

      io.to(`user_${msg.senderId}`).emit('chatlist_update', {
        chatId,
        type,
        lastMessageStatus: 'DELIVERED',
        lastMessageId: msg.id,
      });

      // find sender sockets
      const senderRoom = io.sockets.adapter.rooms.get(`user_${msg.senderId}`);
      if (senderRoom) {
        for (const socketId of senderRoom) {
          const senderSocket = io.sockets.sockets.get(socketId);

          // check if sender is actually viewing this chat
          if (senderSocket?.currentChatId === chatId) {
            senderSocket.emit('messages_update_status', {
              chatId,
              type,
              messages: [msg],
            });
          }
        }
      }
    }
  }

  // // Optionally check if all delivered
  // const deliveredCount = await prisma.messageRead.count({
  //   where: { messageId, deliveredAt: { not: null } },
  // });
  // const totalCount = await prisma.messageRead.count({ where: { messageId } });

  // if (deliveredCount === totalCount) {
  //   const msg = await prisma.message.findUnique({
  //     where: { id: messageId },
  //     select: { groupId: true, conversationId: true },
  //   });
  //   if (msg.groupId) {
  //     getIO()
  //       .to(`group_${msg.groupId}`)
  //       .emit('message:all_delivered', { messageId });
  //   } else {
  //     getIO()
  //       .to(msg.conversationId)
  //       .emit('message:all_delivered', { messageId });
  //   }
  // }

  return { updated: result.count, messagesMarkedRead: fullyRead.length };
};
