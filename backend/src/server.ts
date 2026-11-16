import { createApp } from './app.js';
import { env } from './config/env.config.js';
import { connectDatabase, disconnectDatabase } from './config/database.config.js';
import { logger } from './core/utils/logger.js';

import { categoryService } from './modules/categories/category.service.js';

const startServer = async () => {
  const app = createApp();
  try {
    await connectDatabase();
    await categoryService.seedDefaults();
  } catch (err) {
    logger.warn('Starting server without immediate MongoDB connection (will retry or serve degraded)');
  }

  const server = app.listen(env.PORT, '0.0.0.0', () => {
    logger.info(`🚀 Simpex Backend service running on port ${env.PORT} (0.0.0.0)`);
  });

  const shutdown = async (signal: string) => {

    logger.info(`Received ${signal}. Starting graceful shutdown...`);

    server.close(async () => {
      logger.info('HTTP server closed');
      await disconnectDatabase();
      logger.info('All resources released. Exiting process.');
      process.exit(0);
    });

    setTimeout(() => {
      logger.error('Graceful shutdown timeout exceeded. Forcefully terminating.');
      process.exit(1);
    }, 10000).unref();

  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
};

startServer().catch((error) => {
  logger.error({ error }, 'Fatal error during server startup');
  process.exit(1);
});
