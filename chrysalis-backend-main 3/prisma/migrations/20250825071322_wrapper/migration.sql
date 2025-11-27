-- AlterTable
ALTER TABLE "Group" ADD COLUMN     "keyVersion" INTEGER NOT NULL DEFAULT 1;

-- CreateTable
CREATE TABLE "GroupKeyWrapper" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "encryptedKey" TEXT,
    "status" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GroupKeyWrapper_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "KeyRequest" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "targetUserId" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fulfilledAt" TIMESTAMP(3),
    "requestedBy" TEXT,
    "note" TEXT,

    CONSTRAINT "KeyRequest_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "KeyRequest_groupId_targetUserId_version_status_idx" ON "KeyRequest"("groupId", "targetUserId", "version", "status");

-- AddForeignKey
ALTER TABLE "GroupKeyWrapper" ADD CONSTRAINT "GroupKeyWrapper_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GroupKeyWrapper" ADD CONSTRAINT "GroupKeyWrapper_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "KeyRequest" ADD CONSTRAINT "KeyRequest_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
