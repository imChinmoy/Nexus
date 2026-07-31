const mongoose = require('mongoose');

const memberSchema = new mongoose.Schema(
  {
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
    role: { type: String, required: true, trim: true },
    committee: {
      type: String,
      enum: ['executive', 'core', 'associate', 'volunteer'],
      default: 'volunteer',
    },
    department: { type: String, trim: true },
    joinedAt: { type: Date, default: Date.now },
    isActive: { type: Boolean, default: true },
    responsibilities: [{ type: String, trim: true }],
    socialLinks: {
      linkedin: { type: String },
      github: { type: String },
      twitter: { type: String },
    },
    bio: { type: String, maxlength: 500 },
    order: { type: Number, default: 0 },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true, transform: (_, ret) => { delete ret.__v; return ret; } },
  },
);

memberSchema.index({ student: 1 }, { unique: true });
memberSchema.index({ committee: 1, isActive: 1 });
memberSchema.index({ order: 1 });

module.exports = mongoose.model('Member', memberSchema);
