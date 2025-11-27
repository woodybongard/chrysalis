const bcryptjs = require('bcryptjs');
const prisma = require('../config/database');
const { uploadToS3, uploadFile, deleteFile } = require('../utils/s3Upload');

exports.getlist = async ({ query, page = 1, limit = 10 }) => {
  page = parseInt(page, 10);
  limit = parseInt(limit, 10);
  const skip = (page - 1) * limit;

  try {
    // 1. Fetch users excluding admins
    const users = await prisma.user.findMany({
      where: {
        role: { not: 'ADMIN' }, // exclude admins
        name: query
          ? {
              contains: query,
              mode: 'insensitive',
            }
          : undefined,
      },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        email: true,
        username: true,
        avatar: true,
        role: true,
        isActive: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    });

    // 2. Count total users (for pagination)
    const total = await prisma.user.count({
      where: {
        role: { not: 'ADMIN' },
        name: query
          ? {
              contains: query,
              mode: 'insensitive',
            }
          : undefined,
      },
    });

    return {
      status: true,
      message: 'Users fetched successfully',
      data: users,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  } catch (error) {
    console.error('User fetch error:', error);
    const err = new Error('Failed to fetch users');
    err.status = 500;
    throw err;
  }
};

exports.getUserById = async (userId) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        username: true,
        email: true,
        avatar: true,
        role: true,
        isActive: true,
        createdAt: true,
      },
    });

    if (!user) {
      const err = new Error('User not found');
      err.status = 404;
      throw err;
    }

    return {
      status: true,
      message: 'User fetched successfully',
      data: user,
    };
  } catch (error) {
    console.error('Get User By ID error:', error);
    if (error.status) throw error; // rethrow known errors
    const err = new Error('Failed to fetch user');
    err.status = 500;
    throw err;
  }
};

exports.updateProfile = async (userId, profileData, avatarFile) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      const err = new Error('User not found');
      err.status = 404;
      throw err;
    }

    // ✅ Check if username exists and belongs to a different user
    if (profileData.userName) {
      const existingUser = await prisma.user.findFirst({
        where: {
          username: profileData.userName,
          NOT: { id: userId },
        },
      });

      if (existingUser) {
        const err = new Error('Username already taken');
        err.status = 400;
        throw err;
      }
    }

    if (avatarFile) {
      const avatarUrl = await uploadFile(
        avatarFile,
        avatarFile.originalname,
        'avatars',
      );
      profileData.avatar = avatarUrl;
      await deleteFile(user.avatar);
    } else if (profileData.removeAvatar) {
      await deleteFile(user.avatar);
      profileData.avatar = null;
    }

    // Only allow firstName, lastName, avatar
    const allowedFields = {
      firstName: profileData.firstName,
      lastName: profileData.lastName,
      username: profileData.userName,
      avatar: profileData.avatar,
    };

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: allowedFields,
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

    return {
      status: true,
      message: 'Profile updated successfully',
      data: updatedUser,
    };
  } catch (error) {
    console.error('Update Profile Service Error:', error);
    if (error.status) throw error;
    const err = new Error('Failed to update profile');
    err.status = 500;
    throw err;
  }
};

exports.updatePassword = async (userId, currentPassword, newPassword) => {
  try {
    // Find user with current password
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, password: true },
    });

    if (!user) {
      const err = new Error('User not found');
      err.status = 404;
      throw err;
    }

    // Verify current password
    const isPasswordValid = await bcryptjs.compare(currentPassword, user.password);
    if (!isPasswordValid) {
      const err = new Error('Current password is incorrect');
      err.status = 400;
      throw err;
    }

    // Hash new password with bcryptjs
    const hashedPassword = await bcryptjs.hash(newPassword, 10);

    // Update user record in DB
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { password: hashedPassword },
    });

    return {
      success: true,
      message: 'Password updated successfully',
      userId: updatedUser.id,
    };
  } catch (error) {
    console.error('Error updating password:', error);
    if (error.status) throw error;
    const err = new Error('Failed to update password');
    err.status = 500;
    throw err;
  }
};

exports.toggleNotifications = async (userId, isNotification) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      const err = new Error('User not found');
      err.status = 404;
      throw err;
    }

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { isNotification: isNotification },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        username: true,
        email: true,
        avatar: true,
        isNotification: true,
        isActive: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return {
      status: true,
      message: 'Notification preference updated successfully',
      data: updatedUser,
    };
  } catch (error) {
    console.error('Toggle Notifications Service Error:', error);
    if (error.status) throw error;
    const err = new Error('Failed to update notification preference');
    err.status = 500;
    throw err;
  }
};
