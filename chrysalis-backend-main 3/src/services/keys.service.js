const prisma = require('../config/database');
const { encryptGskForUser } = require('../utils/encryption');

exports.uploadKeyBundle = async ({
  userId,
  publicKeyPem,
  privateKeyEnc,
  deviceId,
}) => {
  publicKeyPem = publicKeyPem.replace(/\\n/g, '\n');

  await prisma.userKey.upsert({
    where: {
      userId: userId,
    },
    update: {
      publicKey: publicKeyPem,
      privateKeyEnc: privateKeyEnc,
    },
    create: {
      userId: userId,
      publicKey: publicKeyPem,
      privateKeyEnc: privateKeyEnc,
    },
  });

  const pendingRequests = await prisma.keyRequest.findMany({
    where: {
      targetUserId: userId,
      status: 'PENDING',
    },
  });

  let fulfilledCount = 0;

  for (const reqItem of pendingRequests) {
    const group = await prisma.group.findUnique({
      where: { id: reqItem.groupId },
      select: { gskB64: true, version: true, id: true },
    });

    if (!group?.gskB64) continue;

    const gskBuffer = Buffer.from(group.gskB64, 'base64');
    const aesKeyEncB64Url = encryptGskForUser(gskBuffer, publicKeyPem);
    // const newVersion = (group.version || 0) + 1;

    await prisma.groupKeyEnvelope.create({
      data: {
        groupId: group.id,
        userId: userId,
        aesKeyEncB64Url,
        version: group.version,
      },
    });

    await prisma.keyRequest.update({
      where: { id: reqItem.id },
      data: { status: 'FULFILLED' },
    });

    fulfilledCount++;
  }

  return {
    deviceId,
    fulfilled: fulfilledCount,
  };
};
