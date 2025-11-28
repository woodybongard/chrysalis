const express = require('express');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const rateLimit = require('express-rate-limit');
const { authorizeRoles } = require('../middleware/roles');

const prisma = require('../config/database');
const {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
  revokeRefreshToken,
  revokeAllRefreshTokens,
} = require('../utils/jwt');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Rate limiting for authentication endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // limit each IP to 10 requests per windowMs
  message: {
    success: false,
    error: {
      message: 'Too many authentication attempts, please try again later.',
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Validation rules
const registerValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email address'),
  body('username')
    .isLength({ min: 3, max: 30 })
    .isAlphanumeric()
    .withMessage(
      'Username must be 3-30 characters long and contain only letters and numbers',
    ),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage(
      'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character',
    ),
  body('firstName')
    .optional()
    .isLength({ min: 1, max: 50 })
    .withMessage('First name must be between 1 and 50 characters'),
  body('lastName')
    .optional()
    .isLength({ min: 1, max: 50 })
    .withMessage('Last name must be between 1 and 50 characters'),
];

const loginValidation = [
  body('login').notEmpty().withMessage('Email or username is required'),
  body('password').notEmpty().withMessage('Password is required'),
];

// Helper function to handle validation errors
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: {
        message: 'Validation failed',
        details: errors.array(),
      },
    });
  }
  next();
};

router.post(
  '/superadmin/register',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 8 }),
    body('username').isLength({ min: 4 }),
  ],
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { email, password, firstName, lastName, username } = req.body;

      const existingUser = await prisma.user.findFirst({
        where: {
          OR: [{ email }, { username }],
        },
      });

      if (existingUser) {
        return res.status(409).json({
          success: false,
          error: {
            message:
              existingUser.email === email
                ? 'Email already registered'
                : 'Username already taken',
          },
        });
      }
      // Hash password
      const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12;
      const hashedPassword = await bcrypt.hash(password, saltRounds);

      // Create SUPERADMIN user
      const user = await prisma.user.create({
        data: {
          email,
          username,
          password: hashedPassword,
          firstName,
          lastName,
          role: 'SUPERADMIN',
        },
        select: {
          id: true,
          email: true,
          username: true,
          firstName: true,
          lastName: true,
          isActive: true,
          isVerified: true,
          createdAt: true,
          role: true,
        },
      });

      // Generate tokens
      const accessToken = generateAccessToken(user.id);
      const deviceId = req.headers['x-device-id'] || null;
      const userAgent = req.headers['user-agent'] || null;
      const { token: refreshToken, expiresAt } = await generateRefreshToken(
        user.id,
        deviceId,
        userAgent,
      );

      // Return response
      res.status(201).json({
        success: true,
        message: 'CHRYSALIS_SUPERADMIN account created successfully',
        data: {
          user,
          tokens: {
            accessToken,
            refreshToken,
            expiresAt,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },
);

//Admin register
router.post(
  '/admin/create',
  // authenticate,
  // authorizeRoles('SUPERADMIN'),
  [
    body('email').isEmail().normalizeEmail(),
    body('username').isLength({ min: 3 }),
    body('password').isLength({ min: 8 }),
    // body('role').isIn(['CHRYSALIS_ADMIN', 'CHRYSALIS_SUPERADMIN']),
  ],
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { email, username, password, firstName, lastName } = req.body;

      console.log(req.body);

      const existingUser = await prisma.user.findFirst({
        where: {
          OR: [{ email }, { username }],
        },
      });

      if (existingUser) {
        return res.status(409).json({
          success: false,
          error: {
            message:
              existingUser.email === email
                ? 'Email already registered'
                : 'Username already taken',
          },
        });
      }

      const hashedPassword = await bcrypt.hash(
        password,
        parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12,
      );

      const user = await prisma.user.create({
        data: {
          email,
          username,
          password: hashedPassword,
          firstName,
          lastName,
          role: 'ADMIN',
        },
        select: {
          id: true,
          email: true,
          username: true,
          role: true,
          createdAt: true,
        },
      });

      res.status(201).json({
        success: true,
        message: `Admin account created successfully`,
        data: { user },
      });
    } catch (error) {
      next(error);
    }
  },
);

// Register User endpoint
router.post(
  '/register',
  // authLimiter,
  registerValidation,
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { email, username, password, firstName, lastName } = req.body;

      // Check if user already exists
      const existingUser = await prisma.user.findFirst({
        where: {
          OR: [{ email }, { username }],
        },
      });

      if (existingUser) {
        return res.status(409).json({
          success: false,
          error: {
            message:
              existingUser.email === email
                ? 'Email already registered'
                : 'Username already taken',
          },
        });
      }

      // Hash password
      const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12;
      const hashedPassword = await bcrypt.hash(password, saltRounds);

      // Create user
      const user = await prisma.user.create({
        data: {
          email,
          username,
          password: hashedPassword,
          firstName,
          lastName,
          role: 'USER',
        },
        select: {
          id: true,
          email: true,
          username: true,
          firstName: true,
          lastName: true,
          isActive: true,
          isVerified: true,
          createdAt: true,
          role: true,
        },
      });

      // Generate tokens
      const accessToken = generateAccessToken(user.id);
      const deviceId = req.headers['x-device-id'] || null;
      const userAgent = req.headers['user-agent'] || null;
      const { token: refreshToken, expiresAt } = await generateRefreshToken(
        user.id,
        deviceId,
        userAgent,
      );

      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: {
          user,
          tokens: {
            accessToken,
            refreshToken,
            expiresAt,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },
);

// Login endpoint
router.post(
  '/login',
  // authLimiter,
  loginValidation,
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { login, password, role, fcmToken, deviceType, deviceId } =
        req.body;

      // Find user by email or username
      const user = await prisma.user.findFirst({
        where: {
          role,
          OR: [{ email: login }, { username: login }],
        },
      });

      if (!user) {
        return res.status(401).json({
          success: false,
          error: {
            message: 'Invalid credentials',
          },
        });
      }

      // Check if user is active
      if (!user.isActive) {
        return res.status(401).json({
          success: false,
          error: {
            message: 'Account is deactivated',
          },
        });
      }

      // Verify password
      const isPasswordValid = await bcrypt.compare(password, user.password);
      if (!isPasswordValid) {
        return res.status(401).json({
          success: false,
          error: {
            message: 'Invalid credentials',
          },
        });
      }

      // Update last login
      await prisma.user.update({
        where: { id: user.id },
        data: { lastLogin: new Date() },
      });

      // const deviceId = req.headers['x-device-id'] || null;
      const userAgent = req.headers['user-agent'] || null;

      if (fcmToken) {
        if (!deviceId) {
          return res.status(400).json({
            success: false,
            error: {
              message: 'deviceId required',
            },
          });
        }

        const existing = await prisma.fcmToken.findFirst({
          where: { deviceId, userId: user.id },
        });

        if (existing) {
          await prisma.fcmToken.update({
            where: { id: existing.id },
            data: {
              token: fcmToken,
              deviceType: deviceType || null,
            },
          });
        } else {
          await prisma.fcmToken.create({
            data: {
              token: fcmToken,
              deviceType: deviceType || null,
              deviceId,
              userId: user.id,
            },
          });
        }
      }

      // Generate tokens
      const accessToken = generateAccessToken(user.id, user.role);

      const { token: refreshToken, expiresAt } = await generateRefreshToken(
        user.id,
        deviceId,
        userAgent,
      );

      const { password: _, ...userWithoutPassword } = user;

      let hasKeys = false;

      let device = await prisma.userKey.findUnique({
        where: { userId: user.id },
      });
      console.log('device', device);
      if (device && device?.publicKey) {
        hasKeys = true;
      }

      res.json({
        success: true,
        message: 'Login successful',
        data: {
          user: {
            ...userWithoutPassword,
          },
          tokens: {
            accessToken,
            refreshToken,
            expiresAt,
          },
          keys: {
            deviceId,
            hasKeys,
            publicKey: device?.publicKey || null,
            privateKey: device?.privateKeyEnc || null,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },
);

// Refresh token endpoint
router.post('/refresh', async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        error: {
          message: 'Refresh token is required',
        },
      });
    }

    // Verify refresh token
    const { tokenId, userId, user } = await verifyRefreshToken(refreshToken);

    // Generate new access token
    const newAccessToken = generateAccessToken(userId);

    // Optionally generate new refresh token (rotate refresh tokens)
    const deviceId = req.headers['x-device-id'] || null;
    const userAgent = req.headers['user-agent'] || null;

    // Revoke old refresh token
    await revokeRefreshToken(tokenId);

    // Generate new refresh token
    const { token: newRefreshToken, expiresAt } = await generateRefreshToken(
      userId,
      deviceId,
      userAgent,
    );

    res.json({
      success: true,
      message: 'Tokens refreshed successfully',
      data: {
        user,
        tokens: {
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          expiresAt,
        },
      },
    });
  } catch (error) {
    if (
      error.name === 'UnauthorizedError' ||
      error.message === 'Invalid or expired refresh token'
    ) {
      return res.status(401).json({
        success: false,
        error: {
          message: 'Invalid or expired refresh token',
        },
      });
    }
    next(error);
  }
});

// Logout endpoint
router.post('/logout', authenticate, async (req, res, next) => {
  try {
    const { refreshToken, fcmToken } = req.body;

    if (refreshToken) {
      try {
        const { tokenId } = await verifyRefreshToken(refreshToken);
        await revokeRefreshToken(tokenId);
      } catch (error) {
        // Token might already be invalid, continue with logout
      }
    }

    if (fcmToken) {
      await prisma.fcmToken.deleteMany({
        where: {
          token: fcmToken,
          userId: req.user.id,
          // ...(deviceId && { deviceType: deviceId }),
        },
      });
    }

    res.json({
      success: true,
      message: 'Logout successful',
    });
  } catch (error) {
    next(error);
  }
});

// Logout from all devices
router.post('/logout-all', authenticate, async (req, res, next) => {
  try {
    await revokeAllRefreshTokens(req.user.id);

    res.json({
      success: true,
      message: 'Logged out from all devices',
    });
  } catch (error) {
    next(error);
  }
});

// Get current user profile
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        email: true,
        username: true,
        firstName: true,
        lastName: true,
        avatar: true,
        isActive: true,
        isVerified: true,
        role: true,
        isNotification: true,
        lastLogin: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    res.json({
      success: true,
      data: { user },
    });
  } catch (error) {
    next(error);
  }
});

// Update user profile
router.put(
  '/me',
  authenticate,
  [
    body('firstName')
      .optional()
      .isLength({ min: 1, max: 50 })
      .withMessage('First name must be between 1 and 50 characters'),
    body('lastName')
      .optional()
      .isLength({ min: 1, max: 50 })
      .withMessage('Last name must be between 1 and 50 characters'),
  ],
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { firstName, lastName } = req.body;

      const user = await prisma.user.update({
        where: { id: req.user.id },
        data: {
          ...(firstName !== undefined && { firstName }),
          ...(lastName !== undefined && { lastName }),
        },
        select: {
          id: true,
          email: true,
          username: true,
          firstName: true,
          lastName: true,
          isActive: true,
          isVerified: true,
          lastLogin: true,
          createdAt: true,
          updatedAt: true,
        },
      });

      res.json({
        success: true,
        message: 'Profile updated successfully',
        data: { user },
      });
    } catch (error) {
      next(error);
    }
  },
);

// Change password
router.put(
  '/change-password',
  authenticate,
  [
    body('currentPassword')
      .notEmpty()
      .withMessage('Current password is required'),
    body('newPassword')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters long')
      .matches(
        /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/,
      )
      .withMessage(
        'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character',
      ),
  ],
  handleValidationErrors,
  async (req, res, next) => {
    try {
      const { currentPassword, newPassword } = req.body;

      // Get user with password
      const user = await prisma.user.findUnique({
        where: { id: req.user.id },
      });

      // Verify current password
      const isCurrentPasswordValid = await bcrypt.compare(
        currentPassword,
        user.password,
      );
      if (!isCurrentPasswordValid) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'Current password is incorrect',
          },
        });
      }

      // Hash new password
      const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12;
      const hashedNewPassword = await bcrypt.hash(newPassword, saltRounds);

      // Update password
      await prisma.user.update({
        where: { id: req.user.id },
        data: { password: hashedNewPassword },
      });

      // Revoke all refresh tokens to force re-authentication
      await revokeAllRefreshTokens(req.user.id);

      res.json({
        success: true,
        message: 'Password changed successfully. Please log in again.',
      });
    } catch (error) {
      next(error);
    }
  },
);

module.exports = router;
