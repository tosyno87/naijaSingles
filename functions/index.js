const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// 🎉 MATCH NOTIFICATIONS - Triggered when match document is created
exports.onMatchCreated = functions.firestore
  .document('matches/{matchId}')
  .onCreate(async (snap, context) => {
    const matchData = snap.data();
    const matchId = context.params.matchId;
    
    console.log(`🎉 New match created: ${matchId}`, matchData);
    
    try {
      const users = matchData.users || [];
      if (users.length !== 2) {
        console.log('Invalid match - not exactly 2 users');
        return;
      }
      
      // Get both users' data in parallel
      const [userADoc, userBDoc] = await Promise.all([
        admin.firestore().collection('users').doc(users[0]).get(),
        admin.firestore().collection('users').doc(users[1]).get()
      ]);
      
      if (!userADoc.exists || !userBDoc.exists) {
        console.log('One or both users not found');
        return;
      }
      
      const userA = { id: users[0], ...userADoc.data() };
      const userB = { id: users[1], ...userBDoc.data() };
      
      // Send match notifications to both users
      await Promise.all([
        sendMatchNotification(userA, userB),
        sendMatchNotification(userB, userA)
      ]);
      
      console.log('✅ Match notifications sent successfully');
      
    } catch (error) {
      console.error('❌ Error sending match notification:', error);
    }
  });

// 💬 MESSAGE NOTIFICATIONS - Triggered when message is created
exports.onMessageSent = functions.firestore
  .document('chatThreads/{threadId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const threadId = context.params.threadId;
    const messageId = context.params.messageId;
    
    console.log(`💬 New message in thread ${threadId}:`, messageData);
    
    try {
      // Get chat thread to find recipient
      const threadDoc = await admin.firestore()
        .collection('chatThreads').doc(threadId).get();
      
      if (!threadDoc.exists) {
        console.log('Chat thread not found');
        return;
      }
      
      const threadData = threadDoc.data();
      const participants = threadData.userIds || [];
      const senderId = messageData.senderId;
      const recipientId = participants.find(id => id !== senderId);
      
      if (!recipientId) {
        console.log('Recipient not found in thread');
        return;
      }
      
      // Get sender and recipient data
      const [senderDoc, recipientDoc] = await Promise.all([
        admin.firestore().collection('users').doc(senderId).get(),
        admin.firestore().collection('users').doc(recipientId).get()
      ]);
      
      if (!senderDoc.exists || !recipientDoc.exists) {
        console.log('Sender or recipient not found');
        return;
      }
      
      const sender = { id: senderId, ...senderDoc.data() };
      const recipient = { id: recipientId, ...recipientDoc.data() };
      
      await sendMessageNotification(recipient, sender, messageData, threadId);
      
      console.log('✅ Message notification sent successfully');
      
    } catch (error) {
      console.error('❌ Error sending message notification:', error);
    }
  });

// 💖 LIKE NOTIFICATIONS - Triggered when someone likes a profile
exports.onLikeCreated = functions.firestore
  .document('users/{userId}/LikedBy/{likeId}')
  .onCreate(async (snap, context) => {
    const likeData = snap.data();
    const likedUserId = context.params.userId;
    const likeId = context.params.likeId;
    const likerId = likeData.LikedBy;
    
    console.log(`💖 New like: ${likerId} liked ${likedUserId}`);
    
    try {
      // Get both users' data
      const [likedUserDoc, likerDoc] = await Promise.all([
        admin.firestore().collection('users').doc(likedUserId).get(),
        admin.firestore().collection('users').doc(likerId).get()
      ]);
      
      if (!likedUserDoc.exists || !likerDoc.exists) {
        console.log('Liked user or liker not found');
        return;
      }
      
      const likedUser = { id: likedUserId, ...likedUserDoc.data() };
      const liker = { id: likerId, ...likerDoc.data() };
      
      await sendLikeNotification(likedUser, liker);
      
      console.log('✅ Like notification sent successfully');
      
    } catch (error) {
      console.error('❌ Error sending like notification:', error);
    }
  });

// 🔥 Helper function to send match notification
async function sendMatchNotification(user, matchedUser) {
  const pushToken = user.pushToken;
  if (!pushToken) {
    console.log(`No push token for user ${user.id}`);
    return;
  }
  
  // Check notification preferences
  const notificationPrefs = user.notificationPreferences || {};
  if (notificationPrefs.matchNotifications === false) {
    console.log(`Match notifications disabled for user ${user.id}`);
    return;
  }
  
  const message = {
    notification: {
      title: '🎉 It\'s a Match!',
      body: `You and ${matchedUser.name || 'someone special'} liked each other!`,
    },
    data: {
      type: 'match',
      userId: user.id,
      matchedUserId: matchedUser.id,
      matchedUserName: matchedUser.name || '',
      matchedUserPhoto: getFirstPhoto(matchedUser),
      action: 'open_chat',
    },
    token: pushToken,
    android: {
      notification: {
        icon: 'ic_notification',
        color: '#FF3A5A',
        sound: 'match_sound',
        channelId: 'matches',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'match_sound.caf',
          badge: 1,
        },
      },
    },
  };
  
  try {
    await admin.messaging().send(message);
    console.log(`✅ Match notification sent to ${user.id}`);
    
    // Store in-app notification
    await storeInAppNotification(user.id, {
      type: 'match',
      title: '🎉 It\'s a Match!',
      message: `You and ${matchedUser.name || 'someone special'} liked each other!`,
      avatarUrl: getFirstPhoto(matchedUser),
      actionId: matchedUser.id,
    });
    
  } catch (error) {
    console.error(`❌ Error sending match notification to ${user.id}:`, error);
  }
}

// 💬 Helper function to send message notification
async function sendMessageNotification(recipient, sender, messageData, threadId) {
  const pushToken = recipient.pushToken;
  if (!pushToken) {
    console.log(`No push token for user ${recipient.id}`);
    return;
  }
  
  // Check notification preferences
  const notificationPrefs = recipient.notificationPreferences || {};
  if (notificationPrefs.messageNotifications === false) {
    console.log(`Message notifications disabled for user ${recipient.id}`);
    return;
  }
  
  // Truncate long messages
  const messageText = messageData.text || 'Sent you a message';
  const truncatedMessage = messageText.length > 100 
    ? messageText.substring(0, 100) + '...' 
    : messageText;
  
  const message = {
    notification: {
      title: sender.name || 'New Message',
      body: truncatedMessage,
    },
    data: {
      type: 'message',
      senderId: sender.id,
      senderName: sender.name || '',
      senderPhoto: getFirstPhoto(sender),
      messageText: messageText,
      threadId: threadId,
      action: 'open_chat',
    },
    token: pushToken,
    android: {
      notification: {
        icon: 'ic_notification',
        color: '#008037',
        sound: 'message_sound',
        channelId: 'messages',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'message_sound.caf',
          badge: 1,
        },
      },
    },
  };
  
  try {
    await admin.messaging().send(message);
    console.log(`✅ Message notification sent to ${recipient.id}`);
    
    // Store in-app notification
    await storeInAppNotification(recipient.id, {
      type: 'message',
      title: `New message from ${sender.name || 'someone'}`,
      message: truncatedMessage,
      avatarUrl: getFirstPhoto(sender),
      actionId: threadId,
    });
    
  } catch (error) {
    console.error(`❌ Error sending message notification to ${recipient.id}:`, error);
  }
}

// 💖 Helper function to send like notification
async function sendLikeNotification(likedUser, liker) {
  const pushToken = likedUser.pushToken;
  if (!pushToken) {
    console.log(`No push token for user ${likedUser.id}`);
    return;
  }
  
  // Check notification preferences
  const notificationPrefs = likedUser.notificationPreferences || {};
  if (notificationPrefs.likeNotifications === false) {
    console.log(`Like notifications disabled for user ${likedUser.id}`);
    return;
  }
  
  const message = {
    notification: {
      title: '💖 Someone likes you!',
      body: `${liker.name || 'Someone'} liked your profile`,
    },
    data: {
      type: 'like',
      likerId: liker.id,
      likerName: liker.name || '',
      likerPhoto: getFirstPhoto(liker),
      action: 'open_profile',
    },
    token: pushToken,
    android: {
      notification: {
        icon: 'ic_notification',
        color: '#FF69B4',
        sound: 'like_sound',
        channelId: 'likes',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'like_sound.caf',
          badge: 1,
        },
      },
    },
  };
  
  try {
    await admin.messaging().send(message);
    console.log(`✅ Like notification sent to ${likedUser.id}`);
    
    // Store in-app notification
    await storeInAppNotification(likedUser.id, {
      type: 'like',
      title: '💖 Someone likes you!',
      message: `${liker.name || 'Someone'} liked your profile`,
      avatarUrl: getFirstPhoto(liker),
      actionId: liker.id,
    });
    
  } catch (error) {
    console.error(`❌ Error sending like notification to ${likedUser.id}:`, error);
  }
}

// 📱 Helper function to store in-app notification
async function storeInAppNotification(userId, notificationData) {
  try {
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .add({
        ...notificationData,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        id: admin.firestore().collection('_').doc().id, // Generate unique ID
      });
      
    console.log(`✅ In-app notification stored for user ${userId}`);
  } catch (error) {
    console.error(`❌ Error storing in-app notification for ${userId}:`, error);
  }
}

// 🖼️ Helper function to get first photo URL
function getFirstPhoto(user) {
  if (user.imageUrl && Array.isArray(user.imageUrl) && user.imageUrl.length > 0) {
    return user.imageUrl[0];
  }
  if (user.Pictures && Array.isArray(user.Pictures) && user.Pictures.length > 0) {
    return user.Pictures[0];
  }
  if (user.photos && Array.isArray(user.photos) && user.photos.length > 0) {
    return user.photos[0];
  }
  if (user.photoUrl) {
    return user.photoUrl;
  }
  return '';
}
