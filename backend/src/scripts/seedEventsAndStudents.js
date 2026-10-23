require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('../config/database');
const initData = require('../database/initData');
const logger = require('../config/logger');

async function run() {
  try {
    await connectDB();
    logger.info('Running event and student configuration seeder...');
    await initData();
    logger.info('Database events and registrations successfully configured.');
    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    logger.error('Failed to configure events and registrations', { error: err.message });
    process.exit(1);
  }
}

run();
