const NodeClam = require('clamscan');
const crypto = require('crypto');
const { uploadToS3, fileUploadMessage } = require('./s3Upload');
const prisma = require('../config/database');
const { Readable } = require('stream');

// ---------- Encryption Config ----------
const ALGORITHM = 'aes-256-cbc';
const IV_LENGTH = 16; // AES block size

function encryptBuffer(buffer, keyBuf, ivBuf) {
  if (keyBuf.length !== 32) {
    throw new Error('Encryption key must be 32 bytes for AES-256-CBC');
  }
  const cipher = crypto.createCipheriv(ALGORITHM, keyBuf, ivBuf);
  const encrypted = Buffer.concat([cipher.update(buffer), cipher.final()]);
  return { encrypted, iv: ivBuf };
}

// ---------- File Scan + Encrypt + Upload ----------
async function scanAndUploadFile(file, groupId, ivBase64) {
  try {
    if (!file || !file.buffer) {
      throw new Error('No file buffer provided');
    }

    // 1. Init ClamAV
    const clamscan = await new NodeClam().init({
      clamdscan: {
        socket: '/var/run/clamav/clamd.ctl',
        host: false,
        port: false,
        timeout: 60000,
        local_fallback: true,
      },
    });

    // 2. Scan Buffer
    const stream = Readable.from(file.buffer);
    const { isInfected, viruses } = await clamscan.scanStream(stream);

    if (isInfected) {
      throw new Error(`File is infected: ${viruses.join(', ')}`);
    }

    // 3. Get Group Key
    const group = await prisma.group.findUnique({
      where: { id: groupId },
    });
    if (!group?.gskB64) {
      throw new Error('Group encryption key not found');
    }

    const gskBuf = Buffer.from(group.gskB64, 'base64'); // must be 32 bytes

    // 4. Prepare IV (use provided one or generate new)
    const ivBuf = ivBase64
      ? Buffer.from(ivBase64, 'base64')
      : crypto.randomBytes(IV_LENGTH);
    if (ivBuf.length !== IV_LENGTH) {
      throw new Error(`IV must be ${IV_LENGTH} bytes`);
    }

    // 5. Encrypt File
    const { encrypted, iv } = encryptBuffer(file.buffer, gskBuf, ivBuf);

    // 6. Upload encrypted file to S3
    const safeName = (file.originalname || 'upload.bin').replace(
      /[^\w.\-]+/g,
      '_',
    );
    const fileKey = `chat_files/${Date.now()}_${safeName}.enc`;

    const fileUrl = await fileUploadMessage(encrypted, fileKey, file.mimetype);

    return {
      fileUrl,
      iv: iv.toString('base64'), // return IV in base64
      alg: ALGORITHM,
    };
  } catch (err) {
    console.error('File Upload Error:', err);
    throw err;
  }
}

module.exports = { scanAndUploadFile };
