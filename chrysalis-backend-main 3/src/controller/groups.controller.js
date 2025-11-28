const groupService = require('../services/groups.service');
const prisma = require('../config/database');

exports.createGroup = async (req, res) => {
  try {
    const creatorId = req.user.id;
    const profileImg = req.file;
    const result = await groupService.createGroup(
      creatorId,
      req.body,
      profileImg,
    );
    res.status(201).json(result);
  } catch (error) {
    console.error('Create group error:', error);
    res
      .status(error.statusCode || 500)
      .json({ message: error.message || 'Failed to create group' });
  }
};

exports.addGroupMembers = async (req, res) => {
  try {
    const groupId = req.params.groupId;
    const result = await groupService.addGroupMembers(
      groupId,
      req.body.members,
    );
    res.status(200).json(result);
  } catch (error) {
    console.error('Add members error:', error);
    res
      .status(error.statusCode || 500)
      .json({ message: error.message || 'Failed to add members' });
  }
};

exports.removeGroupMember = async (req, res) => {
  try {
    const groupId = req.params.groupId;
    const userId = req.params.userId;

    const result = await groupService.removeGroupMember(groupId, userId);

    res.status(200).json({
      success: true,
      message: 'Member removed successfully',
    });
  } catch (error) {
    console.error('Remove member error:', error);
    res
      .status(error.statusCode || 500)
      .json({ message: error.message || 'Failed to remove member' });
  }
};

exports.listGroups = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;

    const result = await groupService.listGroups(page, limit);

    res.json({
      success: true,
      ...result, // includes total, page, limit, totalPages, groups
    });
  } catch (err) {
    console.error('Error listing groups:', err);
    next(err);
  }
};

exports.getGroupDetails = async (req, res, next) => {
  try {
    const { groupId } = req.params;
    const group = await groupService.getGroupDetails(groupId);

    if (!group) {
      const error = new Error('Group not found');
      error.statusCode = 404;
      throw error;
    }

    res.json({
      success: true,
      group,
    });
  } catch (err) {
    console.error('Error fetching group details:', err);
    next(err);
  }
};

exports.archiveGroup = async (req, res, next) => {
  try {
    const { groupId } = req.params;
    const group = await groupService.archiveGroup(groupId);

    if (!group) {
      const error = new Error('Group not found');
      error.statusCode = 404;
      throw error;
    }

    res.json({
      success: true,
      message: 'Group archived successfully',
      group,
    });
  } catch (err) {
    console.error('Error archiving group:', err);
    next(err);
  }
};

exports.unarchiveGroup = async (req, res, next) => {
  try {
    const { groupId } = req.params;
    const group = await groupService.unarchiveGroup(groupId);

    if (!group) {
      const error = new Error('Group not found');
      error.statusCode = 404;
      throw error;
    }

    res.json({
      success: true,
      message: 'Group unarchived successfully',
      group,
    });
  } catch (err) {
    console.error('Error unarchiving group:', err);
    next(err);
  }
};

exports.userNotInGroup = async (req, res) => {
  try {
    const { groupId, page = 1, limit = 10, search } = req.query;

    if (!groupId) {
      return res.status(400).json({ message: 'groupId is required' });
    }

    const result = await groupService.findUsersNotInGroup({
      groupId,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
      search,
    });

    return res.status(200).json({
      status: 200,
      ...result,
    });
  } catch (error) {
    console.error('Controller Error - userNotInGroup:', error);
    return res.status(500).json({ message: 'Internal Server Error' });
  }
};

exports.editGroup = async (req, res) => {
  const groupId = req.params.id;
  const { name, removeProfileImg } = req.body; // removeProfileImg: "true" if removing
  const profileImg = req.file; // multer parsed file

  if (!name && !profileImg && !removeProfileImg) {
    return res.status(400).json({
      message:
        'At least one field (name, profileImg, or removeProfileImg) must be provided',
    });
  }

  try {
    const updatedGroup = await groupService.editGroup({
      groupId,
      name,
      profileImg,
      removeProfileImg: removeProfileImg === 'true', // convert string to boolean
    });
    return res.json(updatedGroup);
  } catch (error) {
    console.error('Edit group error:', error);
    return res.status(500).json({ message: 'Failed to edit group' });
  }
};
