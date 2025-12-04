-- AlterTable: Make groupId optional and add new columns
ALTER TABLE "RecentSearch"
  ALTER COLUMN "groupId" DROP NOT NULL,
  ADD COLUMN "conversationId" TEXT,
  ADD COLUMN "searchedUserId" TEXT;

-- CreateIndex: Add unique constraints
CREATE UNIQUE INDEX "RecentSearch_userId_conversationId_key" ON "RecentSearch"("userId", "conversationId");
CREATE UNIQUE INDEX "RecentSearch_userId_searchedUserId_key" ON "RecentSearch"("userId", "searchedUserId");

-- CreateIndex: Add indexes for performance
CREATE INDEX "RecentSearch_conversationId_idx" ON "RecentSearch"("conversationId");
CREATE INDEX "RecentSearch_searchedUserId_idx" ON "RecentSearch"("searchedUserId");

-- AddForeignKey: Link to Conversation
ALTER TABLE "RecentSearch" ADD CONSTRAINT "RecentSearch_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "Conversation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: Link to User (searchedUser)
ALTER TABLE "RecentSearch" ADD CONSTRAINT "RecentSearch_searchedUserId_fkey" FOREIGN KEY ("searchedUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
