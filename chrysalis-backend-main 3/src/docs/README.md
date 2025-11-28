# API Documentation Structure

This directory contains all the Swagger/OpenAPI documentation for the Chrysalis API, organized for better maintainability and separation of concerns.

## Directory Structure

```
src/docs/
├── README.md          # This file - documentation structure overview
├── schemas.js         # Request/Response schema definitions
└── paths/             # API endpoint documentation
    ├── auth.js        # Authentication endpoints
    └── health.js      # Health check endpoint
```

## Organization

### Schemas (`schemas.js`)
Contains all the reusable schema definitions including:
- `RegisterRequest` - User registration request schema
- `LoginRequest` - User login request schema  
- `RefreshTokenRequest` - Token refresh request schema
- `UpdateProfileRequest` - Profile update request schema
- `ChangePasswordRequest` - Password change request schema

### Paths (`paths/`)
Contains endpoint-specific documentation organized by feature:

#### Authentication (`paths/auth.js`)
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/refresh` - Token refresh
- `POST /api/v1/auth/logout` - Single device logout
- `POST /api/v1/auth/logout-all` - All devices logout
- `GET /api/v1/auth/me` - Get user profile
- `PUT /api/v1/auth/me` - Update user profile
- `PUT /api/v1/auth/change-password` - Change password

#### Health (`paths/health.js`)
- `GET /health` - Health check endpoint

## Usage

The Swagger configuration (`src/config/swagger.js`) automatically scans this directory structure using the pattern `./src/docs/**/*.js` to include all documentation files.

## Benefits

1. **Separation of Concerns**: Documentation is separated from business logic
2. **Better Organization**: Related endpoints are grouped together
3. **Easier Maintenance**: Changes to API docs don't require touching route files
4. **Cleaner Code**: Route files focus purely on implementation
5. **Team Collaboration**: Different team members can work on docs and implementation independently 