/*
  Warnings:

  - A unique constraint covering the columns `[groupId,userId,version]` on the table `GroupKeyEnvelope` will be added. If there are existing duplicate values, this will fail.

*/
-- DropIndex
DROP INDEX "GroupKeyEnvelope_groupId_userId_key";

-- CreateIndex
CREATE UNIQUE INDEX "GroupKeyEnvelope_groupId_userId_version_key" ON "GroupKeyEnvelope"("groupId", "userId", "version");
