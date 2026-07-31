require('dotenv').config();
const app = require('./app');
const connectDB = require('./config/database');
const { configureCloudinary } = require('./config/cloudinary');
const logger = require('./config/logger');

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  await connectDB();
  configureCloudinary();

  const server = app.listen(PORT, () => {
    logger.info(`BRL Nexus API running on port ${PORT} in ${process.env.NODE_ENV} mode`);
    logger.info(`Health: http://localhost:${PORT}/health`);
  });

  const shutdown = async (signal) => {
    logger.info(`${signal} received. Shutting down gracefully...`);
    server.close(() => {
      logger.info('HTTP server closed.');
      process.exit(0);
    });
    setTimeout(() => process.exit(1), 10000);
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('unhandledRejection', (reason) => {
    logger.error('Unhandled Rejection:', reason);
    server.close(() => process.exit(1));
  });
};

startServer();
