const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
const compression = require('compression');
const cookieParser = require('cookie-parser');
const swaggerUi = require('swagger-ui-express');
const http = require('http');
const { initSocket } = require('./socket');

require('dotenv').config();

const authRoutes = require('./routes/auth');
const messageRoutes = require('./routes/chat');
const groupRoutes = require('./routes/groups.route');
const keyRoutes = require('./routes/keys');
const searchRoutes = require('./routes/search');
const userRoutes = require('./routes/users');
const auditLogRoutes = require('./routes/auditlog');
const { errorHandler, notFound } = require('./middleware/errorHandler');
const { validateEnvironment } = require('./utils/validateEnv');
const swaggerSpecs = require('./config/swagger');

// Validate environment variables
validateEnvironment();

const app = express();
const PORT = process.env.PORT || 3000;

// Trust proxy for accurate IP addresses
app.set('trust proxy', 1);
const server = http.createServer(app);
const io = initSocket(server);

// Security middleware
// app.use(
//   helmet({
//     crossOriginEmbedderPolicy: false,
//     contentSecurityPolicy: {
//       directives: {
//         defaultSrc: ["'self'"],
//         styleSrc: ["'self'", "'unsafe-inline'"],
//         scriptSrc: ["'self'"],
//         imgSrc: ["'self'", 'data:', 'https:'],
//       },
//     },
//   }),
// );

// CORS configuration
const corsOptions = {
  origin: function (origin, callback) {
    callback(null, true); // Reflects the origin of the request
  },
  credentials: true, // Required to expose cookies or Authorization headers
  optionsSuccessStatus: 200,
};

app.use(cors(corsOptions));

// Rate limiting
// const limiter = rateLimit({
//   windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
//   max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
//   message: {
//     error: 'Too many requests from this IP, please try again later.',
//   },
//   standardHeaders: true,
//   legacyHeaders: false,
// });
// app.use(limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(cookieParser());

// Compression
app.use(compression());

// Logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Swagger API Documentation
app.use(
  '/api/v1/docs',
  swaggerUi.serve,
  swaggerUi.setup(swaggerSpecs, {
    explorer: true,
    customCss: '.swagger-ui .topbar',
    customSiteTitle: 'Chrysalis API Documentation',
    swaggerOptions: {
      filter: true,
      tryItOutEnabled: true,
      persistAuthorization: true,
    },
  }),
);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV,
  });
});

// API routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/messages', messageRoutes);
app.use('/api/v1/groups', groupRoutes);
app.use('/api/v1/keys', keyRoutes);
app.use('/api/v1/search', searchRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/auditLog', auditLogRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Chrysalis API Server',
    version: '1.0.0',
    documentation: '/api/v1/docs',
    health: '/health',
  });
});

// Error handling middleware
app.use(notFound);
app.use(errorHandler);

// Graceful shutdown
const gracefulShutdown = () => {
  console.log('Received shutdown signal, closing server gracefully...');
  process.exit(0);
};

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

app.set('io', io);

// Start server
server.listen(PORT, () => {
  console.log(
    `🚀 Server running on port ${PORT} in ${process.env.NODE_ENV} mode`,
  );
  console.log(`📚 API Documentation: http://localhost:${PORT}/api/v1/docs`);
  console.log(`❤️  Health Check: http://localhost:${PORT}/health`);
});
