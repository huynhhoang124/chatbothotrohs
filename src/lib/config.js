import dotenv from 'dotenv';

dotenv.config();

const tableNames = {
  users: process.env.USERS_TABLE || 'Users',
  students: process.env.STUDENTS_TABLE || 'Students',
  courses: process.env.COURSES_TABLE || 'Courses',
  enrollments: process.env.ENROLLMENTS_TABLE || 'Enrollments'
};

const corsOrigins = [/^http:\/\/localhost(:\d+)?$/];

export const config = {
  get environment() {
    return process.env.NODE_ENV || 'development';
  },
  tableNames,
  get jwtSecret() {
    return process.env.JWT_SECRET || 'local-secret';
  },
  set jwtSecret(value) {
    process.env.JWT_SECRET = value;
  },
  get openAiKey() {
    return process.env.OPENAI_API_KEY || '';
  },
  set openAiKey(value) {
    process.env.OPENAI_API_KEY = value;
  },
  get dynamoEndpoint() {
    return process.env.DYNAMODB_ENDPOINT || 'http://localhost:8000';
  },
  set dynamoEndpoint(value) {
    process.env.DYNAMODB_ENDPOINT = value;
  },
  corsOrigins
};

export const isProduction = () => config.environment === 'production';
