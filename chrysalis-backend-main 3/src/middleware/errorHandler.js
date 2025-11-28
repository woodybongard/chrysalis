const { Prisma } = require('@prisma/client');

// Not found middleware
const notFound = (req, res, next) => {
  const error = new Error(`Endpoint not found - ${req.originalUrl}`);
  res.status(404);
  next(error);
};

// General error handler
const errorHandler = (err, req, res, next) => {
  let statusCode = res.statusCode === 200 ? 500 : res.statusCode;
  let message = err.message;

  // Handle Prisma errors
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    switch (err.code) {
      case 'P2002':
        // Unique constraint failed
        const field = err.meta?.target?.[0] || 'field';
        statusCode = 409;
        message = `A record with this ${field} already exists`;
        break;
      case 'P2025':
        // Record not found
        statusCode = 404;
        message = 'Record not found';
        break;
      case 'P2003':
        // Foreign key constraint failed
        statusCode = 400;
        message = 'Invalid reference to related record';
        break;
      default:
        statusCode = 500;
        message = 'Database operation failed';
        break;
    }
  }

  // Handle Prisma validation errors
  if (err instanceof Prisma.PrismaClientValidationError) {
    statusCode = 400;
    message = 'Invalid data provided';
  }

  // Handle JWT errors
  if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = 'Invalid token';
  }

  if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = 'Token expired';
  }

  // Handle validation errors
  if (err.name === 'ValidationError') {
    statusCode = 400;
    message = err.message;
  }

  // Log error in development
  if (process.env.NODE_ENV === 'development') {
    console.error('Error:', {
      message: err.message,
      stack: err.stack,
      url: req.originalUrl,
      method: req.method,
      ip: req.ip,
      userAgent: req.get('User-Agent'),
    });
  }

  res.status(statusCode).json({
    success: false,
    error: {
      message,
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    },
    timestamp: new Date().toISOString(),
    path: req.originalUrl,
  });
};

module.exports = {
  notFound,
  errorHandler,
}; 