const User = require('../models/User.model');

class UserRepository {
  async create(data) { return User.create(data); }

  async findById(id, includePassword = false) {
    const query = User.findById(id);
    if (includePassword) query.select('+password');
    return query.exec();
  }

  async findByEmail(email, includePassword = false) {
    const query = User.findOne({ email: email.toLowerCase() });
    if (includePassword) query.select('+password +passwordResetToken +passwordResetExpiry');
    return query.exec();
  }

  async findByResetToken(hashedToken) {
    return User.findOne({
      passwordResetToken: hashedToken,
      passwordResetExpiry: { $gt: Date.now() },
    }).select('+password +passwordResetToken +passwordResetExpiry').exec();
  }

  async findAll({ filter = {}, sort = { createdAt: -1 }, skip = 0, limit = 20 } = {}) {
    const [data, total] = await Promise.all([
      User.find(filter).sort(sort).skip(skip).limit(limit),
      User.countDocuments(filter),
    ]);
    return { data, total };
  }

  async updateById(id, data) {
    return User.findByIdAndUpdate(id, data, { new: true, runValidators: true });
  }

  async save(user) { return user.save(); }

  async deleteById(id) { return User.findByIdAndDelete(id); }

  async addRefreshToken(userId, tokenData) {
    return User.findByIdAndUpdate(
      userId,
      { $push: { refreshTokens: tokenData } },
      { new: true },
    );
  }

  async removeRefreshToken(userId, token) {
    return User.findByIdAndUpdate(
      userId,
      { $pull: { refreshTokens: { token } } },
    );
  }
}

module.exports = new UserRepository();
