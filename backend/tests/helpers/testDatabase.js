process.env.NODE_ENV = 'test';
process.env.MONGODB_URI = process.env.TEST_MONGODB_URI || 'mongodb://127.0.0.1:27099/brl_nexus_test';
process.env.JWT_ACCESS_SECRET = 'test_jwt_access_secret_for_tests_12345';
process.env.JWT_REFRESH_SECRET = 'test_jwt_refresh_secret_for_tests_12345';
process.env.QR_SECRET = 'test_qr_secret_for_tests_12345';
process.env.RATE_LIMIT_MAX = '1000';
process.env.RATE_LIMIT_QR_MAX = '1000';

const mongoose = require('mongoose');

const connectTestDB = async () => {
  if (mongoose.connection.readyState === 0) {
    await mongoose.connect(process.env.MONGODB_URI);
  }
};

const clearTestDB = async () => {
  if (mongoose.connection.readyState !== 0) {
    const collections = mongoose.connection.collections;
    for (const key in collections) {
      await collections[key].deleteMany({});
    }
  }
};

const closeTestDB = async () => {
  if (mongoose.connection.readyState !== 0) {
    await mongoose.connection.dropDatabase();
    await mongoose.disconnect();
  }
};

module.exports = { connectTestDB, clearTestDB, closeTestDB };
