/*
  Warnings:

  - You are about to drop the column `keyVersion` on the `Group` table. All the data in the column will be lost.
  - You are about to drop the column `aesKeyEnc` on the `GroupKey` table. All the data in the column will be lost.
  - You are about to drop the column `userId` on the `GroupKey` table. All the data in the column will be lost.

*/
-- DropForeignKey
ALTER TABLE "GroupKey" DROP CONSTRAINT "GroupKey_userId_fkey";

-- DropIndex
DROP INDEX "GroupKey_groupId_userId_key";

-- AlterTable
ALTER TABLE "Group" DROP COLUMN "keyVersion",
ADD COLUMN     "version" INTEGER;

-- AlterTable
ALTER TABLE "GroupKey" DROP COLUMN "aesKeyEnc",
DROP COLUMN "userId",
ADD COLUMN     "gskB64" TEXT,
ADD COLUMN     "version" INTEGER;

-- AlterTable
ALTER TABLE "Message" ADD COLUMN     "gskVersion" INTEGER NOT NULL DEFAULT 1;

-- CreateIndex
CREATE INDEX "GroupKey_groupId_version_idx" ON "GroupKey"("groupId", "version");
