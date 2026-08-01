const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const userRepository = require('../repositories/user.repository');
const { hashToken, generateResetToken } = require('../utils/hashToken');
const { ROLES } = require('../constants/roles');
const logger = require('../config/logger');

class AuthService {
  _signAccessToken(userId, role) {
    return jwt.sign(
      { id: userId, role },
      process.env.JWT_ACCESS_SECRET,
      { expiresIn: process.env.JWT_ACCESS_EXPIRY || '15m' },
    );
  }

  _signRefreshToken(userId) {
    return jwt.sign(
      { id: userId },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: process.env.JWT_REFRESH_EXPIRY || '7d' },
    );
  }

  async login(email, password, ipAddress) {
    const user = await userRepository.findByEmail(email, true);
    if (!user) throw { status: 401, message: 'Invalid email or password' };
    if (!user.isActive) throw { status: 401, message: 'Your account has been deactivated' };
    if (!user.accessAllowed) throw { status: 403, message: 'Access denied: You do not have permission to log in' };

    const isMatch = await user.comparePassword(password);
    if (!isMatch) throw { status: 401, message: 'Invalid email or password' };

    const accessToken = this._signAccessToken(user._id, user.role);
    const refreshToken = this._signRefreshToken(user._id);

    user.cleanExpiredTokens();
    user.refreshTokens.push({
      token: hashToken(refreshToken),
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    });
    user.lastLogin = new Date();
    await userRepository.save(user);

    logger.info(`User ${user.email} logged in from ${ipAddress}`);
    return { user, accessToken, refreshToken };
  }

  async refreshSession(refreshToken) {
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    } catch {
      throw { status: 401, message: 'Invalid or expired refresh token' };
    }

    const user = await userRepository.findById(decoded.id);
    if (!user || !user.isActive) throw { status: 401, message: 'User not found or inactive' };

    const hashedToken = hashToken(refreshToken);
    const storedToken = user.refreshTokens.find(
      (t) => t.token === hashedToken && t.expiresAt > Date.now(),
    );
    if (!storedToken) throw { status: 401, message: 'Refresh token revoked or expired' };

    const accessToken = this._signAccessToken(user._id, user.role);
    return { accessToken, user };
  }

  async logout(userId, refreshToken) {
    if (refreshToken) {
      await userRepository.removeRefreshToken(userId, hashToken(refreshToken));
    }
  }

  async forgotPassword(email) {
    const user = await userRepository.findByEmail(email);
    if (!user) return; // Silent fail for security

    const { token, hashedToken, expiry } = generateResetToken();
    await userRepository.updateById(user._id, {
      passwordResetToken: hashedToken,
      passwordResetExpiry: expiry,
    });

    return { token, user };
  }

  async resetPassword(token, newPassword) {
    const hashedToken = hashToken(token);
    const user = await userRepository.findByResetToken(hashedToken);
    if (!user) throw { status: 400, message: 'Invalid or expired reset token' };

    user.password = newPassword;
    user.passwordResetToken = undefined;
    user.passwordResetExpiry = undefined;
    user.refreshTokens = [];
    await userRepository.save(user);
  }

  async changePassword(userId, currentPassword, newPassword) {
    const user = await userRepository.findById(userId);
    if (!user) throw { status: 404, message: 'User not found' };

    const fullUser = await userRepository.findByEmail(user.email, true);
    const isMatch = await fullUser.comparePassword(currentPassword);
    if (!isMatch) throw { status: 400, message: 'Current password is incorrect' };

    fullUser.password = newPassword;
    fullUser.refreshTokens = [];
    await userRepository.save(fullUser);
  }

  async verifyToken(token) {
    try {
      const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
      const user = await userRepository.findById(decoded.id);
      if (!user || !user.isActive) throw new Error('Invalid user');
      if (user.changedPasswordAfter(decoded.iat)) throw new Error('Password changed');
      return { user, decoded };
    } catch (err) {
      throw { status: 401, message: err.message || 'Invalid token' };
    }
  }

  async updateProfile(userId, profileData) {
    const user = await userRepository.updateById(userId, profileData);
    if (!user) throw { status: 404, message: 'User not found' };
    return user;
  }

  async updateAvatar(userId, avatarUrl) {
    const user = await userRepository.updateById(userId, { avatar: avatarUrl });
    if (!user) throw { status: 404, message: 'User not found' };
    return user;
  }
}

module.exports = new AuthService();
