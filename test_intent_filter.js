const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./naijasingles-74a75-firebase-adminsdk-new.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://naijasingles-74a75-default-rtdb.firebaseio.com'
});

const db = admin.firestore();

async function testIntentFiltering() {
  console.log('🧪 Testing intent filtering functionality...');
  
  try {
    // Test 1: Count users by intent
    console.log('\n📊 User distribution by intent:');
    
    const intents = ['Dating', 'Friendship', 'Networking'];
    
    for (const intent of intents) {
      const snapshot = await db.collection('users')
        .where('lookingFor', '==', intent)
        .get();
      
      console.log(`   ${intent}: ${snapshot.docs.length} users`);
      
      // Show first few users for each intent
      if (snapshot.docs.length > 0) {
        console.log(`   Sample users:`);
        snapshot.docs.slice(0, 3).forEach(doc => {
          const userData = doc.data();
          console.log(`     - ${userData.name || 'Unknown'} (${doc.id})`);
        });
      }
    }
    
    // Test 2: Create some test users with different intents
    console.log('\n🧪 Creating test users with different intents...');
    
    const testUsers = [
      {
        id: 'test_dating_user',
        name: 'Dating Test User',
        lookingFor: 'Dating',
        age: 25,
        gender: 'male',
        showGender: 'female',
        location: {
          latitude: 6.5244,
          longitude: 3.3792,
          address: 'Lagos, Nigeria'
        }
      },
      {
        id: 'test_friendship_user',
        name: 'Friendship Test User',
        lookingFor: 'Friendship',
        age: 28,
        gender: 'female',
        showGender: 'everyone',
        location: {
          latitude: 6.5244,
          longitude: 3.3792,
          address: 'Lagos, Nigeria'
        }
      },
      {
        id: 'test_networking_user',
        name: 'Networking Test User',
        lookingFor: 'Networking',
        age: 30,
        gender: 'male',
        showGender: 'everyone',
        location: {
          latitude: 6.5244,
          longitude: 3.3792,
          address: 'Lagos, Nigeria'
        }
      }
    ];
    
    const batch = db.batch();
    
    for (const user of testUsers) {
      const userRef = db.collection('users').doc(user.id);
      batch.set(userRef, {
        ...user,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isBot: true, // Mark as test users
        isBlocked: false,
        maximum_distance: 100,
        age_range: { min: 18, max: 50 }
      });
      
      console.log(`   ✅ Queued test user: ${user.name} (${user.lookingFor})`);
    }
    
    await batch.commit();
    console.log('   💾 Test users created successfully');
    
    // Test 3: Query users by intent to verify filtering works
    console.log('\n🔍 Testing intent-based queries...');
    
    for (const intent of intents) {
      const snapshot = await db.collection('users')
        .where('lookingFor', '==', intent)
        .where('isBot', '==', true)
        .get();
      
      console.log(`   Query for ${intent}: ${snapshot.docs.length} test users found`);
      
      snapshot.docs.forEach(doc => {
        const userData = doc.data();
        console.log(`     - ${userData.name} (intent: ${userData.lookingFor})`);
      });
    }
    
    console.log('\n✅ Intent filtering test completed successfully!');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

// Run test
testIntentFiltering()
  .then(() => {
    console.log('🏁 Test script completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Test script failed:', error);
    process.exit(1);
  });
