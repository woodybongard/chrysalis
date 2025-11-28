/*
  Warnings:

  - You are about to drop the `GroupKeyWrapper` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "GroupKeyWrapper" DROP CONSTRAINT "GroupKeyWrapper_groupId_fkey";

-- DropForeignKey
ALTER TABLE "GroupKeyWrapper" DROP CONSTRAINT "GroupKeyWrapper_userId_fkey";

-- AlterTable
ALTER TABLE "Message" ADD COLUMN     "fileName" TEXT,
ADD COLUMN     "filePages" INTEGER,
ADD COLUMN     "fileSize" INTEGER,
ADD COLUMN     "fileType" TEXT;

-- DropTable
DROP TABLE "GroupKeyWrapper";
