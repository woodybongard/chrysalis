// controllers/keyController.js
const keyService = require('../services/keys.service');

exports.uploadKeyBundle = async (req, res) => {
  try {
    const userId = req.user.id;
    const deviceId = req.headers['x-device-id'];
    let { publicKeyPem, privateKeyEnc } = req.body;

    if (!deviceId || !publicKeyPem) {
      return res
        .status(400)
        .json({ success: false, message: 'deviceId & publicKeyPem required' });
    }

    const keyBundle = await keyService.uploadKeyBundle({
      userId,
      publicKeyPem,
      privateKeyEnc,
    });

    res.status(200).json({
      success: true,
      message: 'Key bundle uploaded successfully',
      data: keyBundle,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
