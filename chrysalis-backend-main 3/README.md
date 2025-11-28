# Chrysalis - Mobile Authentication API

A robust Node.js Express authentication system with Prisma, PostgreSQL, and JWT tokens designed for mobile applications.

## Features

- ✅ **Secure Authentication**: Email/Username + Password login
- ✅ **JWT Tokens**: Access tokens (15min) + Refresh tokens (7 days)
- ✅ **Mobile-First**: Device tracking and session management
- ✅ **Security**: Rate limiting, bcrypt hashing, CORS protection
- ✅ **Database**: PostgreSQL with Prisma ORM
- ✅ **Validation**: Input validation and sanitization
- ✅ **Error Handling**: Comprehensive error responses
- ✅ **Logging**: Request logging and error tracking

## Quick Start

### Prerequisites

- Node.js 18.0.0 or higher
- PostgreSQL database
- npm or yarn

### 1. Environment Setup

Create a `.env` file in the root directory:

```bash
# Database
DATABASE_URL="postgresql://username:password@localhost:5432/chrysalis_db?schema=public"

# JWT Configuration
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"
JWT_REFRESH_SECRET="your-super-secret-refresh-jwt-key-change-this-in-production"
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
```

### 2. Installation

```bash
# Install dependencies
npm install

# Generate Prisma client
npm run prisma:generate

# Run database migrations
npm run prisma:migrate

# Start development server
npm run dev
```

### 3. Database Setup

The system will automatically create the necessary tables when you run migrations:

- `users` - User accounts with authentication data
- `refresh_tokens` - JWT refresh token management
- `password_resets` - Password reset functionality

## API Endpoints

### Base URL
```
http://localhost:3000/api/v1/auth
```

### Authentication Endpoints

#### 1. Register User
```http
POST /register
Content-Type: application/json

{
  "email": "user@example.com",
  "username": "johndoe",
  "password": "SecurePass123!",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "username": "johndoe",
      "firstName": "John",
      "lastName": "Doe",
      "isActive": true,
      "isVerified": true,
      "createdAt": "2024-01-15T10:00:00Z"
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIs...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
      "expiresAt": "2024-01-22T10:00:00Z"
    }
  }
}
```

#### 2. Login
```http
POST /login
Content-Type: application/json

{
  "login": "user@example.com", // or username
  "password": "SecurePass123!"
}
```

#### 3. Refresh Token
```http
POST /refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

#### 4. Logout
```http
POST /logout
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

#### 5. Logout All Devices
```http
POST /logout-all
Authorization: Bearer <access_token>
```

### Profile Management

#### 6. Get Profile
```http
GET /me
Authorization: Bearer <access_token>
```

#### 7. Update Profile
```http
PUT /me
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "firstName": "John",
  "lastName": "Doe"
}
```

#### 8. Change Password
```http
PUT /change-password
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "currentPassword": "CurrentPass123!",
  "newPassword": "NewSecurePass456!"
}
```

## Mobile Integration

### Headers for Mobile Apps

Include these headers in your mobile app requests:

```javascript
// For device identification
'X-Device-ID': 'unique-device-identifier'

// For authentication
'Authorization': 'Bearer ' + accessToken

// User agent for tracking
'User-Agent': 'YourMobileApp/1.0.0 (iOS/Android)'
```

### Token Management Strategy

```javascript
// Mobile app token management example
class AuthService {
  constructor() {
    this.accessToken = null;
    this.refreshToken = null;
  }

  async login(email, password) {
    const response = await fetch('/api/v1/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Device-ID': this.getDeviceId()
      },
      body: JSON.stringify({ login: email, password })
    });
    
    const data = await response.json();
    if (data.success) {
      this.accessToken = data.data.tokens.accessToken;
      this.refreshToken = data.data.tokens.refreshToken;
      // Store securely in device storage
      await this.storeTokensSecurely(data.data.tokens);
    }
    return data;
  }

  async refreshAccessToken() {
    const response = await fetch('/api/v1/auth/refresh', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Device-ID': this.getDeviceId()
      },
      body: JSON.stringify({ refreshToken: this.refreshToken })
    });
    
    const data = await response.json();
    if (data.success) {
      this.accessToken = data.data.tokens.accessToken;
      this.refreshToken = data.data.tokens.refreshToken;
      await this.storeTokensSecurely(data.data.tokens);
    }
    return data;
  }

  async makeAuthenticatedRequest(url, options = {}) {
    let response = await fetch(url, {
      ...options,
      headers: {
        ...options.headers,
        'Authorization': `Bearer ${this.accessToken}`,
        'X-Device-ID': this.getDeviceId()
      }
    });

    // If token expired, try to refresh
    if (response.status === 401) {
      const refreshResult = await this.refreshAccessToken();
      if (refreshResult.success) {
        // Retry with new token
        response = await fetch(url, {
          ...options,
          headers: {
            ...options.headers,
            'Authorization': `Bearer ${this.accessToken}`,
            'X-Device-ID': this.getDeviceId()
          }
        });
      }
    }

    return response;
  }
}
```

## Security Features

### Password Requirements
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character (@$!%*?&)

### Rate Limiting
- Authentication endpoints: 10 requests per 15 minutes per IP
- General API: 100 requests per 15 minutes per IP

### Token Security
- Access tokens expire in 15 minutes
- Refresh tokens expire in 7 days
- Refresh token rotation on each use
- Device-specific token tracking

## Database Schema

### Users Table
```sql
id          UUID PRIMARY KEY
email       VARCHAR UNIQUE NOT NULL
username    VARCHAR UNIQUE NOT NULL
password    VARCHAR NOT NULL (bcrypt hashed)
firstName   VARCHAR
lastName    VARCHAR
isActive    BOOLEAN DEFAULT true
isVerified  BOOLEAN DEFAULT false
lastLogin   TIMESTAMP
createdAt   TIMESTAMP DEFAULT NOW()
updatedAt   TIMESTAMP DEFAULT NOW()
```

### Refresh Tokens Table
```sql
id          UUID PRIMARY KEY
token       VARCHAR UNIQUE NOT NULL
userId      UUID REFERENCES users(id)
deviceId    VARCHAR
userAgent   VARCHAR
expiresAt   TIMESTAMP NOT NULL
createdAt   TIMESTAMP DEFAULT NOW()
```

## Development

### Available Scripts

```bash
npm start          # Start production server
npm run dev        # Start development server with nodemon
npm test           # Run tests
npm run prisma:generate  # Generate Prisma client
npm run prisma:migrate   # Run database migrations
npm run prisma:reset     # Reset database
npm run prisma:studio    # Open Prisma Studio
```

### Project Structure

```
src/
├── config/
│   └── database.js         # Prisma client configuration
├── middleware/
│   ├── auth.js            # Authentication middleware
│   └── errorHandler.js    # Error handling middleware
├── routes/
│   └── auth.js            # Authentication routes
├── utils/
│   ├── jwt.js             # JWT token utilities
│   └── validateEnv.js     # Environment validation
└── server.js              # Main server file
```

## Production Deployment

### Environment Variables
Ensure all production environment variables are set:
- Use strong, unique JWT secrets
- Set `NODE_ENV=production`
- Configure production database URL
- Set appropriate CORS origins

### Database
- Use connection pooling
- Enable SSL for database connections
- Regular backups and monitoring

### Security
- Use HTTPS in production
- Implement API monitoring
- Regular security audits
- Keep dependencies updated

## Health Check

```http
GET /health
```

Returns server status, uptime, and environment information.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

ISC License - see LICENSE file for details. 