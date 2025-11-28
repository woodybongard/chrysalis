const crypto = require('crypto');

function encryptGskForUser(gsk, publicKey) {
  try {
    const encrypted = crypto.publicEncrypt(
      {
        key: publicKey,
        padding: crypto.constants.RSA_PKCS1_PADDING,
      },
      gsk,
    );

    return encrypted.toString('base64');
  } catch (error) {
    console.error('Encryption failed:', error);
    throw error;
  }
}
module.exports = { encryptGskForUser };
