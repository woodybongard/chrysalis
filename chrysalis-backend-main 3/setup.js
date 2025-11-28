#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const crypto = require('crypto');

console.log('🚀 Setting up Chrysalis Authentication API...\n');

// Generate secure random strings for JWT secrets
const generateSecret = () => crypto.randomBytes(64).toString('hex');

// Environment file template
const envTemplate = `# Database
DATABASE_URL="postgresql://username:password@localhost:5432/chrysalis_db?schema=public"

# JWT Configuration
JWT_SECRET="${generateSecret()}"
JWT_REFRESH_SECRET="${generateSecret()}"
JWT_ACCESS_EXPIRES_IN="15m"
JWT_REFRESH_EXPIRES_IN="7d"

# Server Configuration
PORT=3000
NODE_ENV="development"

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Security
BCRYPT_SALT_ROUNDS=12

# CORS Origins (comma-separated for multiple origins)
CORS_ORIGINS="http://localhost:3000,http://localhost:3001"

#AWS Bucket Credentials
AWS_S3_BUCKET_NAME=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=
`;

// Check if .env file exists
const envPath = path.join(process.cwd(), '.env');
if (!fs.existsSync(envPath)) {
  console.log('📝 Creating .env file with secure JWT secrets...');
  fs.writeFileSync(envPath, envTemplate);
  console.log('✅ .env file created successfully!');
} else {
  console.log('⚠️  .env file already exists, skipping creation.');
}

// Check if node_modules exists
const nodeModulesPath = path.join(process.cwd(), 'node_modules');
if (!fs.existsSync(nodeModulesPath)) {
  console.log('\n📦 Installing dependencies...');
  try {
    execSync('npm install', { stdio: 'inherit' });
    console.log('✅ Dependencies installed successfully!');
  } catch (error) {
    console.error('❌ Failed to install dependencies:', error.message);
    process.exit(1);
  }
} else {
  console.log('📦 Dependencies already installed.');
}

// Generate Prisma client
console.log('\n🔧 Generating Prisma client...');
try {
  execSync('npx prisma generate', { stdio: 'inherit' });
  console.log('✅ Prisma client generated successfully!');
} catch (error) {
  console.error('❌ Failed to generate Prisma client:', error.message);
  console.log(
    '💡 Make sure PostgreSQL is running and DATABASE_URL is correct in .env',
  );
}

console.log('\n🎉 Setup completed!\n');

console.log('📋 Next steps:');
console.log(
  '1. Update the DATABASE_URL in .env with your PostgreSQL credentials',
);
console.log('2. Run: npm run prisma:migrate (to create database tables)');
console.log('3. Run: npm run dev (to start the development server)');

console.log('\n📚 API will be available at: http://localhost:3000');
console.log('🏥 Health check: http://localhost:3000/health');
console.log('🔐 Auth endpoints: http://localhost:3000/api/v1/auth');

console.log(
  '\n📖 Check README.md for detailed API documentation and usage examples.',
);

console.log('\n🔗 Quick test with curl:');
console.log('curl -X POST http://localhost:3000/api/v1/auth/register \\');
console.log('  -H "Content-Type: application/json" \\');
console.log(
  '  -d \'{"email":"test@example.com","username":"testuser","password":"SecurePass123!"}\'',
);
