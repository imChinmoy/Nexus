const mongoose = require('mongoose');
const logger = require('../config/logger');

class RegistrationSourceService {
  constructor() {
    // Dynamic registry for custom or test sources
    this._customSources = new Map();

    // Default static mapping of canonical registration sources
    this._defaultSources = {
      'expert-seminar': { dbName: 'EXPERT-SEMINAR-REGISTRATION', collectionName: 'registrations' },
      'expert-seminar-registration': { dbName: 'EXPERT-SEMINAR-REGISTRATION', collectionName: 'registrations' },
      'reload': { dbName: 'RELOAD-REGISTRATION', collectionName: 'registrations' },
      'reload-registration': { dbName: 'RELOAD-REGISTRATION', collectionName: 'registrations' },
    };
  }

  /**
   * Programmatically register a trusted registration source (useful for tests and dynamic admin config).
   * @param {string} key - Logical source key
   * @param {{ dbName: string, collectionName?: string }} config
   */
  registerSource(key, config) {
    if (!key || typeof key !== 'string') {
      throw new Error('Registration source key must be a valid string');
    }
    const normalizedKey = key.trim().toLowerCase();
    this._customSources.set(normalizedKey, {
      dbName: config.dbName,
      collectionName: config.collectionName || 'registrations',
    });
  }

  /**
   * Clear custom sources (for test cleanup).
   */
  clearCustomSources() {
    this._customSources.clear();
  }

  /**
   * Check if a registration source key is valid and configured.
   * @param {string} key
   * @returns {boolean}
   */
  isConfigured(key) {
    if (!key || typeof key !== 'string') return false;
    const normalized = key.trim().toLowerCase();
    return this._resolveConfig(normalized) !== null;
  }

  /**
   * Internal helper to resolve source configuration from custom, env, or defaults.
   * Enforces server-side allowlists and strict identifier validation.
   * @param {string} normalizedKey
   * @returns {{ dbName: string, collectionName: string } | null}
   */
  _resolveConfig(normalizedKey) {
    // 1. Check custom / test registry first
    if (this._customSources.has(normalizedKey)) {
      return this._customSources.get(normalizedKey);
    }

    // 2. Check JSON configuration in environment variable if present
    if (process.env.REGISTRATION_SOURCES) {
      try {
        const parsed = JSON.parse(process.env.REGISTRATION_SOURCES);
        for (const [k, v] of Object.entries(parsed)) {
          if (k.toLowerCase() === normalizedKey) {
            return {
              dbName: v.dbName || v,
              collectionName: v.collectionName || 'registrations',
            };
          }
        }
      } catch (err) {
        logger.error('Failed to parse REGISTRATION_SOURCES env variable', { error: err.message });
      }
    }

    // 3. Check default static mapping
    if (this._defaultSources[normalizedKey]) {
      return this._defaultSources[normalizedKey];
    }

    // 4. Check REGISTRATION_SOURCE_ALLOWLIST (comma-separated db names)
    if (process.env.REGISTRATION_SOURCE_ALLOWLIST) {
      const allowed = process.env.REGISTRATION_SOURCE_ALLOWLIST
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .filter(Boolean);

      if (allowed.includes(normalizedKey)) {
        return {
          dbName: normalizedKey.toUpperCase(),
          collectionName: 'registrations',
        };
      }
    }

    return null;
  }

  /**
   * Resolve a registration source key to trusted DB parameters.
   * Validates safety, prevents arbitrary database access.
   *
   * @param {string} key
   * @returns {{ dbName: string, collectionName: string }}
   */
  resolveSource(key) {
    if (!key || typeof key !== 'string' || !key.trim()) {
      throw {
        status: 422,
        code: 'REGISTRATION_SOURCE_NOT_CONFIGURED',
        message: 'Registration source is not configured for this event',
      };
    }

    const trimmed = key.trim();
    // Validate characters: only alphanumeric, hyphen, underscore
    if (!/^[a-zA-Z0-9_-]+$/.test(trimmed)) {
      throw {
        status: 400,
        code: 'INVALID_REGISTRATION_SOURCE_KEY',
        message: 'Invalid characters in registration source key',
      };
    }

    const config = this._resolveConfig(trimmed.toLowerCase());
    if (!config) {
      throw {
        status: 422,
        code: 'REGISTRATION_SOURCE_NOT_CONFIGURED',
        message: `Registration source "${key}" is not registered in the system configuration`,
      };
    }

    return config;
  }

  /**
   * Get the MongoDB collection for a resolved registration source.
   * Reuses the existing Mongoose connection pool via useDb({ useCache: true }).
   * Strictly read-only operations should be used by callers.
   *
   * @param {string} key
   * @returns {Promise<{ collection: any, dbName: string, collectionName: string }>}
   */
  async getCollection(key) {
    const { dbName, collectionName } = this.resolveSource(key);

    if (mongoose.connection.readyState !== 1) {
      throw {
        status: 503,
        code: 'REGISTRATION_SOURCE_UNAVAILABLE',
        message: 'Registration database connection is currently unavailable',
      };
    }

    try {
      // Re-use connection pool without opening new TCP connections
      const targetDb = mongoose.connection.useDb(dbName, { useCache: true });

      // Verify collection existence in target database
      const collections = await targetDb.db.listCollections({ name: collectionName }).toArray();
      if (!collections || collections.length === 0) {
        throw {
          status: 404,
          code: 'REGISTRATION_COLLECTION_NOT_FOUND',
          message: `Registration collection "${collectionName}" was not found in database "${dbName}"`,
        };
      }

      const collection = targetDb.collection(collectionName);
      return { collection, dbName, collectionName };
    } catch (err) {
      if (err.code === 'REGISTRATION_COLLECTION_NOT_FOUND') {
        throw err;
      }
      logger.error('Error connecting to registration source', { dbName, error: err.message });
      throw {
        status: 503,
        code: 'REGISTRATION_SOURCE_UNAVAILABLE',
        message: `Registration database "${dbName}" is temporarily unreachable`,
      };
    }
  }
}

module.exports = new RegistrationSourceService();
