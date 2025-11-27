-- CreateTable
CREATE TABLE "GroupKeyEnvelope" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "aesKeyEncB64Url" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GroupKeyEnvelope_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "GroupKeyEnvelope_groupId_idx" ON "GroupKeyEnvelope"("groupId");

-- CreateIndex
CREATE INDEX "GroupKeyEnvelope_userId_idx" ON "GroupKeyEnvelope"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "GroupKeyEnvelope_groupId_userId_key" ON "GroupKeyEnvelope"("groupId", "userId");

-- AddForeignKey
ALTER TABLE "GroupKeyEnvelope" ADD CONSTRAINT "GroupKeyEnvelope_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GroupKeyEnvelope" ADD CONSTRAINT "GroupKeyEnvelope_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
