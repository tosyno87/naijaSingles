const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Service account file name - UPDATED to use the new key
const serviceAccountFile = 'naijasingles-74a75-firebase-adminsdk-new.json';

// Initialize Firebase Admin SDK
try {
  // Try to load the service account file
  const serviceAccount = require('./' + serviceAccountFile);
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  
  console.log('✅ Initialized Firebase Admin SDK with service account');
} catch (error) {
  console.error('❌ Error initializing Firebase Admin SDK:', error.message);
  console.log(`\nPlease make sure the service account key file "${serviceAccountFile}" is in this directory`);
  process.exit(1);
}

const db = admin.firestore();

// Read the seed data file
const seedData = JSON.parse(fs.readFileSync(path.join(__dirname, 'firestore_seed_afropeep.json'), 'utf8'));

async function importData() {
  try {
    // Process users collection
    if (seedData.users) {
      console.log('Importing users...');
      for (const [docId, data] of Object.entries(seedData.users)) {
        await db.collection('users').doc(docId).set(data);
        console.log(`  - Added user: ${docId}`);
      }
    }
    
    // Process chatThreads collection
    if (seedData.chatThreads) {
      console.log('Importing chat threads...');
      for (const [docId, data] of Object.entries(seedData.chatThreads)) {
        await db.collection('chatThreads').doc(docId).set(data);
        console.log(`  - Added chat thread: ${docId}`);
      }
    }
    
    // Process subcollections (like messages in chatThreads)
    for (const key in seedData) {
      if (key.includes('/')) {
        console.log(`Importing ${key}...`);
        const parts = key.split('/');
        const collPath = parts[0];
        const docId = parts[1];
        const subCollName = parts[2];
        
        for (const [subDocId, data] of Object.entries(seedData[key])) {
          await db.collection(collPath).doc(docId).collection(subCollName).doc(subDocId).set(data);
          console.log(`  - Added ${subCollName} document: ${subDocId}`);
        }
      }
    }
    
    console.log('✅ Seed data imported successfully!');
  } catch (error) {
    console.error('❌ Error importing seed data:', error);
  }
}

importData();
