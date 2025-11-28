/*
  Warnings:

  - You are about to drop the column `identityKey` on the `PreKeyBundle` table. All the data in the column will be lost.
  - You are about to drop the column `signedPreKey` on the `PreKeyBundle` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[bundleKey]` on the table `Conversation` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[bundleKey]` on the table `Group` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `identityKeyPrivateEnc` to the `PreKeyBundle` table without a default value. This is not possible if the table is not empty.
  - Added the required column `identityKeyPublic` to the `PreKeyBundle` table without a default value. This is not possible if the table is not empty.
  - Added the required column `registrationId` to the `PreKeyBundle` table without a default value. This is not possible if the table is not empty.
  - Added the required column `signedPreKeyPrivateEnc` to the `PreKeyBundle` table without a default value. This is not possible if the table is not empty.
  - Added the required column `signedPreKeyPublic` to the `PreKeyBundle` table without a default value. This is not possible if the table is not empty.
  - Added the required column `signedPreKeySignature` to the `PreKeyBundle` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Conversation" ADD COLUMN     "bundleKey" TEXT,
ADD COLUMN     "convoKeyEnc" TEXT;

-- AlterTable
ALTER TABLE "Group" ADD COLUMN     "bundleKey" TEXT,
ADD COLUMN     "groupKeyEnc" TEXT;

-- AlterTable
ALTER TABLE "PreKeyBundle" DROP COLUMN "identityKey",
DROP COLUMN "signedPreKey",
ADD COLUMN     "identityKeyPrivateEnc" TEXT NOT NULL,
ADD COLUMN     "identityKeyPublic" TEXT NOT NULL,
ADD COLUMN     "registrationId" INTEGER NOT NULL,
ADD COLUMN     "signedPreKeyPrivateEnc" TEXT NOT NULL,
ADD COLUMN     "signedPreKeyPublic" TEXT NOT NULL,
ADD COLUMN     "signedPreKeySignature" TEXT NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "Conversation_bundleKey_key" ON "Conversation"("bundleKey");

-- CreateIndex
CREATE UNIQUE INDEX "Group_bundleKey_key" ON "Group"("bundleKey");
