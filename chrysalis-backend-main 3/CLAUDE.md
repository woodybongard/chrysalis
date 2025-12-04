# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Chrysalis is a medical social media platform backend built with Node.js/Express. It provides end-to-end encrypted messaging (1:1 and group chats), real-time communication via Socket.IO, and push notifications via Firebase Cloud Messaging.

## Common Commands

```bash
# Development
npm run dev              # Start dev server with nodemon
npm start                # Start production server

# Database
npm run prisma:generate  # Generate Prisma client after schema changes
npm run prisma:migrate   # Run migrations in development
npm run prisma:deploy    # Deploy migrations to production
npm run prisma:studio    # Open Prisma Studio GUI
npm run prisma:reset     # Reset database (destructive)

# Testing
npm test                 # Run Jest tests
```

## Architecture

### Request Flow
```
Client → Express Routes → Controllers → Services → Prisma → PostgreSQL
                                              ↓
                              Socket.IO (real-time events)
                              Firebase (push notifications)
```

### Key Directories
- `src/routes/` - Express route definitions with validation
- `src/controller/` - Request handlers (thin layer)
- `src/services/` - Business logic (main implementation)
- `src/utils/` - Shared utilities (JWT, S3 upload, push notifications)
- `src/middleware/` - Auth, error handling, file upload
- `prisma/schema.prisma` - Database schema (source of truth for models)

### Messaging System

**Two chat types exist:**
1. **1:1 Conversations** - Uses `Conversation` and `ConversationMember` models
2. **Group Chats** - Uses `Group` and `GroupMember` models

Both share the `Message` model (with either `conversationId` or `groupId` set).

**Message flow (`src/services/chat.service.js`):**
1. Create message in transaction with `MessageRead` and `MessageDelivery` records
2. Emit real-time event via Socket.IO
3. Send push notification to offline users via FCM

**Delivery tracking:**
- `MessageRead` - Tracks read/delivered status per user per message
- `MessageDelivery` - Tracks delivery attempts and status

### Real-time Events (`src/socket.js`)

Key socket events:
- `join_user_room` - Join user's personal notification room
- `join_conversation` - Join a chat room
- `new_message` - New message notification
- `group_message` - Group message broadcast
- `mark_read` - Mark messages as read
- `typing` / `stop_typing` - Typing indicators
- `add_reaction` / `remove_reaction` - Message reactions

### Push Notifications (`src/utils/pushNotification.js`)

FCM tokens stored in `FcmToken` model (multiple per user for multi-device).

Before sending push:
1. Check `user.isNotification` preference
2. Skip users currently "live" in the chat (via Socket.IO room)
3. Skip the message sender

### Encryption

Messages are end-to-end encrypted. Key models:
- `UserKey` - User's RSA public/private key pair
- `GroupKey` - Group symmetric key (versioned)
- `GroupKeyEnvelope` - Per-user encrypted copy of group key

### Authentication

JWT-based with access/refresh tokens:
- Access token: 15 minutes
- Refresh token: 7 days (stored in `RefreshToken` model)
- FCM token registered at login with `deviceId`

### File Uploads

Files uploaded to S3 via `src/utils/s3Upload.js` and `src/utils/scanAndUploadFile.js`.

## API Documentation

Swagger docs available at `/api/v1/docs` when server is running.

## Deployment

Production runs on AWS EC2 with PM2:
```bash
# SSH to server
ssh -i ~/.ssh/chrysalis-keypair.pem ubuntu@ec2-3-17-58-10.us-east-2.compute.amazonaws.com

# View logs
pm2 logs chrysalis-backend

# Restart
pm2 restart chrysalis-backend
```

Files are deployed via `rsync` (see `redeploy.sh` on server).

## Database

PostgreSQL with Prisma ORM. Key relationships:
- User has many: FcmTokens, GroupMemberships, Messages, MessageReads
- Group has many: GroupMembers, Messages, GroupKeyEnvelopes
- Message has many: MessageReads, MessageDeliveries, MessageReactions
