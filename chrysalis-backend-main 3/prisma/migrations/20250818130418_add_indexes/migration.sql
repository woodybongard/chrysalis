-- CreateIndex
CREATE INDEX "GroupMember_userId_idx" ON "GroupMember"("userId");

-- CreateIndex
CREATE INDEX "GroupMember_groupId_idx" ON "GroupMember"("groupId");

-- CreateIndex
CREATE INDEX "Message_conversationId_createdAt_idx" ON "Message"("conversationId", "createdAt");

-- CreateIndex
CREATE INDEX "Message_groupId_createdAt_idx" ON "Message"("groupId", "createdAt");

-- CreateIndex
CREATE INDEX "Message_senderId_createdAt_idx" ON "Message"("senderId", "createdAt");

-- CreateIndex
CREATE INDEX "MessageDelivery_recipientId_deliveredAt_idx" ON "MessageDelivery"("recipientId", "deliveredAt");

-- CreateIndex
CREATE INDEX "MessageDelivery_recipientId_lastReadAt_idx" ON "MessageDelivery"("recipientId", "lastReadAt");

-- CreateIndex
CREATE INDEX "MessageRead_userId_readAt_idx" ON "MessageRead"("userId", "readAt");

-- CreateIndex
CREATE INDEX "MessageRead_userId_deliveredAt_idx" ON "MessageRead"("userId", "deliveredAt");

-- CreateIndex
CREATE INDEX "MessageRead_messageId_readAt_idx" ON "MessageRead"("messageId", "readAt");
