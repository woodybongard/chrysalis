const NodeClam = require('clamscan');
const { uploadToS3, fileUploadMessage } = require('./s3Upload');
const prisma = require('../config/database');
const { Readable } = require('stream');

async function scanAndUploadFile(file, groupId) {
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

    // 3. (Optional: you can remove group lookup entirely if unused)
    const group = await prisma.group.findUnique({
      where: { id: groupId },
    });

    // 4. Create safe file name
    const safeName = (file.originalname || 'upload.bin').replace(
      /[^\w.\-]+/g,
      '_',
    );

    const fileKey = `chat_files/${Date.now()}_${safeName}`;

    // 5. Upload RAW FILE, NO ENCRYPTION
    const fileUrl = await fileUploadMessage(file.buffer, fileKey, file.mimetype);

    return {
      fileUrl,
      encrypted: false,
    };
  } catch (err) {
    console.error('File Upload Error:', err);
    throw err;
  }
}

module.exports = { scanAndUploadFile };
