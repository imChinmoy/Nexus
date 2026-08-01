require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User.model');
const { ROLES } = require('../constants/roles');
const connectDB = require('../config/database');

const seedSuperAdmin = async () => {
  await connectDB();

  try {
    // Check if super admin already exists
    const existingAdmin = await User.findOne({ role: ROLES.SUPER_ADMIN });
    if (existingAdmin) {
      console.log('Super Admin already exists:', existingAdmin.email);
      process.exit(0);
    }

    // Create a new super admin
    const superAdmin = new User({
      name: 'Super Admin',
      email: 'admin@brlnexus.com',
      password: 'password123', // Change this in production
      role: ROLES.SUPER_ADMIN,
      isActive: true,
      accessAllowed: true,
    });

    await superAdmin.save();
    console.log('Super Admin created successfully!');
    console.log('Email: admin@brlnexus.com');
    console.log('Password: password123');
    
    process.exit(0);
  } catch (error) {
    console.error('Error seeding super admin:', error);
    process.exit(1);
  }
};

seedSuperAdmin();
