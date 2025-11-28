-- This is an empty migration.-- Messages: fast last-message lookup in conversation
CREATE INDEX idx_message_conversation_createdat 
ON "Message" ("conversationId", "createdAt" DESC);

-- Messages: fast last-message lookup in group
CREATE INDEX idx_message_group_createdat 
ON "Message" ("groupId", "createdAt" DESC);

-- Messages: exclude sender + join quickly
CREATE INDEX idx_message_sender 
ON "Message" ("senderId");

-- Reads: avoid scanning full table when checking if user read
CREATE INDEX idx_messageread_userid_readat 
ON "MessageRead" ("userId", "readAt");

CREATE INDEX idx_messageread_messageid 
ON "MessageRead" ("messageId");

-- Memberships: fast lookup of all chats a user belongs to
CREATE INDEX idx_convmember_userid 
ON "ConversationMember" ("userId");

CREATE INDEX idx_groupmember_userid 
ON "GroupMember" ("userId");
