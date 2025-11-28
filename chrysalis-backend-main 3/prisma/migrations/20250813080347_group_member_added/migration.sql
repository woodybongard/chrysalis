/*
  Warnings:

  - The values [DENTIST,STAFF] on the enum `GroupRole` will be removed. If these variants are still used in the database, this will fail.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "GroupRole_new" AS ENUM ('MEMBER', 'ADMIN');
ALTER TABLE "GroupMember" ALTER COLUMN "role" TYPE "GroupRole_new" USING ("role"::text::"GroupRole_new");
ALTER TYPE "GroupRole" RENAME TO "GroupRole_old";
ALTER TYPE "GroupRole_new" RENAME TO "GroupRole";
DROP TYPE "GroupRole_old";
COMMIT;
