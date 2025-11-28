/**
 * @swagger
 * tags:
 *   name: Keys
 *   description: Endpoints for managing preKey bundles and group sender keys
 */

/**
 * @swagger
 * /api/v1/keys/upload:
 *   post:
 *     summary: Upload client public keys (identity, signed preKey, one-time preKeys)
 *     tags: [Keys]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - registrationId
 *               - identityKey
 *               - signedPreKeyId
 *               - signedPreKeyPublic
 *               - signedPreKeySignature
 *               - preKeys
 *             properties:
 *               registrationId:
 *                 type: integer
 *               identityKey:
 *                 type: string
 *                 description: Base64 public identity key
 *               signedPreKeyId:
 *                 type: integer
 *               signedPreKeyPublic:
 *                 type: string
 *               signedPreKeySignature:
 *                 type: string
 *               preKeys:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required:
 *                     - keyId
 *                     - publicKey
 *                   properties:
 *                     keyId:
 *                       type: integer
 *                     publicKey:
 *                       type: string
 *     responses:
 *       200:
 *         description: Successfully stored keys
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *       400:
 *         description: Invalid bundle payload
 */

/**
 * @swagger
 * /api/v1/keys/has-bundle:
 *   get:
 *     summary: Check if a public bundle exists for the authenticated user
 *     tags: [Keys]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Returns whether the bundle exists
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 hasBundle:
 *                   type: boolean
 */

/**
 * @swagger
 * /api/v1/keys/bundle/{userId}:
 *   get:
 *     summary: Fetch public bundle of a user including one one-time preKey
 *     tags: [Keys]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: userId
 *         in: path
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Returns user bundle with a one-time preKey
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 registrationId:
 *                   type: integer
 *                 identityKey:
 *                   type: string
 *                 signedPreKey:
 *                   type: object
 *                   properties:
 *                     keyId:
 *                       type: integer
 *                     publicKey:
 *                       type: string
 *                     signature:
 *                       type: string
 *                 preKey:
 *                   type: object
 *                   properties:
 *                     keyId:
 *                       type: integer
 *                     publicKey:
 *                       type: string
 *       404:
 *         description: No bundle found
 *       409:
 *         description: No one-time preKeys available
 */

/**
 * @swagger
 * /api/v1/keys/{groupId}/sender-keys:
 *   post:
 *     summary: Upload encrypted sender keys for a group
 *     tags: [Keys]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: groupId
 *         in: path
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               entries:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required:
 *                     - userId
 *                     - encryptedSenderKey
 *                   properties:
 *                     userId:
 *                       type: string
 *                     encryptedSenderKey:
 *                       type: string
 *     responses:
 *       200:
 *         description: Keys uploaded successfully
 *       400:
 *         description: Invalid entries
 *       403:
 *         description: User not a member of the group
 *       404:
 *         description: Group not found
 */

/**
 * @swagger
 * /api/v1/keys/{groupId}/sender-key:
 *   get:
 *     summary: Fetch authenticated user's encrypted sender key for a group
 *     tags: [Keys]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: groupId
 *         in: path
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Returns encrypted sender key
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 encryptedSenderKey:
 *                   type: string
 *       404:
 *         description: No sender key for user
 */

/**
 * @swagger
 * components:
 *   securitySchemes:
 *     bearerAuth:
 *       type: http
 *       scheme: bearer
 *       bearerFormat: JWT
 */
