import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  QueryCommand,
  ScanCommand,
  UpdateCommand,
  DeleteCommand
} from '@aws-sdk/lib-dynamodb';
import { config } from './config.js';

export const tables = config.tableNames;

const isTestEnv = process.env.NODE_ENV === 'test';

let documentClient;
if (!isTestEnv) {
  const dynamoClient = new DynamoDBClient({
    region: 'local',
    endpoint: config.dynamoEndpoint,
    credentials: {
      accessKeyId: 'fakeMyKeyId',
      secretAccessKey: 'fakeSecretAccessKey'
    }
  });

  documentClient = DynamoDBDocumentClient.from(dynamoClient, {
    marshallOptions: {
      removeUndefinedValues: true
    }
  });
}

const memoryStore = Object.values(tables).reduce((acc, tableName) => {
  acc[tableName] = new Map();
  return acc;
}, {});

const clone = (value) => JSON.parse(JSON.stringify(value));

const applyFilter = (item, { FilterExpression, ExpressionAttributeValues }) => {
  if (!FilterExpression) return true;
  const values = ExpressionAttributeValues || {};
  if (FilterExpression.includes('contains(fullName, :keyword)')) {
    const keyword = values[':keyword'] || '';
    return (
      item.fullName?.toLowerCase().includes(keyword.toLowerCase()) ||
      item.email?.toLowerCase().includes(keyword.toLowerCase())
    );
  }
  if (FilterExpression.includes('email = :email')) {
    return item.email === values[':email'];
  }
  if (FilterExpression.includes('semester = :semester')) {
    return item.semester === values[':semester'];
  }
  return true;
};

const queryByIndex = (table, indexName, values) => {
  const items = Array.from(memoryStore[table].values());
  if (indexName === 'gsi_email') {
    const email = values[':email'];
    return items.filter((item) => item.email === email);
  }
  if (indexName === 'gsi_student') {
    const studentId = values[':studentId'];
    return items.filter((item) => item.studentId === studentId);
  }
  return items;
};

export const resetMemoryStore = () => {
  Object.keys(memoryStore).forEach((table) => memoryStore[table].clear());
};

export const getDocumentClient = () => {
  if (isTestEnv) {
    throw new Error('DocumentClient không khả dụng trong môi trường test in-memory.');
  }
  return documentClient;
};

export const dbGet = async (params) => {
  if (isTestEnv) {
    const table = params.TableName;
    const keyName = Object.keys(params.Key)[0];
    const keyValue = params.Key[keyName];
    const item = memoryStore[table].get(keyValue);
    return { Item: item ? clone(item) : undefined };
  }
  return documentClient.send(new GetCommand(params));
};

export const dbPut = async (params) => {
  if (isTestEnv) {
    const table = params.TableName;
    const item = clone(params.Item);
    const keyName = Object.keys(item).find((key) => key.endsWith('Id'));
    if (!keyName) throw new Error('Không xác định được khóa chính.');
    memoryStore[table].set(item[keyName], item);
    return {};
  }
  return documentClient.send(new PutCommand(params));
};

export const dbScan = async (params) => {
  if (isTestEnv) {
    const table = params.TableName;
    const items = Array.from(memoryStore[table].values()).filter((item) =>
      applyFilter(item, params)
    );
    return { Items: clone(items) };
  }
  return documentClient.send(new ScanCommand(params));
};

export const dbQuery = async (params) => {
  if (isTestEnv) {
    const table = params.TableName;
    const items = queryByIndex(table, params.IndexName, params.ExpressionAttributeValues || {});
    return { Items: clone(items) };
  }
  return documentClient.send(new QueryCommand(params));
};

export const dbUpdate = async (params) => {
  if (isTestEnv) {
    const table = params.TableName;
    const keyName = Object.keys(params.Key)[0];
    const keyValue = params.Key[keyName];
    const existing = memoryStore[table].get(keyValue) || {};
    const updated = { ...existing, ...(params.ExpressionAttributeValues?.[':value'] || {}) };
    memoryStore[table].set(keyValue, updated);
    return { Attributes: clone(updated) };
  }
  return documentClient.send(new UpdateCommand(params));
};

export const dbDelete = async (params) => {
  if (isTestEnv) {
    const table = params.TableName;
    const keyName = Object.keys(params.Key)[0];
    const keyValue = params.Key[keyName];
    memoryStore[table].delete(keyValue);
    return {};
  }
  return documentClient.send(new DeleteCommand(params));
};

export const __memoryStore = memoryStore;
