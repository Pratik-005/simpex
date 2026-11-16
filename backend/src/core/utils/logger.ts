import winston from 'winston';
import { env } from '../../config/env.config.js';

const SENSITIVE_KEYS = new Set([
  'password',
  'passwordhash',
  'token',
  'accesstoken',
  'refreshtoken',
  'authorization',
  'cookie',
]);

const redact = (val: unknown): unknown => {
  if (!val || typeof val !== 'object') return val;
  if (val instanceof Error) {
    return {
      message: val.message,
      name: val.name,
      stack: val.stack,
    };
  }
  if (Array.isArray(val)) {
    return val.map(redact);
  }

  const result: Record<string, unknown> = {};
  for (const [key, item] of Object.entries(val as Record<string, unknown>)) {
    if (SENSITIVE_KEYS.has(key.toLowerCase())) {
      result[key] = '[REDACTED]';
    } else if (typeof item === 'object' && item !== null) {
      result[key] = redact(item);
    } else {
      result[key] = item;
    }
  }
  return result;
};

const devFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.colorize(),
  winston.format.printf(({ level, message, timestamp, ...meta }) => {
    const metaKeys = Object.keys(meta);
    const metaString = metaKeys.length > 0 ? ` ${JSON.stringify(meta)}` : '';
    return `[${timestamp}] ${level}: ${message}${metaString}`;
  })
);

const prodFormat = winston.format.combine(
  winston.format.timestamp(),
  winston.format.json()
);

const baseWinstonLogger = winston.createLogger({
  level: env.NODE_ENV === 'test' ? 'silent' : env.NODE_ENV === 'development' ? 'debug' : 'info',
  format: env.NODE_ENV === 'development' ? devFormat : prodFormat,
  transports: [
    new winston.transports.Console({
      silent: env.NODE_ENV === 'test',
    }),
  ],
});

export class AppLogger {
  readonly winston = baseWinstonLogger;

  private logWithHandling(level: string, arg1: unknown, arg2?: unknown): void {
    if (typeof arg1 === 'string') {
      const meta = arg2 && typeof arg2 === 'object' ? (redact(arg2) as Record<string, unknown>) : {};
      baseWinstonLogger.log(level, arg1, meta);
    } else if (typeof arg2 === 'string') {
      const meta = arg1 && typeof arg1 === 'object' ? (redact(arg1) as Record<string, unknown>) : {};
      baseWinstonLogger.log(level, arg2, meta);
    } else if (arg1 && typeof arg1 === 'object') {
      baseWinstonLogger.log(level, '', redact(arg1) as Record<string, unknown>);
    } else {
      baseWinstonLogger.log(level, String(arg1 ?? ''));
    }
  }

  info(arg1: unknown, arg2?: unknown): void {
    this.logWithHandling('info', arg1, arg2);
  }

  warn(arg1: unknown, arg2?: unknown): void {
    this.logWithHandling('warn', arg1, arg2);
  }

  error(arg1: unknown, arg2?: unknown): void {
    this.logWithHandling('error', arg1, arg2);
  }

  debug(arg1: unknown, arg2?: unknown): void {
    this.logWithHandling('debug', arg1, arg2);
  }
}

export const logger = new AppLogger();
