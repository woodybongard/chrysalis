/**
 * @swagger
 * /api/v1/groups:
 *   post:
 *     summary: Create a new group chat
 *     description: Creates a new group chat with the specified name, members, and optional profile image. The creator is automatically added as an admin.
 *     tags:
 *       - Groups
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - members
 *             properties:
 *               name:
 *                 type: string
 *                 description: Name of the group
 *                 example: "Project Team"
 *               members:
 *                 type: array
 *                 description: Array of user IDs to add to the group
 *                 items:
 *                   type: string
 *                   format: uuid
 *                 example: ["123e4567-e89b-12d3-a456-426614174000"]
 *               profileImg:
 *                 type: string
 *                 format: binary
 *                 description: Group profile image file (optional)
 *     responses:
 *       201:
 *         description: Group created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: string
 *                       format: uuid
 *                       example: "123e4567-e89b-12d3-a456-426614174000"
 *                     name:
 *                       type: string
 *                       example: "Project Team"
 *                     profileImg:
 *                       type: string
 *                       nullable: true
 *                       example: "https://storage.example.com/groups/profile123.jpg"
 *                     createdAt:
 *                       type: string
 *                       format: date-time
 *                     members:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           userId:
 *                             type: string
 *                             format: uuid
 *                           role:
 *                             type: string
 *                             enum: [ADMIN, MEMBER]
 *       400:
 *         description: Bad Request - Validation error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 error:
 *                   type: object
 *                   properties:
 *                     message:
 *                       type: string
 *                       example: "Name and members are required"
 *       413:
 *         description: Payload Too Large - File size exceeds limit
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 error:
 *                   type: object
 *                   properties:
 *                     message:
 *                       type: string
 *                       example: "File too large"
 *
 * /api/v1/groups/{groupId}/members:
 *   post:
 *     summary: Add members to a group
 *     description: Adds new members to an existing group chat
 *     tags:
 *       - Groups
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: ID of the group to add members to
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *     responses:
 *       200:
 *         description: Members added successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 added:
 *                   type: integer
 *                   description: Number of members added
 *                   example: 3
 *       400:
 *         description: Bad Request (validation error)
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Members array is required"
 *       401:
 *         description: Unauthorized (Missing or invalid token)
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Unauthorized"
 *       404:
 *         description: Group not found
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Group not found"
 *       500:
 *         description: Internal Server Error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Failed to add members"
 */

/**
 * @swagger
 * /api/v1/groups/{groupId}/members:
 *   post:
 *     summary: Add members to a group
 *     description: Adds one or more users as members of an existing group chat. This action will rotate the group key to maintain security.
 *     tags:
 *       - Groups
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: ID of the group to add members to
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - members
 *             properties:
 *               members:
 *                 type: array
 *                 items:
 *                   type: string
 *                   format: uuid
 *                 example:
 *                   - "123e4567-e89b-12d3-a456-426614174001"
 *                   - "123e4567-e89b-12d3-a456-426614174002"
 *     responses:
 *       200:
 *         description: Members added successfully and group key rotated
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 groupId:
 *                   type: string
 *                   format: uuid
 *                   example: "123e4567-e89b-12d3-a456-426614174000"
 *                 newVersion:
 *                   type: integer
 *                   example: 2
 *                 distributed:
 *                   type: array
 *                   description: Members who successfully received the new group key
 *                   items:
 *                     type: object
 *                     properties:
 *                       userId:
 *                         type: string
 *                         format: uuid
 *                       distributed:
 *                         type: boolean
 *                 pendingRequests:
 *                   type: array
 *                   description: Members for whom group key distribution is pending
 *                   items:
 *                     type: string
 *                     format: uuid
 *       400:
 *         description: Bad Request (Missing or invalid members array)
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Members array is required"
 *       401:
 *         description: Unauthorized (Missing or invalid token)
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Unauthorized"
 *       404:
 *         description: Group not found
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Group not found"
 *       500:
 *         description: Internal Server Error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Failed to add members"
 */
