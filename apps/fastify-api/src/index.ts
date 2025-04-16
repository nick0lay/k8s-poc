import fastify from 'fastify';
import sensible from '@fastify/sensible';
import { pino } from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: {
    target: 'pino-pretty'
  }
});

const server = fastify({
  logger
});

server.register(sensible);

// Health check endpoint
server.get('/health', async () => {
  return { status: 'ok' };
});

// Root endpoint
server.get('/', async () => {
  return { message: 'Fastify API is running!' };
});

const start = async () => {
  try {
    const port = process.env.PORT ? parseInt(process.env.PORT) : 3000;
    const host = process.env.HOST || '0.0.0.0';
    await server.listen({ port, host });
    server.log.info(`Server listening on ${host}:${port}`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};

start(); 