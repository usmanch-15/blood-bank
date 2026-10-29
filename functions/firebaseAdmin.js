// Centralize the modular Admin SDK, including emulator app lifecycle.
const { initializeApp, getApps, getApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, Timestamp, FieldValue, FieldPath, Filter } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { getStorage } = require('firebase-admin/storage');
const { getMessaging } = require('firebase-admin/messaging');

module.exports = {
  initializeApp,
  get apps() { return getApps(); },
  app: () => ({ delete: () => deleteApp(getApp()) }),
  firestore: Object.assign(getFirestore, { Timestamp, FieldValue, FieldPath, Filter }),
  auth: getAuth,
  storage: getStorage,
  messaging: getMessaging,
};
