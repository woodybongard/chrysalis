const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const prisma = require('../config/database');

// Generate access token
const generateAccessToken = (userId, role) => {
  return jwt.sign(
    {
      userId,
      role,
      type: 'access',
      iat: Math.floor(Date.now() / 1000),
    },
    process.env.JWT_SECRET,
    {
      expiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
      issuer: 'chrysalis-api',
      audience: 'chrysalis-mobile',
    },
  );
};

// Generate refresh token
const generateRefreshToken = async (
  userId,
  deviceId = null,
  userAgent = null,
) => {
  const tokenId = uuidv4();
  const expiresIn = process.env.JWT_REFRESH_EXPIRES_IN || '7d';

  // Calculate expiration date
  const expiresAt = new Date();
  const days = parseInt(expiresIn.replace('d', ''));
  expiresAt.setDate(expiresAt.getDate() + days);

  // Create refresh token in database
  const refreshTokenRecord = await prisma.refreshToken.create({
    data: {
      id: tokenId,
      token: tokenId,
      userId,
      deviceId,
      userAgent,
      expiresAt,
    },
  });

  // Generate JWT with token ID
  const token = jwt.sign(
    {
      tokenId: refreshTokenRecord.id,
      userId,
      type: 'refresh',
      iat: Math.floor(Date.now() / 1000),
    },
    process.env.JWT_REFRESH_SECRET,
    {
      expiresIn,
      issuer: 'chrysalis-api',
      audience: 'chrysalis-mobile',
    },
  );

  return { token, tokenId: refreshTokenRecord.id, expiresAt };
};

// Verify access token
const verifyAccessToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_SECRET, {
      issuer: 'chrysalis-api',
      audience: 'chrysalis-mobile',
    });
  } catch (error) {
    throw new Error('Invalid or expired access token');
  }
};

// Verify refresh token
const verifyRefreshToken = async (token) => {
  try {
    // Verify JWT
    const decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET, {
      issuer: 'chrysalis-api',
      audience: 'chrysalis-mobile',
    });

    // Check if token exists in database and is not expired
    const refreshTokenRecord = await prisma.refreshToken.findFirst({
      where: {
        id: decoded.tokenId,
        expiresAt: {
          gt: new Date(),
        },
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            username: true,
            isActive: true,
          },
        },
      },
    });

    if (!refreshTokenRecord) {
      throw new Error('Refresh token not found or expired');
    }

    if (!refreshTokenRecord.user.isActive) {
      throw new Error('User account is deactivated');
    }

    return {
      tokenId: refreshTokenRecord.id,
      userId: refreshTokenRecord.userId,
      user: refreshTokenRecord.user,
    };
  } catch (error) {
    console.log(error);
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
    throw new Error('Invalid or expired refresh token');
  }
};

// Revoke refresh token
const revokeRefreshToken = async (tokenId) => {
  await prisma.refreshToken.delete({
    where: { id: tokenId },
  });
};

// Revoke all refresh tokens for a user
const revokeAllRefreshTokens = async (userId) => {
  await prisma.refreshToken.deleteMany({
    where: { userId },
  });
};

// Clean up expired refresh tokens
const cleanupExpiredTokens = async () => {
  const result = await prisma.refreshToken.deleteMany({
    where: {
      expiresAt: {
        lt: new Date(),
      },
    },
  });

  console.log(`🧹 Cleaned up ${result.count} expired refresh tokens`);
  return result.count;
};

// Extract token from Authorization header
const extractTokenFromHeader = (authHeader) => {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  return authHeader.substring(7);
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
  revokeRefreshToken,
  revokeAllRefreshTokens,
  cleanupExpiredTokens,
  extractTokenFromHeader,
};
