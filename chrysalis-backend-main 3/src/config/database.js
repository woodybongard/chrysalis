const { PrismaClient } = require('@prisma/client');

let prisma;

if (process.env.NODE_ENV === 'production') {
  prisma = new PrismaClient({
    log: ['error'],
  });
} else {
  // In development, use a global variable to prevent hot-reload issues
  if (!global.__prisma) {
    global.__prisma = new PrismaClient({
      log: ['query', 'info', 'warn', 'error'],
      errorFormat: 'pretty',
    });
  }
  prisma = global.__prisma;
}

// Explicitly connect to DB and log success/failure
(async () => {
  try {
    await prisma.$connect();
    console.log('✅ Database connected successfully');
  } catch (err) {
    console.error('❌ Database connection failed:', err);
  }
})();

// Handle graceful shutdown
const gracefulShutdown = async () => {
  console.log('Closing database connection...');
  await prisma.$disconnect();
};

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);
process.on('beforeExit', gracefulShutdown);

module.exports = prisma;
