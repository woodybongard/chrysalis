/*
  Warnings:

  - You are about to drop the column `bundleKey` on the `Group` table. All the data in the column will be lost.
  - You are about to drop the column `groupKeyEnc` on the `Group` table. All the data in the column will be lost.
  - You are about to drop the column `encryptedSenderKey` on the `GroupKey` table. All the data in the column will be lost.
  - You are about to drop the `PreKeyBundle` table. If the table is not empty, all the data it contains will be lost.
  - Added the required column `aesKeyEnc` to the `GroupKey` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "PreKeyBundle" DROP CONSTRAINT "PreKeyBundle_userId_fkey";

-- DropIndex
DROP INDEX "Group_bundleKey_key";

-- AlterTable
ALTER TABLE "Group" DROP COLUMN "bundleKey",
DROP COLUMN "groupKeyEnc";

-- AlterTable
ALTER TABLE "GroupKey" DROP COLUMN "encryptedSenderKey",
ADD COLUMN     "aesKeyEnc" TEXT NOT NULL,
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- AlterTable
ALTER TABLE "Message" ADD COLUMN     "iv" TEXT;

-- DropTable
DROP TABLE "PreKeyBundle";

-- CreateTable
CREATE TABLE "UserKey" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "publicKey" TEXT NOT NULL,
    "privateKeyEnc" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UserKey_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "UserKey_userId_key" ON "UserKey"("userId");

-- AddForeignKey
ALTER TABLE "UserKey" ADD CONSTRAINT "UserKey_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
