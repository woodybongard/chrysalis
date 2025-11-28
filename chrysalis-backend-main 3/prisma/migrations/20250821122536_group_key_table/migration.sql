-- CreateTable
CREATE TABLE "GroupKey" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "encryptedSenderKey" TEXT NOT NULL,

    CONSTRAINT "GroupKey_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "GroupKey_groupId_userId_key" ON "GroupKey"("groupId", "userId");

-- AddForeignKey
ALTER TABLE "GroupKey" ADD CONSTRAINT "GroupKey_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GroupKey" ADD CONSTRAINT "GroupKey_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
