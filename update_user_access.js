const admin = require('firebase-admin');
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
const yourUserId = '412UYOeWB4QyIvM9DzCP4PG0Qs12';
const threadId = '9b495eb4-297d-4dcc-a0f7-0c7234060ebf';

async function updateAccess() {
  try {
    // 1. Create a user document for your user ID if it doesn't exist
    console.log(`Creating user document for ID: ${yourUserId}`);
    await db.collection('users').doc(yourUserId).set({
      name: 'Current User',
      photoUrl: 'https://example.com/default.jpg',
      // Add other required fields based on your app's data model
      gender: 'Male',
      age: 25,
      bio: 'This is a test user created to access the imported chat data.',
      lastActive: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true }); // Using merge to preserve any existing data
    
    // 2. Add your user ID to the chat thread's userIds array
    console.log(`Adding user to chat thread: ${threadId}`);
    await db.collection('chatThreads').doc(threadId).update({
      userIds: admin.firestore.FieldValue.arrayUnion(yourUserId),
      users: admin.firestore.FieldValue.arrayUnion({
        id: yourUserId,
        name: 'Current User',
        photoUrl: 'https://example.com/default.jpg'
      })
    });
    
    console.log('✅ Successfully updated Firestore data!');
    console.log(`Your user ID (${yourUserId}) now has access to the chat thread.`);
    console.log('You should now be able to view the messages in your app.');
  } catch (error) {
    console.error('❌ Error updating Firestore data:', error);
  }
}

updateAccess();
