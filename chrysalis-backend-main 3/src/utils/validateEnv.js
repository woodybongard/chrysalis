const validateEnvironment = () => {
  const requiredEnvVars = [
    'DATABASE_URL',
    'JWT_SECRET',
    'JWT_REFRESH_SECRET',
  ];

  const missingEnvVars = requiredEnvVars.filter(envVar => !process.env[envVar]);

  if (missingEnvVars.length > 0) {
    console.error('❌ Missing required environment variables:');
    missingEnvVars.forEach(envVar => {
      console.error(`   - ${envVar}`);
    });
    console.error('\n📋 Please check your .env file and ensure all required variables are set.');
    process.exit(1);
  }

  // Validate JWT secrets are not default values
  const defaultSecrets = [
    'your-super-secret-jwt-key-change-this-in-production',
    'your-super-secret-refresh-jwt-key-change-this-in-production'
  ];

  if (process.env.NODE_ENV === 'production') {
    if (defaultSecrets.includes(process.env.JWT_SECRET) || 
        defaultSecrets.includes(process.env.JWT_REFRESH_SECRET)) {
      console.error('❌ JWT secrets are using default values in production!');
      console.error('Please update JWT_SECRET and JWT_REFRESH_SECRET in your .env file.');
      process.exit(1);
    }
  }

  console.log('✅ Environment validation passed');
};

module.exports = { validateEnvironment }; 