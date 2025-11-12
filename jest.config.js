export default {
  testEnvironment: 'node',
  verbose: true,
  collectCoverage: false,
  roots: ['<rootDir>/tests'],
  extensionsToTreatAsEsm: ['.js'],
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],
  transform: {}
};
