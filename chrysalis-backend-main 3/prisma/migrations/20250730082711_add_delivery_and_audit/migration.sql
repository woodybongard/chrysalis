-- CreateEnum
CREATE TYPE "DeliveryChannel" AS ENUM ('SOCKET', 'PUSH', 'WEBHOOK', 'UNKNOWN');

-- CreateEnum
CREATE TYPE "DeliveryStatus" AS ENUM ('QUEUED', 'SENT', 'DELIVERED', 'READ', 'FAILED');

-- CreateTable
CREATE TABLE "MessageDelivery" (
    "id" TEXT NOT NULL,
    "messageId" TEXT NOT NULL,
    "recipientId" TEXT NOT NULL,
    "status" "DeliveryStatus" NOT NULL DEFAULT 'QUEUED',
    "lastChannel" "DeliveryChannel" NOT NULL DEFAULT 'UNKNOWN',
    "deliveredAt" TIMESTAMP(3),
    "firstReadAt" TIMESTAMP(3),
    "lastReadAt" TIMESTAMP(3),
    "readCount" INTEGER NOT NULL DEFAULT 0,
    "lastDeviceId" TEXT,
    "lastUserAgent" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MessageDelivery_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditEvent" (
    "id" TEXT NOT NULL,
    "occurredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "action" TEXT NOT NULL,
    "channel" "DeliveryChannel",
    "actorUserId" TEXT,
    "recipientUserId" TEXT,
    "messageId" TEXT,
    "conversationId" TEXT,
    "groupId" TEXT,
    "ip" TEXT,
    "userAgent" TEXT,
    "deviceId" TEXT,
    "metadata" JSONB,
    "prevHash" TEXT,
    "hash" TEXT,

    CONSTRAINT "AuditEvent_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "MessageDelivery_recipientId_idx" ON "MessageDelivery"("recipientId");

-- CreateIndex
CREATE INDEX "MessageDelivery_status_idx" ON "MessageDelivery"("status");

-- CreateIndex
CREATE INDEX "MessageDelivery_messageId_updatedAt_idx" ON "MessageDelivery"("messageId", "updatedAt");

-- CreateIndex
CREATE UNIQUE INDEX "MessageDelivery_messageId_recipientId_key" ON "MessageDelivery"("messageId", "recipientId");

-- CreateIndex
CREATE INDEX "AuditEvent_messageId_occurredAt_idx" ON "AuditEvent"("messageId", "occurredAt");

-- CreateIndex
CREATE INDEX "AuditEvent_recipientUserId_occurredAt_idx" ON "AuditEvent"("recipientUserId", "occurredAt");

-- CreateIndex
CREATE INDEX "AuditEvent_action_occurredAt_idx" ON "AuditEvent"("action", "occurredAt");

-- AddForeignKey
ALTER TABLE "MessageDelivery" ADD CONSTRAINT "MessageDelivery_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "Message"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MessageDelivery" ADD CONSTRAINT "MessageDelivery_recipientId_fkey" FOREIGN KEY ("recipientId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditEvent" ADD CONSTRAINT "AuditEvent_actorUserId_fkey" FOREIGN KEY ("actorUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditEvent" ADD CONSTRAINT "AuditEvent_recipientUserId_fkey" FOREIGN KEY ("recipientUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditEvent" ADD CONSTRAINT "AuditEvent_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "Message"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditEvent" ADD CONSTRAINT "AuditEvent_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "Conversation"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditEvent" ADD CONSTRAINT "AuditEvent_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE SET NULL ON UPDATE CASCADE;
