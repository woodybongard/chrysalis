const express = require('express');
const router = express.Router();
const groupController = require('../controller/groups.controller');
const { authenticate } = require('../middleware/auth');
const { authorizeRoles } = require('../middleware/roles');
const upload = require('../middleware/upload');

router.post(
  '/',
  authenticate,
  //   authorizeRoles(['ADMIN']),
  upload.single('profileImg'),
  groupController.createGroup,
);
router.post(
  '/:groupId/members',
  authenticate,
  // authorizeRoles,
  groupController.addGroupMembers,
);
router.delete(
  '/members/:groupId/:userId',
  authenticate,
  // authorizeRoles,
  groupController.removeGroupMember,
);
router.get('/', groupController.listGroups);
router.get('/userNotInGroup', groupController.userNotInGroup);
router.get('/:groupId', groupController.getGroupDetails);
router.patch('/:groupId/archive', groupController.archiveGroup);
router.patch('/:groupId/unarchive', groupController.unarchiveGroup);
router.patch('/:id', upload.single('profileImg'), groupController.editGroup);

module.exports = router;
