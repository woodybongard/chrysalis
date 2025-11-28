const multer = require('multer');
const storage = multer.memoryStorage(); // store file in memory before uploading to S3

const upload = multer({
  storage,
  limits: { fileSize: 20 * 1024 * 1024 }, // 20 MB limit
});

module.exports = upload;
