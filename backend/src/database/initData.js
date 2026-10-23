const mongoose = require('mongoose');
const Event = require('../models/Event.model');
const Student = require('../models/Student.model');
const User = require('../models/User.model');
const Attendance = require('../models/Attendance.model');
const { ROLES } = require('../constants/roles');
const logger = require('../config/logger');

const reloadSeedStudents = [
  {
    name: 'Aarav Sharma',
    rollNo: '2100290100001',
    studentNo: '210001',
    phone: '9876543210',
    email: 'aarav.210001@akgec.ac.in',
    branch: 'CSE',
    year: 3,
    domain: 'Full Stack',
    gender: 'Male',
    hosteller: true,
    github: 'https://github.com/aaravsharma',
    unstopProfile: 'https://unstop.com/aarav',
    hackerrank: 'aarav_sharma',
  },
  {
    name: 'Bhavna Verma',
    rollNo: '2100290100002',
    studentNo: '210002',
    phone: '9876543211',
    email: 'bhavna.210002@akgec.ac.in',
    branch: 'IT',
    year: 3,
    domain: 'AIML',
    gender: 'Female',
    hosteller: false,
    github: 'https://github.com/bhavnaverma',
    unstopProfile: 'https://unstop.com/bhavna',
    hackerrank: 'bhavna_verma',
  },
  {
    name: 'Chirag Gupta',
    rollNo: '2100290100003',
    studentNo: '210003',
    phone: '9876543212',
    email: 'chirag.210003@akgec.ac.in',
    branch: 'ECE',
    year: 2,
    domain: 'Blockchain',
    gender: 'Male',
    hosteller: true,
    github: 'https://github.com/chiraggupta',
    unstopProfile: 'https://unstop.com/chirag',
    hackerrank: 'chirag_gupta',
  },
  {
    name: 'Divya Singh',
    rollNo: '2100290100004',
    studentNo: '210004',
    phone: '9876543213',
    email: 'divya.210004@akgec.ac.in',
    branch: 'CSE',
    year: 3,
    domain: 'UI/UX',
    gender: 'Female',
    hosteller: false,
    github: 'https://github.com/divyasingh',
    unstopProfile: 'https://unstop.com/divya',
    hackerrank: 'divya_singh',
  },
  {
    name: 'Eshan Roy',
    rollNo: '2100290100005',
    studentNo: '210005',
    phone: '9876543214',
    email: 'eshan.210005@akgec.ac.in',
    branch: 'CS',
    year: 2,
    domain: 'Full Stack',
    gender: 'Male',
    hosteller: true,
    github: 'https://github.com/eshanroy',
    unstopProfile: 'https://unstop.com/eshan',
    hackerrank: 'eshan_roy',
  },
  {
    name: 'Farhan Khan',
    rollNo: '2100290100006',
    studentNo: '210006',
    phone: '9876543215',
    email: 'farhan.210006@akgec.ac.in',
    branch: 'IT',
    year: 3,
    domain: 'DevOps',
    gender: 'Male',
    hosteller: false,
    github: 'https://github.com/farhankhan',
    unstopProfile: 'https://unstop.com/farhan',
    hackerrank: 'farhan_khan',
  },
  {
    name: 'Garima Agarwal',
    rollNo: '2100290100007',
    studentNo: '210007',
    phone: '9876543216',
    email: 'garima.210007@akgec.ac.in',
    branch: 'CSE',
    year: 2,
    domain: 'AIML',
    gender: 'Female',
    hosteller: true,
    github: 'https://github.com/garimaagarwal',
    unstopProfile: 'https://unstop.com/garima',
    hackerrank: 'garima_agarwal',
  },
  {
    name: 'Harsh Tiwari',
    rollNo: '2100290100008',
    studentNo: '210008',
    phone: '9876543217',
    email: 'harsh.210008@akgec.ac.in',
    branch: 'ECE',
    year: 3,
    domain: 'Cybersecurity',
    gender: 'Male',
    hosteller: false,
    github: 'https://github.com/harshtiwari',
    unstopProfile: 'https://unstop.com/harsh',
    hackerrank: 'harsh_tiwari',
  },
  {
    name: 'Ishaan Patel',
    rollNo: '2100290100009',
    studentNo: '210009',
    phone: '9876543218',
    email: 'ishaan.210009@akgec.ac.in',
    branch: 'CSIT',
    year: 2,
    domain: 'Full Stack',
    gender: 'Male',
    hosteller: true,
    github: 'https://github.com/ishaanpatel',
    unstopProfile: 'https://unstop.com/ishaan',
    hackerrank: 'ishaan_patel',
  },
  {
    name: 'Jaya Mishra',
    rollNo: '2100290100010',
    studentNo: '210010',
    phone: '9876543219',
    email: 'jaya.210010@akgec.ac.in',
    branch: 'CSE',
    year: 3,
    domain: 'Blockchain',
    gender: 'Female',
    hosteller: false,
    github: 'https://github.com/jayamishra',
    unstopProfile: 'https://unstop.com/jaya',
    hackerrank: 'jaya_mishra',
  },
];

const seminarSeedStudents = [
  {
    name: 'Kunal Sen',
    rollNo: '2100290100011',
    studentNo: '210011',
    phone: '9876543220',
    email: 'kunal.210011@akgec.ac.in',
    branch: 'CSE',
    year: 3,
    domain: 'AI & Data Science',
    gender: 'Male',
    hosteller: true,
  },
  {
    name: 'Lavanya Nair',
    rollNo: '2100290100012',
    studentNo: '210012',
    phone: '9876543221',
    email: 'lavanya.210012@akgec.ac.in',
    branch: 'IT',
    year: 2,
    domain: 'Machine Learning',
    gender: 'Female',
    hosteller: false,
  },
  {
    name: 'Manish Pandey',
    rollNo: '2100290100013',
    studentNo: '210013',
    phone: '9876543222',
    email: 'manish.210013@akgec.ac.in',
    branch: 'ECE',
    year: 4,
    domain: 'Embedded Systems',
    gender: 'Male',
    hosteller: true,
  },
  {
    name: 'Neha Saxena',
    rollNo: '2100290100014',
    studentNo: '210014',
    phone: '9876543223',
    email: 'neha.210014@akgec.ac.in',
    branch: 'CSE',
    year: 3,
    domain: 'Cloud Architecture',
    gender: 'Female',
    hosteller: false,
  },
  {
    name: 'Omkar Srivastava',
    rollNo: '2100290100015',
    studentNo: '210015',
    phone: '9876543224',
    email: 'omkar.210015@akgec.ac.in',
    branch: 'CS',
    year: 2,
    domain: 'Distributed Systems',
    gender: 'Male',
    hosteller: true,
  },
];

async function initData() {
  try {
    if (mongoose.connection.readyState !== 1) {
      return;
    }

    // 1. Resolve or create Admin user for event creation reference
    let admin = await User.findOne({ role: { $in: [ROLES.SUPER_ADMIN, ROLES.ADMIN] } });
    if (!admin) {
      admin = await User.create({
        name: 'Super Admin',
        email: 'superadmin@brl.com',
        password: 'password123',
        role: ROLES.SUPER_ADMIN,
        isActive: true,
      });
      logger.info('Initialized super admin user for event management');
    }

    // 2. Ensure existing events have registrationSourceKey configured properly
    await Event.updateMany(
      { title: { $regex: /reload/i }, $or: [{ registrationSourceKey: { $exists: false } }, { registrationSourceKey: null }, { registrationSourceKey: '' }] },
      { $set: { registrationSourceKey: 'reload' } }
    );
    await Event.updateMany(
      { title: { $regex: /seminar|expert/i }, $or: [{ registrationSourceKey: { $exists: false } }, { registrationSourceKey: null }, { registrationSourceKey: '' }] },
      { $set: { registrationSourceKey: 'expert-seminar' } }
    );

    // 3. Ensure 'Reload 26, Recruitment Drive' event exists
    let reloadEvent = await Event.findOne({ title: { $regex: /reload/i } });
    if (!reloadEvent) {
      reloadEvent = await Event.create({
        title: 'Reload 26, Recruitment Drive',
        description: 'Annual flagship recruitment drive and technical challenge for Blockchain Research Lab.',
        type: 'recruitment',
        status: 'ongoing',
        isAttendanceOpen: true,
        registrationSourceKey: 'reload',
        venue: 'Main Auditorium, Campus North',
        capacity: 350,
        startDate: new Date(Date.now() - 3600000), // started 1 hour ago
        endDate: new Date(Date.now() + 86400000 * 3),
        createdBy: admin._id,
      });
      logger.info('Created canonical event: Reload 26, Recruitment Drive');
    } else {
      // Ensure it has registrationSourceKey and open attendance
      if (!reloadEvent.registrationSourceKey) {
        reloadEvent.registrationSourceKey = 'reload';
        await reloadEvent.save();
      }
    }

    // 4. Ensure 'Expert Seminar 2026' event exists
    let seminarEvent = await Event.findOne({ title: { $regex: /seminar/i } });
    if (!seminarEvent) {
      seminarEvent = await Event.create({
        title: 'Expert Seminar 2026',
        description: 'AI & Web3 Seminar by industry leaders and research mentors.',
        type: 'seminar',
        status: 'upcoming',
        isAttendanceOpen: false,
        registrationSourceKey: 'expert-seminar',
        venue: 'Seminar Hall 2',
        capacity: 150,
        startDate: new Date(Date.now() + 86400000 * 5),
        endDate: new Date(Date.now() + 86400000 * 5 + 3600000 * 3),
        createdBy: admin._id,
      });
      logger.info('Created canonical event: Expert Seminar 2026');
    } else {
      if (!seminarEvent.registrationSourceKey) {
        seminarEvent.registrationSourceKey = 'expert-seminar';
        await seminarEvent.save();
      }
    }

    // 5. Seed external registrations in RELOAD-REGISTRATION
    try {
      const reloadDb = mongoose.connection.useDb('RELOAD-REGISTRATION', { useCache: true });
      const reloadRegCol = reloadDb.collection('registrations');
      for (const student of reloadSeedStudents) {
        await reloadRegCol.updateOne(
          { rollNo: student.rollNo },
          { $set: student },
          { upsert: true }
        );
      }
      logger.info('Configured RELOAD-REGISTRATION registrations dataset');
    } catch (err) {
      logger.warn('Could not seed RELOAD-REGISTRATION database directly', { error: err.message });
    }

    // 6. Seed external registrations in EXPERT-SEMINAR-REGISTRATION
    try {
      const seminarDb = mongoose.connection.useDb('EXPERT-SEMINAR-REGISTRATION', { useCache: true });
      const seminarRegCol = seminarDb.collection('registrations');
      for (const student of seminarSeedStudents) {
        await seminarRegCol.updateOne(
          { rollNo: student.rollNo },
          { $set: student },
          { upsert: true }
        );
      }
      logger.info('Configured EXPERT-SEMINAR-REGISTRATION registrations dataset');
    } catch (err) {
      logger.warn('Could not seed EXPERT-SEMINAR-REGISTRATION database directly', { error: err.message });
    }

    // 7. Seed Student collection in brl_nexus
    const allStudents = [...reloadSeedStudents, ...seminarSeedStudents];
    for (const studentData of allStudents) {
      await Student.updateOne(
        { rollNo: studentData.rollNo },
        {
          $set: {
            ...studentData,
            isActive: true,
          },
        },
        { upsert: true }
      );
    }
    logger.info(`Synchronized ${allStudents.length} students into primary Nexus database`);

    // 8. Create sample attendance for Reload event
    if (reloadEvent) {
      const presentRollNos = ['2100290100001', '2100290100002', '2100290100003'];
      const presentStudents = await Student.find({ rollNo: { $in: presentRollNos } });

      for (const st of presentStudents) {
        await Attendance.updateOne(
          { event: reloadEvent._id, student: st._id },
          {
            $set: {
              event: reloadEvent._id,
              student: st._id,
              status: 'present',
              method: 'qr',
              markedBy: admin._id,
              markedAt: new Date(),
            },
          },
          { upsert: true }
        );
        st.isPresent = true;
        st.lastMarkedAt = new Date();
        await st.save();
      }
      logger.info('Configured live attendance records for Reload 26 event');
    }
  } catch (err) {
    logger.error('Error during data initialization and configuration', { error: err.message });
  }
}

module.exports = initData;
