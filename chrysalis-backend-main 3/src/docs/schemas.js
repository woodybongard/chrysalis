/**
 * @swagger
 * components:
 *   schemas:
 *     RegisterRequest:
 *       type: object
 *       required:
 *         - email
 *         - username
 *         - password
 *       properties:
 *         email:
 *           type: string
 *           format: email
 *           description: User email address
 *           example: user@example.com
 *         username:
 *           type: string
 *           minLength: 3
 *           maxLength: 30
 *           pattern: '^[a-zA-Z0-9]+$'
 *           description: Unique alphanumeric username (3-30 characters)
 *           example: johndoe
 *         password:
 *           type: string
 *           minLength: 8
 *           description: Password must include uppercase, lowercase, number, and special character
 *           example: SecurePass123!
 *         firstName:
 *           type: string
 *           maxLength: 50
 *           description: User's first name
 *           example: John
 *         lastName:
 *           type: string
 *           maxLength: 50
 *           description: User's last name
 *           example: Doe
 *     LoginRequest:
 *       type: object
 *       required:
 *         - login
 *         - password
 *       properties:
 *         login:
 *           type: string
 *           description: User email or username
 *           example: user@example.com
 *         password:
 *           type: string
 *           description: User password
 *           example: SecurePass123!
 *         fcmToken:
 *           type: string
 *           description: Firebase Cloud Messaging token for push notifications
 *           example: fcm_token_example
 *     RefreshTokenRequest:
 *       type: object
 *       required:
 *         - refreshToken
 *       properties:
 *         refreshToken:
 *           type: string
 *           description: Valid refresh token
 *           example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *     UpdateProfileRequest:
 *       type: object
 *       properties:
 *         firstName:
 *           type: string
 *           maxLength: 50
 *           description: User's first name
 *           example: John
 *         lastName:
 *           type: string
 *           maxLength: 50
 *           description: User's last name
 *           example: Doe
 *     ChangePasswordRequest:
 *       type: object
 *       required:
 *         - currentPassword
 *         - newPassword
 *       properties:
 *         currentPassword:
 *           type: string
 *           description: Current user password
 *           example: CurrentPass123!
 *         newPassword:
 *           type: string
 *           minLength: 8
 *           description: New password (must include uppercase, lowercase, number, special character)
 *           example: NewSecurePass456!
 *     CreateAdminRequest:
 *       type: object
 *       required:
 *         - email
 *         - username
 *         - password
 *       properties:
 *         email:
 *           type: string
 *           format: email
 *           description: Admin email address
 *           example: admin@chrysalis.com
 *         username:
 *           type: string
 *           minLength: 3
 *           maxLength: 30
 *           description: Admin username
 *           example: chrysalisadmin
 *         password:
 *           type: string
 *           minLength: 8
 *           description: Secure password
 *           example: AdminSecurePass123!
 *         firstName:
 *           type: string
 *           description: Admin's first name
 *           example: Alice
 *         lastName:
 *           type: string
 *           description: Admin's last name
 *           example: Smith
 *     CreateSuperAdminRequest:
 *      type: object
 *      required:
 *        - email
 *        - username
 *        - password
 *      properties:
 *        email:
 *          type: string
 *          format: email
 *          example: superadmin@chrysalis.com
 *        username:
 *          type: string
 *          example: superadminuser
 *        password:
 *          type: string
 *          example: SuperSecure123!
 *        firstName:
 *          type: string
 *          example: Super
 *        lastName:
 *          type: string
 *          example: Admin

 */

/**
 * @swagger
 * components:
 *   schemas:
 *     SendMessageRequest:
 *       type: object
 *       required:
 *         - content
 *         - type
 *       properties:
 *         recipientId:
 *           type: string
 *           description: User ID for 1-on-1 chat or Conversation ID for group chat
 *           example: 88b73a1d-3171-41c8-b25f-b9fb8b537e3a
 *         content:
 *           type: string
 *           description: Message text or caption
 *           example: Hello! This is a test message.
 *         type:
 *           type: string
 *           enum: [TEXT, IMAGE, VIDEO, FILE, AUDIO]
 *           description: Type of the message
 *           example: TEXT
 *         groupId:
 *           type: string
 *           description: group Id
 *           example: uuid
 *         version:
 *           type: string
 *           description: version of key
 *         file:
 *           type: string
 *           format: binary
 *           description: File to upload (image, video, audio, or document)
 *
 *
 *     MessageResponse:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         conversationId:
 *           type: string
 *         senderId:
 *           type: string
 *         content:
 *           type: string
 *         type:
 *           type: string
 *           enum: [TEXT, IMAGE, VIDEO, FILE, AUDIO]
 *         status:
 *           type: string
 *           enum: [SENT, DELIVERED, READ]
 *         attachmentUrl:
 *           type: string
 *         createdAt:
 *           type: string
 *           format: date-time
 *     PaginationResponse:
 *       type: object
 *       properties:
 *         totalCount:
 *           type: integer
 *           description: Total number of items
 *           example: 157
 *         pageSize:
 *           type: integer
 *           description: Number of items per page
 *           example: 20
 *         currPage:
 *           type: integer
 *           description: Current page number
 *           example: 1
 *         totalPages:
 *           type: integer
 *           description: Total number of pages
 *           example: 8
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     CreateGroupRequest:
 *       type: object
 *       required:
 *         - name
 *         - members
 *       properties:
 *         name:
 *           type: string
 *           description: Name of the group
 *           example: "Dental Team"
 *         members:
 *           type: array
 *           description: Array of user IDs to add to the group
 *           items:
 *             type: string
 *             format: uuid
 *           example: ["123e4567-e89b-12d3-a456-426614174001", "123e4567-e89b-12d3-a456-426614174002"]
 *
 *     AddGroupMembersRequest:
 *       type: object
 *       required:
 *         - members
 *       properties:
 *         members:
 *           type: array
 *           description: Array of user IDs to add to the group
 *           items:
 *             type: string
 *             format: uuid
 *           example: ["123e4567-e89b-12d3-a456-426614174003", "123e4567-e89b-12d3-a456-426614174004"]
 *
 *     GroupResponse:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Group ID
 *           example: "123e4567-e89b-12d3-a456-426614174000"
 *         name:
 *           type: string
 *           description: Group name
 *           example: "Dental Team"
 *         archived:
 *           type: boolean
 *           description: Whether the group is archived
 *           example: false
 *         members:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               id:
 *                 type: string
 *                 format: uuid
 *                 example: "123e4567-e89b-12d3-a456-426614174005"
 *               userId:
 *                 type: string
 *                 format: uuid
 *                 example: "123e4567-e89b-12d3-a456-426614174001"
 *               groupId:
 *                 type: string
 *                 format: uuid
 *                 example: "123e4567-e89b-12d3-a456-426614174000"
 *               role:
 *                 type: string
 *                 enum: [DENTIST, STAFF, ADMIN]
 *                 example: "ADMIN"
 *               joinedAt:
 *                 type: string
 *                 format: date-time
 *                 example: "2025-07-24T10:00:00.000Z"
 *         createdAt:
 *           type: string
 *           format: date-time
 *           example: "2025-07-24T10:00:00.000Z"
 *         updatedAt:
 *           type: string
 *           format: date-time
 *           example: "2025-07-24T10:00:00.000Z"
 */
