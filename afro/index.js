const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();

/**
 * Send push notification when users match
 */
exports.onMatchCreated = onDocumentCreated(
    "matches/{matchId}", async (event) => {
      const snap = event.data;
      const context = event.params;
      const matchData = snap.data();
      const {users} = matchData;

      if (!users || users.length !== 2) {
        console.log("Invalid match data:", matchData);
        return null;
      }

      try {
        // Get user data for both users
        const [user1Doc, user2Doc] = await Promise.all([
          db.collection("users").doc(users[0]).get(),
          db.collection("users").doc(users[1]).get(),
        ]);

        if (!user1Doc.exists || !user2Doc.exists) {
          console.log("One or both users not found");
          return null;
        }

        const user1Data = user1Doc.data();
        const user2Data = user2Doc.data();

        // Send notification to both users
        const notifications = [
          {
            userId: users[0],
            title: "🎉 New Match!",
            body: `You matched with ${user2Data.name || "Someone"}!`,
            data: {
              type: "match",
              matchId: context.matchId,
              otherUserId: users[1],
            },
          },
          {
            userId: users[1],
            title: "🎉 New Match!",
            body: `You matched with ${user1Data.name || "Someone"}!`,
            data: {
              type: "match",
              matchId: context.matchId,
              otherUserId: users[0],
            },
          },
        ];

        // Send notifications
        await Promise.all(notifications.map((notification) =>
          sendNotification(notification),
        ));

        console.log("Match notifications sent successfully");
        return null;
      } catch (error) {
        console.error("Error sending match notifications:", error);
        return null;
      }
    });

/**
 * Send push notification when a new message is sent
 */
exports.onMessageCreated = onDocumentCreated(
    "chatThreads/{threadId}/messages/{messageId}",
    async (event) => {
      const snap = event.data;
      const context = event.params;
      const messageData = snap.data();
      const {senderId, text} = messageData;

      if (!senderId || !text) {
        console.log("Invalid message data:", messageData);
        return null;
      }

      try {
        // Get chat thread data
        const threadDoc = await db.collection("chatThreads")
            .doc(context.threadId).get();

        if (!threadDoc.exists) {
          console.log("Chat thread not found");
          return null;
        }

        const threadData = threadDoc.data();
        const {userIds} = threadData;

        if (!userIds || userIds.length !== 2) {
          console.log("Invalid thread data:", threadData);
          return null;
        }

        // Find the recipient (not the sender)
        const recipientId = userIds.find((id) => id !== senderId);

        if (!recipientId) {
          console.log("Recipient not found");
          return null;
        }

        // Get sender data
        const senderDoc = await db.collection("users").doc(senderId).get();

        if (!senderDoc.exists) {
          console.log("Sender not found");
          return null;
        }

        const senderData = senderDoc.data();

        // Send notification to recipient
        await sendNotification({
          userId: recipientId,
          title: senderData.name || "New Message",
          body: text.length > 50 ? text.substring(0, 50) + "..." : text,
          data: {
            type: "message",
            threadId: context.threadId,
            senderId: senderId,
          },
        });

        console.log("Message notification sent successfully");
        return null;
      } catch (error) {
        console.error("Error sending message notification:", error);
        return null;
      }
    });

/**
 * Send push notification when someone likes you
 */
exports.onLikeCreated = onDocumentCreated("likes/{likeId}", async (event) => {
  const snap = event.data;
  const likeData = snap.data();
  const {from, to} = likeData;

  if (!from || !to) {
    console.log("Invalid like data:", likeData);
    return null;
  }

  try {
    // Get liker data
    const likerDoc = await db.collection("users").doc(from).get();

    if (!likerDoc.exists) {
      console.log("Liker not found");
      return null;
    }

    const likerData = likerDoc.data();

    // Send notification to the liked user
    await sendNotification({
      userId: to,
      title: "💖 Someone likes you!",
      body: `${likerData.name || "Someone"} liked your profile`,
      data: {
        type: "like",
        likerId: from,
      },
    });

    console.log("Like notification sent successfully");
    return null;
  } catch (error) {
    console.error("Error sending like notification:", error);
    return null;
  }
});

/**
 * Send push notification when someone super likes you
 */
exports.onSuperLikeCreated = onDocumentCreated(
    "superLikes/{superLikeId}",
    async (event) => {
      const snap = event.data;
      const superLikeData = snap.data();
      const {fromUserId, toUserId} = superLikeData;

      if (!fromUserId || !toUserId) {
        console.log("Invalid super like data:", superLikeData);
        return null;
      }

      try {
        // Get super liker data
        const superLikerDoc = await db.collection("users")
            .doc(fromUserId).get();

        if (!superLikerDoc.exists) {
          console.log("Super liker not found");
          return null;
        }

        const superLikerData = superLikerDoc.data();

        // Send notification to the super liked user
        await sendNotification({
          userId: toUserId,
          title: "⭐ Super Like!",
          body: `${superLikerData.name || "Someone"} super liked you!`,
          data: {
            type: "superLike",
            superLikerId: fromUserId,
          },
        });

        console.log("Super like notification sent successfully");
        return null;
      } catch (error) {
        console.error("Error sending super like notification:", error);
        return null;
      }
    });

/**
 * Helper function to send push notification
 * @param {Object} notification - The notification object
 */
async function sendNotification(notification) {
  try {
    // Get user's push token
    const userDoc = await db.collection("users")
        .doc(notification.userId).get();

    if (!userDoc.exists) {
      console.log("User not found:", notification.userId);
      return;
    }

    const userData = userDoc.data();
    const pushToken = userData.pushToken;

    if (!pushToken) {
      console.log("No push token for user:", notification.userId);
      return;
    }

    // Create notification payload
    const payload = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
      token: pushToken,
    };

    // Send notification
    const response = await admin.messaging().send(payload);
    console.log("Notification sent successfully:", response);

    // Save notification to user's notifications collection
    await db.collection("users").doc(notification.userId)
        .collection("notifications").add({
          title: notification.title,
          body: notification.body,
          data: notification.data || {},
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
        });
  } catch (error) {
    console.error("Error sending notification:", error);
  }
}

/**
 * HTTP function to send test notification
 */
exports.sendTestNotification = onRequest(async (req, res) => {
  try {
    const {userId, title, body} = req.body;

    if (!userId || !title || !body) {
      res.status(400).json({error: "Missing required fields"});
      return;
    }

    await sendNotification({
      userId,
      title,
      body,
      data: {type: "test"},
    });

    res.json({success: true, message: "Test notification sent"});
  } catch (error) {
    console.error("Error in test notification:", error);
    res.status(500).json({error: "Failed to send notification"});
  }
});
