-- DropForeignKey
ALTER TABLE "refresh_tokens" DROP CONSTRAINT "refresh_tokens_deviceId_fkey";

-- DropIndex
DROP INDEX "Device_deviceId_key";

-- AlterTable
ALTER TABLE "Device" ALTER COLUMN "deviceId" DROP NOT NULL;
