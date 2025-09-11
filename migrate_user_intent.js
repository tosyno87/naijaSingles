const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./naijasingles-74a75-firebase-adminsdk-new.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://naijasingles-74a75-default-rtdb.firebaseio.com'
});

const db = admin.firestore();

async function migrateUserIntents() {
  console.log('🚀 Starting user intent migration...');
  
  try {
    // Get all users
    const usersSnapshot = await db.collection('users').get();
    console.log(`📊 Found ${usersSnapshot.docs.length} users to migrate`);
    
    const batch = db.batch();
    let updateCount = 0;
    
    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      
      // Skip if user already has lookingFor field
      if (userData.lookingFor) {
        console.log(`⏭️  User ${doc.id} already has lookingFor: ${userData.lookingFor}`);
        continue;
      }
      
      // Default to 'Dating' for existing users
      const defaultIntent = 'Dating';
      
      // You could add logic here to infer intent from other fields
      // For example, if user has certain keywords in bio, set different intent
      let inferredIntent = defaultIntent;
      
      if (userData.bio || (userData.editInfo && userData.editInfo.userBio)) {
        const bio = (userData.bio || userData.editInfo?.userBio || '').toLowerCase();
        
        if (bio.includes('friend') || bio.includes('friendship') || bio.includes('platonic')) {
          inferredIntent = 'Friendship';
        } else if (bio.includes('network') || bio.includes('business') || bio.includes('professional')) {
          inferredIntent = 'Networking';
        }
      }
      
      // Update user document
      batch.update(doc.ref, {
        lookingFor: inferredIntent,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      updateCount++;
      console.log(`✅ Queued update for user ${doc.id} (${userData.name || 'Unknown'}) -> ${inferredIntent}`);
      
      // Commit batch every 500 operations (Firestore limit)
      if (updateCount % 500 === 0) {
        console.log(`💾 Committing batch of ${updateCount} updates...`);
        await batch.commit();
        console.log(`✅ Batch committed successfully`);
      }
    }
    
    // Commit remaining updates
    if (updateCount % 500 !== 0) {
      console.log(`💾 Committing final batch of ${updateCount % 500} updates...`);
      await batch.commit();
      console.log(`✅ Final batch committed successfully`);
    }
    
    console.log(`🎉 Migration completed! Updated ${updateCount} users with lookingFor field`);
    
    // Verify migration
    console.log('\n🔍 Verifying migration...');
    const verifySnapshot = await db.collection('users').where('lookingFor', '==', null).get();
    console.log(`📊 Users without lookingFor field: ${verifySnapshot.docs.length}`);
    
    if (verifySnapshot.docs.length === 0) {
      console.log('✅ All users now have lookingFor field!');
    } else {
      console.log('⚠️  Some users still missing lookingFor field');
    }
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
  }
}

// Run migration
migrateUserIntents()
  .then(() => {
    console.log('🏁 Migration script completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Migration script failed:', error);
    process.exit(1);
  });
