import morgan from 'morgan';
import { isProduction } from './config.js';

const format = isProduction() ? 'combined' : 'dev';

export const requestLogger = morgan(format, {
  stream: {
    write: (message) => {
      console.log(message.trim());
    }
  }
});

export const logError = (error, context = {}) => {
  console.error('[LỖI]', {
    message: error.message,
    name: error.name,
    context
  });
};
