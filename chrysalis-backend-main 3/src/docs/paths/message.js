/**
 * @swagger
 * /api/v1/messages/send:
 *   post:
 *     summary: Send a message to a user (1-on-1 chat)
 *     tags:
 *       - Messages
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             $ref: '#/components/schemas/SendMessageRequest'
 *     responses:
 *       201:
 *         description: Message sent successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Message sent successfully
 *                 data:
 *                   type: object
 *                   properties:
 *                     message:
 *                       $ref: '#/components/schemas/MessageResponse'
 *       400:
 *         description: Bad Request (e.g., sending message to yourself or validation error)
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
 *                       example: Cannot send message to yourself
 *       401:
 *         description: Unauthorized (Missing or invalid token)
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
 *                       example: Unauthorized
 *       500:
 *         description: Internal Server Error
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
 *                       example: Internal Server Error
 */

/**
 * @swagger
 * /api/v1/messages:
 *   get:
 *     summary: Get messages for a conversation or group chat with pagination
 *     tags:
 *       - Messages
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: type
 *         required: true
 *         schema:
 *           type: string
 *           enum: [conversation, group]
 *         description: Type of chat (conversation for 1-on-1, group for group chat)
 *       - in: query
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: ID of the conversation or group
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *           default: 1
 *         description: Page number for pagination
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 20
 *         description: Number of messages per page
 *     responses:
 *       200:
 *         description: Messages retrieved successfully
 *         headers:
 *           X-Total-Count:
 *             schema:
 *               type: integer
 *             description: Total number of messages
 *           X-Page-Size:
 *             schema:
 *               type: integer
 *             description: Number of messages per page
 *           X-Current-Page:
 *             schema:
 *               type: integer
 *             description: Current page number
 *           X-Total-Pages:
 *             schema:
 *               type: integer
 *             description: Total number of pages
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
 *                     messages:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/MessageResponse'
 *                     pagination:
 *                       type: object
 *                       properties:
 *                         totalCount:
 *                           type: integer
 *                           example: 157
 *                         pageSize:
 *                           type: integer
 *                           example: 20
 *                         currPage:
 *                           type: integer
 *                           example: 1
 *                         totalPages:
 *                           type: integer
 *                           example: 8
 *       400:
 *         description: Bad Request (validation error)
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
 *                       example: Validation failed
 *                     details:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           param:
 *                             type: string
 *                           msg:
 *                             type: string
 *       401:
 *         description: Unauthorized (Missing or invalid token)
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
 *                       example: Unauthorized
 *       403:
 *         description: Forbidden (Not a member of the conversation or group)
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
 *                       example: You are not a member of this conversation
 *       500:
 *         description: Internal Server Error
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
 *                       example: Internal Server Error
 */

/**
 * @swagger
 * /api/v1/messages/chat-list:
 *   get:
 *     summary: Get a list of all chats (conversations and groups) for the authenticated user
 *     description: Retrieves all conversations and group chats that the user is a member of, with the most recent message for each
 *     tags:
 *       - Messages
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *           default: 1
 *         description: Page number for pagination
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 10
 *         description: Number of records per page
 *     responses:
 *       200:
 *         description: Chat list retrieved successfully
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
 *                     conversations:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: string
 *                             format: uuid
 *                             description: Conversation ID
 *                             example: "123e4567-e89b-12d3-a456-426614174000"
 *                           isGroup:
 *                             type: boolean
 *                             description: Whether this is a group chat
 *                             example: false
 *                           members:
 *                             type: array
 *                             items:
 *                               type: object
 *                               properties:
 *                                 userId:
 *                                   type: string
 *                                   format: uuid
 *                                   description: User ID
 *                                   example: "123e4567-e89b-12d3-a456-426614174001"
 *                                 user:
 *                                   type: object
 *                                   properties:
 *                                     id:
 *                                       type: string
 *                                       format: uuid
 *                                       example: "123e4567-e89b-12d3-a456-426614174001"
 *                                     firstName:
 *                                       type: string
 *                                       example: "John"
 *                                     lastName:
 *                                       type: string
 *                                       example: "Doe"
 *                                     role:
 *                                       type: string
 *                                       enum: [SUPERADMIN, ADMIN, DENTIST, STAFF]
 *                                       example: "DENTIST"
 *                           lastMessage:
 *                             type: object
 *                             properties:
 *                               id:
 *                                 type: string
 *                                 format: uuid
 *                                 example: "123e4567-e89b-12d3-a456-426614174002"
 *                               encryptedText:
 *                                 type: string
 *                                 example: "Hello, how are you?"
 *                               type:
 *                                 type: string
 *                                 enum: [TEXT, IMAGE, VIDEO, FILE, AUDIO]
 *                                 example: "TEXT"
 *                               status:
 *                                 type: string
 *                                 enum: [SENT, DELIVERED, READ]
 *                                 example: "DELIVERED"
 *                               senderId:
 *                                 type: string
 *                                 format: uuid
 *                                 example: "123e4567-e89b-12d3-a456-426614174001"
 *                               createdAt:
 *                                 type: string
 *                                 format: date-time
 *                                 example: "2025-07-24T07:30:00.000Z"
 *                           createdAt:
 *                             type: string
 *                             format: date-time
 *                             example: "2025-07-20T10:00:00.000Z"
 *                           updatedAt:
 *                             type: string
 *                             format: date-time
 *                             example: "2025-07-24T07:30:00.000Z"
 *                     groups:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: string
 *                             format: uuid
 *                             description: Group ID
 *                             example: "123e4567-e89b-12d3-a456-426614174003"
 *                           name:
 *                             type: string
 *                             description: Group name
 *                             example: "Dental Team"
 *                           archived:
 *                             type: boolean
 *                             description: Whether the group is archived
 *                             example: false
 *                           members:
 *                             type: array
 *                             items:
 *                               type: object
 *                               properties:
 *                                 userId:
 *                                   type: string
 *                                   format: uuid
 *                                   description: User ID
 *                                   example: "123e4567-e89b-12d3-a456-426614174001"
 *                                 role:
 *                                   type: string
 *                                   enum: [DENTIST, STAFF, ADMIN]
 *                                   example: "ADMIN"
 *                                 user:
 *                                   type: object
 *                                   properties:
 *                                     id:
 *                                       type: string
 *                                       format: uuid
 *                                       example: "123e4567-e89b-12d3-a456-426614174001"
 *                                     firstName:
 *                                       type: string
 *                                       example: "John"
 *                                     lastName:
 *                                       type: string
 *                                       example: "Doe"
 *                                     role:
 *                                       type: string
 *                                       enum: [SUPERADMIN, ADMIN, DENTIST, STAFF]
 *                                       example: "DENTIST"
 *                           lastMessage:
 *                             type: object
 *                             properties:
 *                               id:
 *                                 type: string
 *                                 format: uuid
 *                                 example: "123e4567-e89b-12d3-a456-426614174004"
 *                               encryptedText:
 *                                 type: string
 *                                 example: "Team meeting tomorrow at 10 AM"
 *                               type:
 *                                 type: string
 *                                 enum: [TEXT, IMAGE, VIDEO, FILE, AUDIO]
 *                                 example: "TEXT"
 *                               status:
 *                                 type: string
 *                                 enum: [SENT, DELIVERED, READ]
 *                                 example: "SENT"
 *                               senderId:
 *                                 type: string
 *                                 format: uuid
 *                                 example: "123e4567-e89b-12d3-a456-426614174005"
 *                               createdAt:
 *                                 type: string
 *                                 format: date-time
 *                                 example: "2025-07-24T08:15:00.000Z"
 *                           createdAt:
 *                             type: string
 *                             format: date-time
 *                             example: "2025-07-15T14:30:00.000Z"
 *                           updatedAt:
 *                             type: string
 *                             format: date-time
 *                             example: "2025-07-24T08:15:00.000Z"
 *       401:
 *         description: Unauthorized (Missing or invalid token)
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
 *                       example: "Unauthorized"
 *       500:
 *         description: Internal Server Error
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
 *                       example: "Internal Server Error"
 */

/**
 * @swagger
 * /api/v1/messages/mark-all-as-read:
 *   post:
 *     summary: Mark all messages in a conversation or group as read
 *     description: Updates the status of all unread messages in a specified conversation or group to 'READ'
 *     tags:
 *       - Messages
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - type
 *               - chatId
 *             properties:
 *               type:
 *                 type: string
 *                 enum: [conversation, group]
 *                 description: Type of chat (conversation for 1-on-1, group for group chat)
 *                 example: "conversation"
 *               chatId:
 *                 type: string
 *                 format: uuid
 *                 description: ID of the conversation or group
 *                 example: "123e4567-e89b-12d3-a456-426614174000"
 *     responses:
 *       200:
 *         description: Messages marked as read successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "All messages marked as read"
 *                 data:
 *                   type: object
 *                   properties:
 *                     count:
 *                       type: integer
 *                       description: Number of messages marked as read
 *                       example: 5
 *       400:
 *         description: Bad Request (validation error)
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
 *                       example: "Validation failed"
 *                     details:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           param:
 *                             type: string
 *                           msg:
 *                             type: string
 *       401:
 *         description: Unauthorized (Missing or invalid token)
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
 *                       example: "Unauthorized"
 *       403:
 *         description: Forbidden (Not a member of the conversation or group)
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
 *                       example: "You are not a member of this conversation"
 *       500:
 *         description: Internal Server Error
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
 *                       example: "Internal Server Error"
 */
