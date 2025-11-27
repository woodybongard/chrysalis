const userService = require('../services/user.service');

exports.getlist = async (req, res, next) => {
  try {
    const { query, page, limit } = req.query;

    const result = await userService.getlist({ query, page, limit });

    res.status(200).json(result);
  } catch (err) {
    console.error(err);
    if (err.status) {
      return res.status(err.status).json({
        success: false,
        message: err.message,
      });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getUserById = async (req, res, next) => {
  try {
    const userId = req.params.id;

    const result = await userService.getUserById(userId);

    res.status(200).json(result);
  } catch (err) {
    console.error(err);
    if (err.status) {
      return res.status(err.status).json({
        success: false,
        message: err.message,
      });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.updateProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const profileData = req.body;
    const avatar = req.file; // multer single file

    console.log(avatar);

    const result = await userService.updateProfile(userId, profileData, avatar);

    res.status(200).json(result);
  } catch (err) {
    console.error(err);
    if (err.status) {
      return res.status(err.status).json({
        success: false,
        message: err.message,
      });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.updateUserProfile = async (req, res, next) => {
  try {
    const { userId } = req.query;
    const profileData = req.body;
    const avatar = req.file; // multer single file

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'userId query parameter is required',
      });
    }

    const result = await userService.updateProfile(userId, profileData, avatar);

    res.status(200).json(result);
  } catch (err) {
    console.error(err);
    if (err.status) {
      return res.status(err.status).json({
        success: false,
        message: err.message,
      });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.updatePassword = async (req, res, next) => {
  try {
    const { userId, currentPassword, password } = req.body;
    if (!userId || !currentPassword || !password) {
      return res.status(400).json({
        success: false,
        message: 'userId, currentPassword, and password are required',
      });
    }

    // ✅ Password validation regex
    const passwordRegex =
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$/;

    if (!passwordRegex.test(password)) {
      return res.status(400).json({
        success: false,
        message:
          'Password must be at least 8 characters long, include 1 uppercase, 1 lowercase, 1 number, and 1 special character',
      });
    }

    const result = await userService.updatePassword(userId, currentPassword, password);

    res.status(200).json(result);
  } catch (err) {
    console.error(err);
    if (err.status) {
      return res.status(err.status).json({
        success: false,
        message: err.message,
      });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.toggleNotifications = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { isNotification } = req.body;

    const result = await userService.toggleNotifications(
      userId,
      isNotification,
    );

    res.status(200).json(result);
  } catch (err) {
    console.error(err);
    if (err.status) {
      return res.status(err.status).json({
        success: false,
        message: err.message,
      });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
