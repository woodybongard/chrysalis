const prisma = require('../config/database');

exports.search = async (userId, { query, page = 1, limit = 10 }) => {
  if (!query) {
    const error = new Error('query is missing');
    error.status = 400;
    throw error;
  }

  page = parseInt(page, 10);
  limit = parseInt(limit, 10);

  try {
    // 1. Get all group IDs the user is a member of (for user search scope)
    const userGroupMemberships = await prisma.groupMember.findMany({
      where: { userId },
      select: { groupId: true },
    });
    const userGroupIds = userGroupMemberships.map((m) => m.groupId);

    // 2. Fetch groups, conversations, and users in parallel
    const [groups, conversations, users] = await Promise.all([
      // Groups matching search query
      prisma.group.findMany({
        where: {
          name: { contains: query, mode: 'insensitive' },
          members: { some: { userId } },
        },
        select: {
          id: true,
          name: true,
          profileImg: true,
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
      }),

      // 1:1 Conversations where the other member's name matches
      prisma.conversation.findMany({
        where: {
          isGroup: false,
          members: { some: { userId } },
        },
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

      // Users from shared groups matching the search query
      prisma.user.findMany({
        where: {
          id: { not: userId }, // Exclude self
          groupMemberships: {
            some: { groupId: { in: userGroupIds } },
          },
          OR: [
            { firstName: { contains: query, mode: 'insensitive' } },
            { lastName: { contains: query, mode: 'insensitive' } },
            { username: { contains: query, mode: 'insensitive' } },
          ],
        },
        select: {
          id: true,
          firstName: true,
          lastName: true,
          avatar: true,
          username: true,
          keys: { select: { publicKey: true } },
        },
        take: limit,
      }),
    ]);

    // Filter conversations where the OTHER member's name matches the query
    const filteredConversations = conversations.filter((conv) => {
      const otherMember = conv.members.find((m) => m.userId !== userId);
      if (!otherMember) return false;
      const fullName =
        `${otherMember.user.firstName || ''} ${otherMember.user.lastName || ''}`.toLowerCase();
      const username = (otherMember.user.username || '').toLowerCase();
      const q = query.toLowerCase();
      return fullName.includes(q) || username.includes(q);
    });

    const groupIds = groups.map((g) => g.id);
    const convIds = filteredConversations.map((c) => c.id);

    // 3. Fetch group key envelopes, last messages, and unread counts
    const [groupKeyEnvelopes, groupLastMessages, convLastMessages] =
      await Promise.all([
        prisma.groupKeyEnvelope.findMany({
          where: { userId, groupId: { in: groupIds } },
          select: { groupId: true, aesKeyEncB64Url: true, version: true },
        }),
        groupIds.length > 0
          ? prisma.message.findMany({
              where: { groupId: { in: groupIds } },
              orderBy: { createdAt: 'desc' },
              distinct: ['groupId'],
              include: {
                sender: {
                  select: { id: true, firstName: true, lastName: true },
                },
              },
            })
          : [],
        convIds.length > 0
          ? prisma.message.findMany({
              where: { conversationId: { in: convIds } },
              orderBy: { createdAt: 'desc' },
              distinct: ['conversationId'],
              include: {
                sender: {
                  select: { id: true, firstName: true, lastName: true },
                },
              },
            })
          : [],
      ]);

    // Build last message maps
    const groupLastMsgMap = Object.fromEntries(
      groupLastMessages.map((m) => [
        m.groupId,
        {
          id: m.id,
          type: m.type,
          content: m.encryptedText,
          createdAt: m.createdAt,
          isSenderYou: m.senderId === userId,
          status: m.status || 'SENT',
          sender: {
            id: m.sender.id,
            name: `${m.sender.firstName || ''} ${m.sender.lastName || ''}`.trim(),
          },
          iv: m?.iv || null,
          aesKeyEncB64Url: m?.aesKeyEncB64Url || null,
        },
      ]),
    );

    const convLastMsgMap = Object.fromEntries(
      convLastMessages.map((m) => [
        m.conversationId,
        {
          id: m.id,
          type: m.type,
          content: m.encryptedText,
          createdAt: m.createdAt,
          isSenderYou: m.senderId === userId,
          status: m.status || 'SENT',
          sender: {
            id: m.sender.id,
            name: `${m.sender.firstName || ''} ${m.sender.lastName || ''}`.trim(),
          },
          iv: m?.iv || null,
          aesKeyEncB64Url: m?.aesKeyEncB64Url || null,
        },
      ]),
    );

    // Fetch unread counts
    const [unreadByGroup, unreadByConv] = await Promise.all([
      groupIds.length > 0
        ? prisma.message.groupBy({
            by: ['groupId'],
            where: {
              groupId: { in: groupIds },
              reads: { some: { userId, readAt: null } },
            },
            _count: { id: true },
          })
        : [],
      convIds.length > 0
        ? prisma.message.groupBy({
            by: ['conversationId'],
            where: {
              conversationId: { in: convIds },
              reads: { some: { userId, readAt: null } },
            },
            _count: { id: true },
          })
        : [],
    ]);

    const groupUnreadMap = Object.fromEntries(
      unreadByGroup.map((row) => [row.groupId, row._count.id]),
    );
    const convUnreadMap = Object.fromEntries(
      unreadByConv.map((row) => [row.conversationId, row._count.id]),
    );

    // 4. Format results
    const groupResults = groups.map((g) => {
      const groupKey = groupKeyEnvelopes.find((key) => key.groupId === g.id);
      return {
        type: 'group',
        id: g.id,
        name: g.name,
        avatar: g.profileImg || null,
        isGroup: true,
        lastMessage: groupLastMsgMap[g.id] || null,
        unreadCount: groupUnreadMap[g.id] || 0,
        groupKey: groupKey?.aesKeyEncB64Url || null,
        version: groupKey?.version || null,
      };
    });

    const conversationResults = filteredConversations.map((conv) => {
      const otherMember = conv.members.find((m) => m.userId !== userId);
      return {
        type: 'conversation',
        id: conv.id,
        name: `${otherMember?.user.firstName || ''} ${otherMember?.user.lastName || ''}`.trim(),
        avatar: otherMember?.user.avatar || null,
        isGroup: false,
        otherUserId: otherMember?.user.id || null,
        lastMessage: convLastMsgMap[conv.id] || null,
        unreadCount: convUnreadMap[conv.id] || 0,
        convoKeyEnc: conv.convoKeyEnc || null,
      };
    });

    const userResults = users.map((u) => ({
      type: 'user',
      id: u.id,
      name: `${u.firstName || ''} ${u.lastName || ''}`.trim(),
      username: u.username || null,
      avatar: u.avatar || null,
      publicKey: u.keys?.publicKey || null,
    }));

    // Combine and paginate
    const allResults = [...groupResults, ...conversationResults, ...userResults];
    const skip = (page - 1) * limit;
    const paginatedResults = allResults.slice(skip, skip + limit);

    return {
      status: true,
      message: 'Search completed successfully',
      data: paginatedResults,
      pagination: {
        total: allResults.length,
        page,
        limit,
        totalPages: Math.ceil(allResults.length / limit),
      },
    };
  } catch (error) {
    console.error('Search error:', error);
    const err = new Error('Failed to search');
    err.status = 500;
    throw err;
  }
};

exports.addRecentSearch = async (
  userId,
  { groupId, conversationId, searchedUserId },
) => {
  try {
    // Validate that exactly one target is provided
    const targets = [groupId, conversationId, searchedUserId].filter(Boolean);
    if (targets.length !== 1) {
      const error = new Error(
        'Exactly one of groupId, conversationId, or searchedUserId is required',
      );
      error.status = 400;
      throw error;
    }

    let whereClause;
    let createData = { userId };

    if (groupId) {
      whereClause = { userId, groupId };
      createData.groupId = groupId;
    } else if (conversationId) {
      whereClause = { userId, conversationId };
      createData.conversationId = conversationId;
    } else {
      whereClause = { userId, searchedUserId };
      createData.searchedUserId = searchedUserId;
    }

    // Check if recent search already exists
    const existing = await prisma.recentSearch.findFirst({
      where: whereClause,
    });

    let recentSearch;
    if (existing) {
      // Update the timestamp instead of adding new row
      recentSearch = await prisma.recentSearch.update({
        where: { id: existing.id },
        data: { updatedAt: new Date() },
      });
    } else {
      // Create a new entry
      recentSearch = await prisma.recentSearch.create({
        data: createData,
      });
    }

    return {
      status: true,
      message: 'Recent search saved successfully',
      data: recentSearch,
    };
  } catch (error) {
    console.error('Add recent search error:', error);
    throw error;
  }
};

exports.getRecentSearches = async (userId, limit = 10) => {
  try {
    // 1. Fetch recent searches with all references
    const recentSearches = await prisma.recentSearch.findMany({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
      take: limit,
      include: {
        group: {
          select: { id: true, name: true, profileImg: true },
        },
        conversation: {
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
        },
        searchedUser: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatar: true,
            username: true,
            keys: { select: { publicKey: true } },
          },
        },
      },
    });

    // Separate by type
    const groupSearches = recentSearches.filter((rs) => rs.group);
    const convSearches = recentSearches.filter((rs) => rs.conversation);

    const groupIds = groupSearches.map((rs) => rs.group.id);
    const convIds = convSearches.map((rs) => rs.conversation.id);

    // 2. Fetch group keys, last messages, and unread counts in parallel
    const [groupKeyEnvelopes, groupLastMessages, convLastMessages] =
      await Promise.all([
        groupIds.length > 0
          ? prisma.groupKeyEnvelope.findMany({
              where: { userId, groupId: { in: groupIds } },
              select: { groupId: true, aesKeyEncB64Url: true, version: true },
            })
          : [],
        groupIds.length > 0
          ? prisma.message.findMany({
              where: { groupId: { in: groupIds } },
              orderBy: { createdAt: 'desc' },
              distinct: ['groupId'],
              include: {
                sender: {
                  select: { id: true, firstName: true, lastName: true },
                },
              },
            })
          : [],
        convIds.length > 0
          ? prisma.message.findMany({
              where: { conversationId: { in: convIds } },
              orderBy: { createdAt: 'desc' },
              distinct: ['conversationId'],
              include: {
                sender: {
                  select: { id: true, firstName: true, lastName: true },
                },
              },
            })
          : [],
      ]);

    // Build last message maps
    const groupLastMsgMap = Object.fromEntries(
      groupLastMessages.map((m) => [
        m.groupId,
        {
          id: m.id,
          type: m.type,
          content: m.encryptedText,
          createdAt: m.createdAt,
          isSenderYou: m.senderId === userId,
          status: m.status || 'SENT',
          sender: {
            id: m.sender.id,
            name: `${m.sender.firstName || ''} ${m.sender.lastName || ''}`.trim(),
          },
          iv: m?.iv || null,
          aesKeyEncB64Url: m?.aesKeyEncB64Url || null,
        },
      ]),
    );

    const convLastMsgMap = Object.fromEntries(
      convLastMessages.map((m) => [
        m.conversationId,
        {
          id: m.id,
          type: m.type,
          content: m.encryptedText,
          createdAt: m.createdAt,
          isSenderYou: m.senderId === userId,
          status: m.status || 'SENT',
          sender: {
            id: m.sender.id,
            name: `${m.sender.firstName || ''} ${m.sender.lastName || ''}`.trim(),
          },
          iv: m?.iv || null,
          aesKeyEncB64Url: m?.aesKeyEncB64Url || null,
        },
      ]),
    );

    // Fetch unread counts
    const [unreadByGroup, unreadByConv] = await Promise.all([
      groupIds.length > 0
        ? prisma.message.groupBy({
            by: ['groupId'],
            where: {
              groupId: { in: groupIds },
              reads: { some: { userId, readAt: null } },
            },
            _count: { id: true },
          })
        : [],
      convIds.length > 0
        ? prisma.message.groupBy({
            by: ['conversationId'],
            where: {
              conversationId: { in: convIds },
              reads: { some: { userId, readAt: null } },
            },
            _count: { id: true },
          })
        : [],
    ]);

    const groupUnreadMap = Object.fromEntries(
      unreadByGroup.map((row) => [row.groupId, row._count.id]),
    );
    const convUnreadMap = Object.fromEntries(
      unreadByConv.map((row) => [row.conversationId, row._count.id]),
    );

    // 3. Format results preserving the original order
    const results = recentSearches.map((rs) => {
      if (rs.group) {
        const g = rs.group;
        const groupKey = groupKeyEnvelopes.find((key) => key.groupId === g.id);
        return {
          type: 'group',
          id: g.id,
          name: g.name,
          avatar: g.profileImg || null,
          isGroup: true,
          lastMessage: groupLastMsgMap[g.id] || null,
          unreadCount: groupUnreadMap[g.id] || 0,
          groupKey: groupKey?.aesKeyEncB64Url || null,
          version: groupKey?.version || null,
        };
      } else if (rs.conversation) {
        const conv = rs.conversation;
        const otherMember = conv.members.find((m) => m.userId !== userId);
        return {
          type: 'conversation',
          id: conv.id,
          name: `${otherMember?.user.firstName || ''} ${otherMember?.user.lastName || ''}`.trim(),
          avatar: otherMember?.user.avatar || null,
          isGroup: false,
          otherUserId: otherMember?.user.id || null,
          lastMessage: convLastMsgMap[conv.id] || null,
          unreadCount: convUnreadMap[conv.id] || 0,
          convoKeyEnc: conv.convoKeyEnc || null,
        };
      } else if (rs.searchedUser) {
        const u = rs.searchedUser;
        return {
          type: 'user',
          id: u.id,
          name: `${u.firstName || ''} ${u.lastName || ''}`.trim(),
          username: u.username || null,
          avatar: u.avatar || null,
          publicKey: u.keys?.publicKey || null,
        };
      }
      return null;
    }).filter(Boolean);

    return {
      status: true,
      message: 'Recent searches fetched successfully',
      data: results,
      pagination: {
        total: results.length,
        limit,
        totalPages: Math.ceil(results.length / limit),
      },
    };
  } catch (error) {
    console.error('Get recent searches error:', error);
    const err = new Error('Failed to fetch recent searches');
    err.status = 500;
    throw err;
  }
};
