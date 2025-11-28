const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID, // set in .env
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION,
});

exports.uploadToS3 = async (fileBuffer, originalName, folder = 'folder') => {
  const fileExtension = originalName.split('.').pop();
  const fileName = `${folder}/${uuidv4()}.${fileExtension}`;

  const params = {
    Bucket: process.env.AWS_S3_BUCKET_NAME,
    Key: fileName,
    Body: fileBuffer,
    ContentType: `application/octet-stream`,
  };

  await s3.upload(params).promise();
  return `https://${process.env.AWS_S3_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${fileName}`;
};

exports.uploadFile = async (file, userId, folder) => {
  const filePath = `${folder}/${userId}-${Date.now()}-${file.originalname}`;

  const uploadResult = await s3
    .upload({
      Bucket: process.env.AWS_S3_BUCKET_NAME,
      Key: filePath,
      Body: file.buffer,
      ContentType: file.mimetype,
    })
    .promise();

  return uploadResult.Location;
};

exports.fileUploadMessage = async (fileBuffer, fileName, mimeType) => {
  const params = {
    Bucket: process.env.AWS_S3_BUCKET_NAME,
    Key: fileName,
    Body: fileBuffer,
    ContentType: mimeType,
  };

  const result = await s3.upload(params).promise();
  return result.Location; // returns file URL
};

exports.deleteFile = async (fileUrl) => {
  if (!fileUrl) return;

  const bucketName = process.env.AWS_S3_BUCKET_NAME;
  const url = new URL(fileUrl);

  // Remove leading slash
  let Key = url.pathname.startsWith('/') ? url.pathname.slice(1) : url.pathname;

  // Sometimes URL may include bucket name (virtual-hosted style), remove it
  if (Key.startsWith(bucketName + '/')) {
    Key = Key.replace(`${bucketName}/`, '');
  }

  await s3
    .deleteObject({
      Bucket: bucketName,
      Key,
    })
    .promise();
};
