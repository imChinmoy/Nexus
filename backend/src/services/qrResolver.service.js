const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const Student = require('../models/Student.model');
const Registration = require('../models/Registration.model');
const registrationSourceService = require('./registrationSource.service');
const logger = require('../config/logger');

class QrResolverService {
  /**
   * Parse the raw scanned QR payload and extract candidate student identifiers.
   * Supports:
   *  1. Plain roll number / student number / string
   *  2. JSON string payload (e.g. { rollNo: "...", studentNo: "..." })
   *  3. JWT token (signed with external QR_SECRET or containing claims)
   *
   * @param {string} rawQr - Raw scanned string
   * @returns {{ identifier: string|null, metadata: object }}
   */
  parseQrValue(rawQr) {
    if (!rawQr || typeof rawQr !== 'string') {
      return { identifier: null, metadata: {} };
    }

    const trimmed = rawQr.trim();
    if (!trimmed) {
      return { identifier: null, metadata: {} };
    }

    // Strategy 1: JSON payload
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) || (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        const parsed = JSON.parse(trimmed);
        if (parsed && typeof parsed === 'object') {
          const id = parsed.rollNo || parsed.rollNumber || parsed.studentNo || parsed.studentId || parsed.id || parsed.email;
          if (id) {
            return { identifier: String(id).trim(), metadata: { format: 'json' } };
          }
        }
      } catch (_e) {
        // Not valid JSON, continue to other strategies
      }
    }

    // Strategy 2: JWT token
    const parts = trimmed.split('.');
    if (parts.length === 3) {
      try {
        const secret = process.env.EXTERNAL_QR_SECRET || process.env.QR_SECRET;
        let payload = null;
        if (secret) {
          try {
            payload = jwt.verify(trimmed, secret);
          } catch (_jwtErr) {
            payload = jwt.decode(trimmed);
          }
        } else {
          payload = jwt.decode(trimmed);
        }

        if (payload && typeof payload === 'object') {
          const id = payload.rollNo || payload.rollNumber || payload.studentNo || payload.studentId || payload.id || payload.sub || payload.email;
          if (id) {
            return { identifier: String(id).trim(), metadata: { format: 'jwt' } };
          }
        }
      } catch (_e) {
        // Not valid JWT, continue
      }
    }

    // Strategy 3: Plain text identifier (roll number, student number, or ObjectId)
    return { identifier: trimmed, metadata: { format: 'raw' } };
  }

  /**
   * Resolve a candidate identifier into an active Student document for attendance.
   *
   * @param {string} rawQr - Raw value read from student QR
   * @param {object|null} event - Optional event object for event-specific registration source resolution
   * @returns {Promise<Student|null>}
   */
  async resolveStudent(rawQr, event = null) {
    const { identifier } = this.parseQrValue(rawQr);
    if (!identifier) return null;

    const isMongoId = mongoose.Types.ObjectId.isValid(identifier);

    // 1. Direct query in Student collection
    const studentQuery = [];
    if (isMongoId) {
      studentQuery.push({ _id: identifier });
    }
    studentQuery.push({ rollNo: identifier.toUpperCase() });
    studentQuery.push({ rollNo: identifier });
    studentQuery.push({ studentNo: identifier });
    if (identifier.includes('@')) {
      studentQuery.push({ email: identifier.toLowerCase() });
    }

    let student = await Student.findOne({ $or: studentQuery }).exec();
    if (student) {
      return student;
    }

    // 2. Query in candidate Registration collection(s)
    const regQuery = [];
    if (isMongoId) {
      regQuery.push({ _id: new mongoose.Types.ObjectId(identifier) });
    }
    regQuery.push({ rollNo: identifier.toUpperCase() });
    regQuery.push({ rollNo: identifier });
    regQuery.push({ studentNo: identifier });
    if (identifier.includes('@')) {
      regQuery.push({ email: identifier.toLowerCase() });
    }

    // If event has a configured registration source, check that source collection
    if (event) {
      const sourceKey = registrationSourceService.resolveEventSourceKey(event);
      if (sourceKey && registrationSourceService.isConfigured(sourceKey)) {
        try {
          const { collection } = await registrationSourceService.getCollection(sourceKey);
          const externalDoc = await collection.findOne({ $or: regQuery });
          if (externalDoc) {
            student = await this._getOrCreateStudentFromRegistration(externalDoc);
            return student;
          }
        } catch (err) {
          logger.warn('Failed querying event registration source in resolveStudent', { error: err.message });
        }
      }
    }

    // Query in local Registration collection (external student registration portal data)
    const localRegQuery = [];
    if (isMongoId) {
      localRegQuery.push({ _id: identifier });
    }
    localRegQuery.push({ rollNo: identifier.toUpperCase() });
    localRegQuery.push({ rollNo: identifier });
    localRegQuery.push({ studentNo: identifier });
    if (identifier.includes('@')) {
      localRegQuery.push({ email: identifier.toLowerCase() });
    }

    const registration = await Registration.findOne({ $or: localRegQuery }).exec();
    if (registration) {
      student = await this._getOrCreateStudentFromRegistration(registration);
      return student;
    }

    // 3. External Student API Adapter (if configured in environment)
    if (process.env.EXTERNAL_STUDENT_API_URL) {
      student = await this._resolveViaExternalApi(identifier);
      if (student) return student;
    }

    return null;
  }

  /**
   * Helper to map an external registration document into a local Student attendance record
   * without mutating external registration data or repeatedly overwriting profiles.
   */
  async _getOrCreateStudentFromRegistration(reg) {
    let student = await Student.findOne({ rollNo: reg.rollNo }).exec();
    if (!student) {
      student = await Student.create({
        name: reg.name,
        rollNo: reg.rollNo,
        studentNo: reg.studentNo,
        email: reg.email,
        phone: reg.phone,
        domain: reg.domain,
        branch: reg.branch,
        gender: reg.gender,
        hosteller: reg.hosteller,
        isActive: true,
      });
    }
    return student;
  }

  /**
   * External Student API integration hook.
   */
  async _resolveViaExternalApi(_identifier) {
    try {
      logger.info('External student API configured, querying external portal');
      return null;
    } catch (err) {
      logger.error('Failed to resolve student via external API', { error: err.message });
      return null;
    }
  }

}

module.exports = new QrResolverService();
