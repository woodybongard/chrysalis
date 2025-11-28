-- CreateTable
CREATE TABLE "RecentSearch" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "RecentSearch_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "RecentSearch_userId_idx" ON "RecentSearch"("userId");

-- CreateIndex
CREATE INDEX "RecentSearch_groupId_idx" ON "RecentSearch"("groupId");

-- CreateIndex
CREATE UNIQUE INDEX "RecentSearch_userId_groupId_key" ON "RecentSearch"("userId", "groupId");

-- AddForeignKey
ALTER TABLE "RecentSearch" ADD CONSTRAINT "RecentSearch_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecentSearch" ADD CONSTRAINT "RecentSearch_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE CASCADE ON UPDATE CASCADE;
