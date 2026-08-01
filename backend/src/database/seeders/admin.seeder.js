require('dotenv').config({ path: require('path').join(__dirname, '../../../.env') });
const mongoose = require('mongoose');
const User = require('../../models/User.model');
const Settings = require('../../models/Settings.model');
const { ROLES } = require('../../constants/roles');
const { PERMISSIONS } = require('../../constants/permissions');

const seed = async () => {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to MongoDB');

  // Create super admin
  const existing = await User.findOne({ email: 'superadmin@brl.com' });
  if (!existing) {
    await User.create({
      name: 'Super Admin',
      email: 'superadmin@brl.com',
      password: 'BRL@Admin2024',
      role: ROLES.SUPER_ADMIN,
      isActive: true,
    });
    console.log('Super Admin created: superadmin@brl.com / BRL@Admin2024');
  } else {
    console.log('Super Admin already exists');
  }

  // Default settings
  const defaultSettings = [
    { key: 'society_name', value: 'Blockchain Research Lab', isPublic: true },
    { key: 'society_short_name', value: 'BRL', isPublic: true },
    { key: 'society_email', value: 'brl@college.edu', isPublic: true },
    { key: 'attendance_late_threshold_minutes', value: 15 },
    { key: 'qr_expiry_minutes', value: 10 },
    { key: 'max_events_per_page', value: 20 },
    {
      key: 'role_permissions',
      value: {
        [ROLES.SUPER_ADMIN]: [PERMISSIONS.ALL],
        [ROLES.ADMIN]: [PERMISSIONS.ALL],
        [ROLES.COORDINATOR]: [PERMISSIONS.ATTENDANCE_MARK, PERMISSIONS.EVENT_ADD],
        [ROLES.VOLUNTEER]: [],
        [ROLES.VIEWER]: []
      },
      isPublic: false
    }
  ];

  for (const s of defaultSettings) {
    await Settings.findOneAndUpdate({ key: s.key }, s, { upsert: true });
  }
  console.log('Default settings seeded');

  await mongoose.disconnect();
  console.log('Seeding complete');
  process.exit(0);
};

seed().catch((err) => { console.error(err); process.exit(1); });
