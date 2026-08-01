const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const { cloudinary } = require('../config/cloudinary');

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'brl_nexus/events',
    allowed_formats: ['jpg', 'png', 'jpeg', 'webp'],
    // Events usually have wide banners like 16:9 or similar
    transformation: [{ width: 1280, height: 720, crop: 'limit' }],
  },
});

const eventUpload = multer({ 
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit for event banners
  }
});

module.exports = eventUpload;
