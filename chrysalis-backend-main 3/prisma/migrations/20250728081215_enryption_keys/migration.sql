-- CreateTable
CREATE TABLE "PreKeyBundle" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "identityKey" TEXT NOT NULL,
    "signedPreKey" TEXT NOT NULL,
    "signedPreKeyId" INTEGER NOT NULL,
    "preKeys" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PreKeyBundle_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "PreKeyBundle_userId_key" ON "PreKeyBundle"("userId");

-- AddForeignKey
ALTER TABLE "PreKeyBundle" ADD CONSTRAINT "PreKeyBundle_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
