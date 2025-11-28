const swaggerJSDoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Chrysalis Authentication API',
      version: '1.0.0',
      description:
        'A robust Node.js Express authentication system with Prisma, PostgreSQL, and JWT tokens designed for mobile applications.',
      contact: {
        name: 'Arham Anwar',
        email: 'support@chrysalis.com',
      },
      license: {
        name: 'ISC',
        url: 'https://opensource.org/licenses/ISC',
      },
    },
    // servers: [
    //   {
    //     url: 'http://localhost:3000',
    //     description: 'local server',
    //   },
    //   {
    //     url: 'https://130c4f8aea17.ngrok-free.app',
    //     description: 'Development server',
    //   },
    //   {
    //     url: 'https://api.chrysalis.com',
    //     description: 'Production server',
    //   },
    // ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description:
            'JWT Authorization header using the Bearer scheme. Example: "Authorization: Bearer {token}"',
        },
      },
      schemas: {
        User: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'Unique user identifier',
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'User email address',
            },
            username: {
              type: 'string',
              description: 'Unique username',
            },
            firstName: {
              type: 'string',
              description: 'User first name',
              nullable: true,
            },
            lastName: {
              type: 'string',
              description: 'User last name',
              nullable: true,
            },
            isActive: {
              type: 'boolean',
              description: 'Whether the user account is active',
            },
            isVerified: {
              type: 'boolean',
              description: 'Whether the user email is verified',
            },
            lastLogin: {
              type: 'string',
              format: 'date-time',
              description: 'Last login timestamp',
              nullable: true,
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'Account creation timestamp',
            },
            updatedAt: {
              type: 'string',
              format: 'date-time',
              description: 'Last update timestamp',
            },
          },
        },
        Tokens: {
          type: 'object',
          properties: {
            accessToken: {
              type: 'string',
              description: 'JWT access token (expires in 15 minutes)',
            },
            refreshToken: {
              type: 'string',
              description: 'JWT refresh token (expires in 7 days)',
            },
            expiresAt: {
              type: 'string',
              format: 'date-time',
              description: 'Refresh token expiration time',
            },
          },
        },
        AuthResponse: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              description: 'Operation success status',
            },
            message: {
              type: 'string',
              description: 'Response message',
            },
            data: {
              type: 'object',
              properties: {
                user: {
                  $ref: '#/components/schemas/User',
                },
                tokens: {
                  $ref: '#/components/schemas/Tokens',
                },
              },
            },
          },
        },
        Error: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: false,
              description: 'Operation success status',
            },
            error: {
              type: 'object',
              properties: {
                message: {
                  type: 'string',
                  description: 'Error message',
                },
                details: {
                  type: 'array',
                  items: {
                    type: 'object',
                  },
                  description: 'Detailed validation errors',
                },
              },
            },
            timestamp: {
              type: 'string',
              format: 'date-time',
              description: 'Error timestamp',
            },
            path: {
              type: 'string',
              description: 'Request path where error occurred',
            },
          },
        },
      },
    },
    tags: [
      {
        name: 'Authentication',
        description: 'User authentication endpoints',
      },
      {
        name: 'User Profile',
        description: 'User profile management endpoints',
      },
      {
        name: 'Health',
        description: 'System health and monitoring',
      },
    ],
  },
  apis: ['./src/docs/**/*.js'], // paths to files containing OpenAPI definitions
};

const specs = swaggerJSDoc(options);

module.exports = specs;
