const prisma = require('../config/database');

// exports.search = async (userId, { query, page = 1, limit = 10 }) => {
//   if (!query) {
//     const error = new Error('query is missing');
//     error.status = 400;
//     throw error;
//   }

//   page = parseInt(page, 10);
//   limit = parseInt(limit, 10);
//   const skip = (page - 1) * limit;

//   try {
//     const [groups, total] = await Promise.all([
//       prisma.group.findMany({
//         where: {
//           name: {
//             contains: query,
//             mode: 'insensitive',
//           },
//           members: {
//             some: { userId },
//           },
//         },
//         select: {
//           id: true,
//           name: true,
//           profileImg: true,
//           createdAt: true,
//           updatedAt: true,
//         },
//         orderBy: { createdAt: 'desc' },
//         skip,
//         take: limit,
//       }),
//       prisma.group.count({
//         where: {
//           name: {
//             contains: query,
//             mode: 'insensitive',
//           },
//           members: {
//             some: { userId },
//           },
//         },
//       }),
//     ]);

//     return {
//       status: true,
//       message: 'Groups fetched successfully',
//       pagination: {
//         total,
//         page,
//         limit,
//         totalPages: Math.ceil(total / limit),
//       },
//       data: groups,
//     };
//   } catch (error) {
//     console.error('Group search error:', error);
//     const err = new Error('Failed to search groups');
//     err.status = 500;
//     throw err;
//   }
// };

exports.search = async (userId, { query, page = 1, limit = 10 }) => {
  if (!query) {
    const error = new Error('query is missing');
    error.status = 400;
    throw error;
  }

  page = parseInt(page, 10);
  limit = parseInt(limit, 10);
  const skip = (page - 1) * limit;

  try {
    // 1. Fetch groups matching search
    const groups = await prisma.group.findMany({
      where: {
        name: {
          contains: query,
          mode: 'insensitive',
        },
        members: { some: { userId } },
      },
      select: {
        id: true,
        name: true,
        profileImg: true,
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    });

    const groupIds = groups.map((g) => g.id);

    // 2. Fetch group key envelopes for the user
    const groupKeyEnvelopes = await prisma.groupKeyEnvelope.findMany({
      where: { userId, groupId: { in: groupIds } },
      select: { groupId: true, aesKeyEncB64Url: true, version: true },
    });

    // 3. Fetch last messages for these groups
    const lastMessages = await prisma.message.findMany({
      where: { groupId: { in: groupIds } },
      orderBy: { createdAt: 'desc' },
      distinct: ['groupId'],
      include: {
        sender: { select: { id: true, firstName: true, lastName: true } },
      },
    });

    const lastMsgMap = Object.fromEntries(
      lastMessages.map((m) => [
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
            name: `${m.sender.firstName || ''} ${
              m.sender.lastName || ''
            }`.trim(),
          },
          iv: m?.iv || null,
          aesKeyEncB64Url: m?.aesKeyEncB64Url || null,
        },
      ]),
    );

    // 4. Fetch unread counts
    const unreadByGroup = await prisma.message.groupBy({
      by: ['groupId'],
      where: {
        groupId: { in: groupIds },
        reads: { some: { userId, readAt: null } },
      },
      _count: { id: true },
    });

    const unreadMap = Object.fromEntries(
      unreadByGroup.map((row) => [row.groupId, row._count.id]),
    );

    // 5. Map into unified response format
    const groupWithUnread = groups.map((g) => {
      const groupKey = groupKeyEnvelopes.find((key) => key.groupId === g.id);
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

    return {
      status: true,
      message: 'Groups fetched successfully',
      data: groupWithUnread,
      pagination: {
        total: groupWithUnread.length,
        page,
        limit,
        totalPages: Math.ceil(groupWithUnread.length / limit),
      },
    };
  } catch (error) {
    console.error('Group search error:', error);
    const err = new Error('Failed to search groups');
    err.status = 500;
    throw err;
  }
};

exports.addRecentSearch = async (userId, groupId) => {
  try {
    // Check if recent search already exists for this user + group
    const existing = await prisma.recentSearch.findFirst({
      where: { userId, groupId },
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
        data: { userId, groupId },
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
    // 1. Fetch recent searches with group reference
    const recentSearches = await prisma.recentSearch.findMany({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
      take: limit,
      include: {
        group: {
          select: {
            id: true,
            name: true,
            profileImg: true,
          },
        },
      },
    });

    const groups = recentSearches.map((rs) => rs.group).filter(Boolean); // exclude nulls if any

    const groupIds = groups.map((g) => g.id);

    // 2. Fetch group keys
    const groupKeyEnvelopes = await prisma.groupKeyEnvelope.findMany({
      where: { userId, groupId: { in: groupIds } },
      select: { groupId: true, aesKeyEncB64Url: true, version: true },
    });

    // 3. Fetch last messages
    const lastMessages = await prisma.message.findMany({
      where: { groupId: { in: groupIds } },
      orderBy: { createdAt: 'desc' },
      distinct: ['groupId'],
      include: {
        sender: { select: { id: true, firstName: true, lastName: true } },
      },
    });

    const lastMsgMap = Object.fromEntries(
      lastMessages.map((m) => [
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
            name: `${m.sender.firstName || ''} ${
              m.sender.lastName || ''
            }`.trim(),
          },
          iv: m?.iv || null,
          aesKeyEncB64Url: m?.aesKeyEncB64Url || null,
        },
      ]),
    );

    // 4. Fetch unread counts
    const unreadByGroup = await prisma.message.groupBy({
      by: ['groupId'],
      where: {
        groupId: { in: groupIds },
        reads: { some: { userId, readAt: null } },
      },
      _count: { id: true },
    });

    const unreadMap = Object.fromEntries(
      unreadByGroup.map((row) => [row.groupId, row._count.id]),
    );

    // 5. Format response
    const groupWithUnread = groups.map((g) => {
      const groupKey = groupKeyEnvelopes.find((key) => key.groupId === g.id);
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

    return {
      status: true,
      message: 'Recent searches fetched successfully',
      data: groupWithUnread,
      pagination: {
        total: groupWithUnread.length,
        limit,
        totalPages: Math.ceil(groupWithUnread.length / limit),
      },
    };
  } catch (error) {
    console.error('Get recent searches error:', error);
    const err = new Error('Failed to fetch recent searches');
    err.status = 500;
    throw err;
  }
};
