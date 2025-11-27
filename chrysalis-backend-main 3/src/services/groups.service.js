const prisma = require('../config/database');
const { encryptGskForUser } = require('../utils/encryption');
const { uploadFile, deleteFile } = require('../utils/s3Upload');
const crypto = require('crypto');

exports.createGroup = async (creatorId, body, profileImg) => {
  let { name, members } = body;

  // Normalize members if passed as comma-separated string
  if (typeof members === 'string') {
    members = members
      .split(',')
      .map((id) => id.trim())
      .filter(Boolean);
  }

  if (!name || !Array.isArray(members) || members.length === 0) {
    const err = new Error('Name and members are required.');
    err.statusCode = 400;
    throw err;
  }

  // Upload profile image if provided
  const mediaUrl = profileImg
    ? await uploadFile(profileImg, profileImg.originalname, 'group_profiles')
    : null;

  // 🔹 Generate Group Shared Key (GSK)
  const gsk = crypto.randomBytes(32); // 256-bit AES key
  const gskB64 = gsk.toString('base64');

  // Create group with initial members
  const group = await prisma.group.create({
    data: {
      name,
      profileImg: mediaUrl,
      version: 1,
      gskB64, // stored for key distribution
      members: {
        create: [
          { userId: creatorId, role: 'ADMIN' },
          ...members.map((id) => ({ userId: id, role: 'MEMBER' })),
        ],
      },
    },
    include: {
      members: {
        include: { user: { include: { keys: true } } },
      },
    },
  });

  // Store initial GSK version in GroupKey table
  await prisma.groupKey.create({
    data: {
      groupId: group.id,
      version: 1,
      gskB64,
    },
  });

  const recipients = [];
  const pending = [];

  // Encrypt GSK for each member
  for (const m of group.members) {
    const userKey = m.user.keys;

    if (userKey?.publicKey) {
      try {
        const gskBuffer = Buffer.from(group.gskB64, 'base64');

        const aesKeyEncB64Url = encryptGskForUser(gskBuffer, userKey.publicKey);

        await prisma.groupKeyEnvelope.create({
          data: {
            groupId: group.id,
            userId: m.userId,
            aesKeyEncB64Url,
            version: 1,
          },
        });

        recipients.push({ userId: m.userId, distributed: true });
      } catch (error) {
        pending.push(m.userId);
      }
    } else {
      pending.push(m.userId);
    }
  }

  // Record key requests for users without public keys
  if (pending.length) {
    await prisma.keyRequest.createMany({
      data: pending.map((userId) => ({
        groupId: group.id,
        targetUserId: userId,
        version: 1,
        status: 'PENDING',
        requestedBy: 'system',
      })),
    });
  }

  return {
    groupId: group.id,
    name: group.name,
    profileImg: group.profileImg,
    distributed: recipients,
    pendingRequests: pending,
  };
};

exports.addGroupMembers = async (groupId, members) => {
  if (!Array.isArray(members) || members.length === 0) {
    const error = new Error('Members array is required');
    error.statusCode = 400;
    throw error;
  }

  const group = await prisma.group.findUnique({
    where: { id: groupId },
    include: {
      members: { include: { user: { include: { keys: true } } } },
      groupKeys: true,
    },
  });

  if (!group) {
    const error = new Error('Group not found');
    error.statusCode = 404;
    throw error;
  }

  // Add new members
  await prisma.groupMember.createMany({
    data: members.map((id) => ({
      groupId,
      userId: id,
      role: 'MEMBER',
    })),
    skipDuplicates: true,
  });

  // // 🔹 Rotate Group Shared Key (GSK)
  const newVersion = group.version + 1;
  // const newGsk = crypto.randomBytes(32);
  // const newGskB64 = newGsk.toString('base64');

  // // Store new group key version
  // await prisma.groupKey.create({
  //   data: {
  //     groupId,
  //     version: newVersion,
  //     gskB64: newGskB64,
  //   },
  // });

  // // Update group version
  await prisma.group.update({
    where: { id: groupId },
    data: { version: newVersion /* gskB64: newGskB64  */ },
  });

  const updatedGroup = await prisma.group.findUnique({
    where: { id: groupId },
    include: {
      members: { include: { user: { include: { keys: true } } } },
      groupKeys: true,
    },
  });

  const recipients = [];
  const pending = [];

  console.log(JSON.stringify(group, null, 2));
  // Create envelopes for ALL members (old + new)
  for (const m of updatedGroup.members) {
    const userKey = m.user.keys;
    console.log(userKey);
    if (userKey?.publicKey) {
      console.log('here');
      try {
        const gskBuffer = Buffer.from(updatedGroup.gskB64, 'base64');
        const aesKeyEncB64Url = encryptGskForUser(gskBuffer, userKey.publicKey);

        await prisma.groupKeyEnvelope.create({
          data: {
            groupId,
            userId: m.userId,
            aesKeyEncB64Url,
            version: newVersion,
          },
        });

        recipients.push({ userId: m.userId, distributed: true });
      } catch (err) {
        pending.push(m.userId);
      }
    } else {
      pending.push(m.userId);
    }
  }

  console.log('pending', pending);

  if (pending.length) {
    console.log('here 2');
    await prisma.keyRequest.createMany({
      data: pending.map((userId) => ({
        groupId,
        targetUserId: userId,
        version: newVersion,
        status: 'PENDING',
        requestedBy: 'system',
      })),
    });
  }

  return {
    groupId,
    newVersion,
    distributed: recipients,
    pendingRequests: pending,
  };
};

exports.removeGroupMember = async (groupId, userId) => {
  // 1. Find the group with current members & keys
  const group = await prisma.group.findUnique({
    where: { id: groupId },
    include: {
      members: { include: { user: { include: { keys: true } } } },
      groupKeys: true,
    },
  });

  if (!group) {
    const error = new Error('Group not found');
    error.statusCode = 404;
    throw error;
  }

  // 2. Verify member exists
  const member = await prisma.groupMember.findUnique({
    where: { userId_groupId: { userId, groupId } },
  });

  if (!member) {
    const error = new Error('User is not a member of the group');
    error.statusCode = 400;
    throw error;
  }

  // 3. Remove the member
  await prisma.groupMember.delete({
    where: { userId_groupId: { userId, groupId } },
  });

  // 4. Rotate Group Shared Key (GSK)
  const newVersion = group.version + 1;
  // const newGsk = crypto.randomBytes(32);
  // const newGskB64 = newGsk.toString('base64');

  // // Store new group key version
  // await prisma.groupKey.create({
  //   data: {
  //     groupId,
  //     version: newVersion,
  //     gskB64: newGskB64,
  //   },
  // });

  // Update group version
  await prisma.group.update({
    where: { id: groupId },
    data: { version: newVersion /*gskB64: newGskB64 */ },
  });

  const updatedGroup = await prisma.group.findUnique({
    where: { id: groupId },
    include: {
      members: { include: { user: { include: { keys: true } } } },
      groupKeys: true,
    },
  });

  const recipients = [];
  const pending = [];

  // 5. Distribute envelopes to remaining members
  for (const m of updatedGroup.members) {
    if (m.userId === userId) continue; // skip removed member

    const userKey = m.user.keys;
    if (userKey?.publicKey) {
      try {
        const gskBuffer = Buffer.from(updatedGroup.gskB64, 'base64');

        const aesKeyEncB64Url = encryptGskForUser(gskBuffer, userKey.publicKey);

        await prisma.groupKeyEnvelope.create({
          data: {
            groupId,
            userId: m.userId,
            aesKeyEncB64Url,
            version: newVersion,
          },
        });

        recipients.push({ userId: m.userId, distributed: true });
      } catch (err) {
        pending.push(m.userId);
      }
    } else {
      pending.push(m.userId);
    }
  }

  // 6. Create pending key requests if needed
  if (pending.length) {
    await prisma.keyRequest.createMany({
      data: pending.map((uid) => ({
        groupId,
        targetUserId: uid,
        version: newVersion,
        status: 'PENDING',
        requestedBy: 'system',
      })),
    });
  }

  // 7. Return result
  return {
    groupId,
    removedUserId: userId,
    newVersion,
    distributed: recipients,
    pendingRequests: pending,
  };
};

exports.listGroups = async (page = 1, limit = 20) => {
  const skip = (page - 1) * limit;

  const [groups, total] = await Promise.all([
    prisma.group.findMany({
      skip,
      take: limit,
      include: {
        _count: { select: { members: true } },
      },
      orderBy: { createdAt: 'desc' },
    }),
    prisma.group.count(),
  ]);

  return {
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit),
    groups,
  };
};

exports.getGroupDetails = async (groupId) => {
  const group = await prisma.group.findUnique({
    where: { id: groupId },
    include: {
      members: {
        include: {
          user: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              email: true,
              avatar: true,
            },
          },
        },
      },
      groupKeys: {
        orderBy: { version: 'desc' },
        take: 1,
      },
    },
  });

  return group;
};

exports.archiveGroup = async (groupId) => {
  const group = await prisma.group.update({
    where: { id: groupId },
    data: { archived: true },
  });
  return group;
};

exports.unarchiveGroup = async (groupId) => {
  const group = await prisma.group.update({
    where: { id: groupId },
    data: { archived: false },
  });
  return group;
};

exports.findUsersNotInGroup = async ({ groupId, page, limit, search }) => {
  try {
    const skip = (page - 1) * limit;

    const where = {
      role: 'USER',
      groupMemberships: {
        none: {
          groupId: groupId,
        },
      },
    };

    // Add search condition if provided
    if (search) {
      where.OR = [
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: {
          createdAt: 'desc',
        },
        select: {
          id: true,
          email: true,
          username: true,
          firstName: true,
          lastName: true,
          avatar: true,
        },
      }),
      prisma.user.count({ where }),
    ]);

    return {
      data: users,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  } catch (error) {
    console.error('Service Error - findUsersNotInGroup:', error);
    throw error;
  }
};

exports.editGroup = async ({ groupId, name, profileImg, removeProfileImg }) => {
  const group = await prisma.group.findUnique({ where: { id: groupId } });
  if (!group) throw new Error('Group not found');

  let mediaUrl = group.profileImg;

  if (removeProfileImg) {
    await deleteFile(group.profileImg);
    mediaUrl = null;
  } else if (profileImg) {
    // upload new image
    mediaUrl = await uploadFile(
      profileImg,
      profileImg.originalname,
      'group_profiles',
    );
  }

  const updatedGroup = await prisma.group.update({
    where: { id: groupId },
    data: {
      name: name ?? group.name,
      profileImg: mediaUrl,
    },
  });

  return updatedGroup;
};
