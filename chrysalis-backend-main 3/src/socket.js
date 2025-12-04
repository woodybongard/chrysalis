const { Server } = require('socket.io');
const prisma = require('./config/database');
const { sendReactionPushNotification } = require('./utils/pushNotification');

let io;

const initSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: [
        '*',
        'https://chrysalisdental.tech',
        'https://api.chrysalisdental.tech',
        'http://localhost:3000',
        'http://localhost:3001'
      ],
      methods: ['GET', 'POST'],
      credentials: true
    },
  });

  io.on('connection', (socket) => {
    console.log(`🟢 User connected: ${socket.id}`);

    // Join a user-specific room
    socket.on('join_user_room', ({ userId }) => {
      socket.join(`user_${userId}`);
      console.log(`User ${userId} joined room user_${userId}`);
    });

    // Join all conversations user belongs to
    socket.on('join_conversation', async (data) => {
      const { conversationId, isgroup, userId } = data;
      if (!userId) {
        return console.error('join_conversation: Missing userId');
      }
      if (isgroup) {
        // Check if user is actually in the group
        const isMember = await prisma.groupMember.findFirst({
          where: { groupId: conversationId, userId },
        });

        if (!isMember) {
          return console.error(
            `User ${userId} is not in group ${conversationId}`,
          );
        }

        socket.join(`group_${conversationId}`);
        socket.userId = userId;
        socket.currentChatId = conversationId;
        console.log(`User is member now=>`);
        console.log(`User ${userId} joined group_${conversationId}`);
      } else {
        const conversations = await prisma.conversationMember.findMany({
          where: { userId },
          select: { conversationId: true },
        });

        conversations.forEach((conv) => {
          socket.join(conv.conversationId);
        });
        socket.userId = userId; // 🔑 attach userId to socket
        socket.currentChatId = `${type}:${conversationId}`;

        console.log(`User ${userId} joined ${conversations.length} rooms`);
      }
    });

    socket.on(
      'leave_conversation',
      async ({ conversationId, isgroup, userId }) => {
        if (!conversationId || !userId) {
          return console.error(
            'leave_conversation: Missing conversationId or userId',
          );
        }

        const roomName = isgroup ? `group_${conversationId}` : conversationId;
        socket.leave(roomName);
        console.log(`User ${userId} left ${roomName}`);

        // Optionally, notify other members
        socket.to(roomName).emit('user_left', { userId, conversationId });
      },
    );

    // Typing indicator
    socket.on('typing', async ({ conversationId, isgroup, userId }) => {
      let payload = { userId, conversationId };
      console.log('typing event received:', payload);

      if (isgroup) {
        const user = await prisma.user.findUnique({
          where: { id: userId },
          select: { firstName: true, lastName: true },
        });
        payload.name = user ? `${user.firstName} ${user.lastName}` : 'Someone';
      }

      // Emit to other conversation participants
      socket
        .to(isgroup ? `group_${conversationId}` : conversationId)
        .emit('user_typing', payload);

      let participants = [];
      if (isgroup) {
        const members = await prisma.groupMember.findMany({
          where: { groupId: conversationId },
          select: { userId: true },
        });
        participants = members.map((m) => m.userId);
      } else {
        const convo = await prisma.conversation.findUnique({
          where: { id: conversationId },
          select: { members: { select: { userId: true } } },
        });
        participants = convo?.members?.map((m) => m.userId) || [];
      }
      console.log('Participants:', participants);
      // Emit to all participants' user rooms except the typer
      participants.forEach((uid) => {
        if (uid !== userId) {
          io.to(`user_${uid}`).emit('user_typing_list', payload);
        }
      });
    });

    socket.on('stop_typing', async ({ conversationId, isgroup, userId }) => {
      let payload = { userId, conversationId };

      if (isgroup) {
        const user = await prisma.user.findUnique({
          where: { id: userId },
          select: { firstName: true, lastName: true },
        });
        payload.name = user ? `${user.firstName} ${user.lastName}` : 'Someone';
      }

      // Emit to participants in conversation (except sender)
      socket
        .to(isgroup ? `group_${conversationId}` : conversationId)
        .emit('user_stop_typing', payload);

      let participants = [];
      if (isgroup) {
        const members = await prisma.groupMember.findMany({
          where: { groupId: conversationId },
          select: { userId: true },
        });
        participants = members.map((m) => m.userId);
      } else {
        const convo = await prisma.conversation.findUnique({
          where: { id: conversationId },
          select: { members: { select: { userId: true } } },
        });
        participants = convo?.members?.map((m) => m.userId) || [];
      }
      console.log('Participants:', participants);
      // Emit to all participants' user rooms except the typer
      participants.forEach((uid) => {
        if (uid !== userId) {
          io.to(`user_${uid}`).emit('user_stop_typing_list', payload);
        }
      });
    });

    socket.on('message:delivered', async ({ messageId, userId, deviceId }) => {
      try {
        if (!messageId || !userId) {
          console.error('❌ message:delivered missing params', { messageId, userId });
          return;
        }

        const now = new Date();

        // Mark delivered for this user in MessageRead
        await prisma.messageRead.updateMany({
          where: { userId, messageId, deliveredAt: null },
          data: { deliveredAt: now },
        });

        // Update MessageDelivery record
        await prisma.messageDelivery.updateMany({
          where: { messageId, recipientId: userId },
          data: {
            status: 'DELIVERED',
            lastChannel: 'SOCKET',
            deliveredAt: now,
            lastDeviceId: deviceId || null,
          },
        });

        console.log(`✅ Marked message ${messageId} as delivered to user ${userId}`);

        // Get the message with its reads to check if all delivered
        const message = await prisma.message.findUnique({
          where: { id: messageId },
          include: { reads: true },
        });

        if (!message) {
          console.warn(`⚠️ Message ${messageId} not found`);
          return;
        }

        const chatId = message.conversationId || message.groupId;
        const type = message.conversationId ? 'conversation' : 'group';

        // Get all participants
        const participants = type === 'conversation'
          ? (await prisma.conversation.findUnique({
              where: { id: chatId },
              include: { members: true },
            }))?.members.map((m) => m.userId) || []
          : (await prisma.group.findUnique({
              where: { id: chatId },
              include: { members: true },
            }))?.members.map((m) => m.userId) || [];

        // Check if ALL participants have deliveredAt set
        const allDelivered = participants.every((pid) =>
          message.reads.some((r) => r.userId === pid && r.deliveredAt !== null)
        );

        if (allDelivered && message.status === 'SENT') {
          console.log(`📬 Message ${messageId} is now fully DELIVERED`);

          // Update message status to DELIVERED
          await prisma.message.update({
            where: { id: messageId },
            data: { status: 'DELIVERED' },
          });

          // Notify sender's chat list
          io.to(`user_${message.senderId}`).emit('chatlist_update', {
            chatId,
            type,
            lastMessageId: messageId,
            lastMessageStatus: 'DELIVERED',
          });

          // Notify sender if viewing messages
          io.to(`user_${message.senderId}`).emit('messages_update_status', {
            chatId,
            type,
            messages: [{ id: messageId, status: 'DELIVERED', senderId: message.senderId }],
          });

          // Broadcast to chat room
          const roomName = type === 'group' ? `group_${chatId}` : chatId;
          io.to(roomName).emit('message:all_delivered', {
            messageId,
            status: 'DELIVERED',
          });
        }
      } catch (err) {
        console.error('❌ Error in message:delivered handler:', err);
      }
    });

    socket.on('mark_read', async ({ chatId, type, messageId, userId }) => {
      try {
        if (!chatId || !type || !messageId || !userId) {
          console.error('❌ mark_read missing params', {
            chatId,
            type,
            messageId,
            userId,
          });
          return;
        }

        const now = new Date();

        // ✅ Step 1: Update read receipts for this user in MessageRead
        const result = await prisma.messageRead.upsert({
          where: {
            userId_messageId: {
              userId,
              messageId,
            },
          },
          update: { readAt: now },
          create: { userId, messageId, readAt: now },
        });

        // ✅ Step 1b: Update MessageDelivery record
        const existingDelivery = await prisma.messageDelivery.findUnique({
          where: { messageId_recipientId: { messageId, recipientId: userId } },
        });

        if (existingDelivery) {
          await prisma.messageDelivery.update({
            where: { messageId_recipientId: { messageId, recipientId: userId } },
            data: {
              status: 'READ',
              firstReadAt: existingDelivery.firstReadAt || now,
              lastReadAt: now,
              readCount: { increment: 1 },
            },
          });
        }

        console.log(
          `✅ Marked message ${messageId} as read by user ${userId}`,
          result,
        );

        // ✅ Step 2: Get participants (conversation or group)
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

        // ✅ Step 3: Fetch the message and its reads
        const message = await prisma.message.findUnique({
          where: { id: messageId },
          include: { reads: true },
        });

        if (!message) {
          console.warn(`⚠️ Message ${messageId} not found`);
          return;
        }

        // ✅ Step 4: Check if *all* participants have read this message
        const allRead = participants.every((pid) =>
          message.reads.some((r) => r.userId === pid && r.readAt !== null),
        );

        // Only update and notify if message is not already READ
        if (allRead && message.status !== 'READ') {
          console.log(`📩 Message ${messageId} is now fully READ`);

          // Update status in DB
          await prisma.message.update({
            where: { id: messageId },
            data: { status: 'READ' },
          });

          // ✅ Step 5a: Notify sender's chatlist
          io.to(`user_${message.senderId}`).emit('chatlist_update', {
            chatId,
            type,
            lastMessageId: messageId,
            lastMessageStatus: 'READ',
          });

          io.to(`user_${message.senderId}`).emit('messages_update_status', {
            chatId,
            type,
            messages: [
              { id: messageId, status: 'READ', senderId: message.senderId },
            ],
          });
        }
      } catch (err) {
        console.error('❌ Error in mark_read handler:', err);
      }
    });

    // Add reaction to a message (one reaction per user per message - like iMessage)
    socket.on('add_reaction', async ({ messageId, emoji, userId, chatId, isGroup }) => {
      try {
        if (!messageId || !emoji || !userId) {
          console.error('❌ add_reaction missing params', { messageId, emoji, userId });
          return;
        }

        // Upsert: Create new reaction or update existing one
        const reaction = await prisma.messageReaction.upsert({
          where: {
            messageId_userId: {
              messageId,
              userId,
            },
          },
          update: {
            emoji, // Update to new emoji
          },
          create: {
            messageId,
            userId,
            emoji,
          },
          include: {
            user: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                avatar: true,
              },
            },
            message: {
              select: {
                senderId: true,
              },
            },
          },
        });

        console.log(`✅ Reaction set: ${emoji} by ${userId} on message ${messageId}`);

        // Emit to the chat room
        const roomName = isGroup ? `group_${chatId}` : chatId;
        io.to(roomName).emit('reaction_added', {
          messageId,
          reaction: {
            id: reaction.id,
            emoji: reaction.emoji,
            userId: reaction.userId,
            user: reaction.user,
            createdAt: reaction.createdAt,
          },
        });

        // Also emit to user rooms for chat list updates
        const participants = isGroup
          ? (await prisma.groupMember.findMany({
              where: { groupId: chatId },
              select: { userId: true },
            })).map(m => m.userId)
          : (await prisma.conversationMember.findMany({
              where: { conversationId: chatId },
              select: { userId: true },
            })).map(m => m.userId);

        participants.forEach(uid => {
          io.to(`user_${uid}`).emit('reaction_added_notification', {
            chatId,
            isGroup,
            messageId,
            reaction: {
              id: reaction.id,
              emoji: reaction.emoji,
              userId: reaction.userId,
              user: reaction.user,
            },
          });
        });

        // Send push notification to message owner
        let chatName = '';
        if (isGroup) {
          const group = await prisma.group.findUnique({
            where: { id: chatId },
            select: { name: true },
          });
          chatName = group?.name || 'Group';
        }

        const reactorName = `${reaction.user.firstName || ''} ${reaction.user.lastName || ''}`.trim();

        // Send push notification (runs async, no await needed)
        sendReactionPushNotification({
          messageOwnerId: reaction.message.senderId,
          reactorId: userId,
          reactorName: reactorName || 'Someone',
          emoji,
          chatId,
          isGroup,
          chatName,
        });

      } catch (err) {
        console.error('❌ Error in add_reaction handler:', err);
        socket.emit('reaction_error', { error: 'Failed to add reaction' });
      }
    });

    // Remove reaction from a message
    socket.on('remove_reaction', async ({ messageId, userId, chatId, isGroup }) => {
      try {
        if (!messageId || !userId) {
          console.error('❌ remove_reaction missing params', { messageId, userId });
          return;
        }

        // Delete the reaction
        const deletedReaction = await prisma.messageReaction.delete({
          where: {
            messageId_userId: {
              messageId,
              userId,
            },
          },
        }).catch(() => null);

        if (!deletedReaction) {
          console.log(`⚠️ Reaction not found by ${userId} on ${messageId}`);
          return;
        }

        console.log(`✅ Reaction removed: ${deletedReaction.emoji} by ${userId} on message ${messageId}`);

        // Emit to the chat room
        const roomName = isGroup ? `group_${chatId}` : chatId;
        io.to(roomName).emit('reaction_removed', {
          messageId,
          emoji: deletedReaction.emoji,
          userId,
        });

        // Also emit to user rooms for chat list updates
        const participants = isGroup
          ? (await prisma.groupMember.findMany({
              where: { groupId: chatId },
              select: { userId: true },
            })).map(m => m.userId)
          : (await prisma.conversationMember.findMany({
              where: { conversationId: chatId },
              select: { userId: true },
            })).map(m => m.userId);

        participants.forEach(uid => {
          io.to(`user_${uid}`).emit('reaction_removed_notification', {
            chatId,
            isGroup,
            messageId,
            emoji: deletedReaction.emoji,
            userId,
          });
        });

      } catch (err) {
        console.error('❌ Error in remove_reaction handler:', err);
        socket.emit('reaction_error', { error: 'Failed to remove reaction' });
      }
    });

    socket.on('disconnect', () => {
      console.log(`🔴 User disconnected: ${socket.id}`);
    });
  });

  return io;
};

const getIO = () => {
  if (!io) throw new Error('Socket.io not initialized');
  return io;
};

module.exports = { initSocket, getIO };
