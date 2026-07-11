const functions = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ═══════════════════════════════════════════════════════════════
// FUNCTION 1: Notify Admin when trader submits requirement
// ═══════════════════════════════════════════════════════════════
exports.onRequirementCreated = functions.firestore
  .onDocumentCreated('requirements/{requirementId}', async (event) => {
    const requirement = event.data.data();
    const requirementId = event.params.requirementId;

    try {
      // Get all admin users
      const adminSnapshot = await db
        .collection('users')
        .where('role', '==', 'admin')
        .get();

      if (adminSnapshot.empty) return;

      const notifications = [];
      const fcmTokens = [];

      for (const adminDoc of adminSnapshot.docs) {
        const adminData = adminDoc.data();

        // Add notification to Firestore
        notifications.push(
          db.collection('notifications')
            .doc(adminDoc.id)
            .collection('items')
            .add({
              title: '🔔 New Requirement!',
              message: `${requirement.traderName} submitted requirement for ${requirement.productName} at ₹${requirement.priceDetails?.customerDemandedPrice || 0}`,
              type: 'newRequirement',
              referenceId: requirementId,
              read: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            })
        );

        // Collect FCM tokens
        if (adminData.fcmToken) {
          fcmTokens.push(adminData.fcmToken);
        }
      }

      await Promise.all(notifications);

      // Send push notifications
      if (fcmTokens.length > 0) {
        const message = {
          notification: {
            title: '🔔 New Requirement!',
            body: `${requirement.traderName}: ${requirement.productName} - ₹${requirement.priceDetails?.customerDemandedPrice || 0}`,
          },
          data: {
            type: 'newRequirement',
            requirementId: requirementId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          tokens: fcmTokens,
          android: {
            notification: {
              channelId: 'price_catalog_channel',
              priority: 'high',
              sound: 'default',
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        };

        await messaging.sendEachForMulticast(message);
      }

      functions.logger.info(
        `Requirement ${requirementId} notifications sent to ${adminSnapshot.size} admins`
      );
    } catch (error) {
      functions.logger.error('Error in onRequirementCreated:', error);
    }
  });

// ═══════════════════════════════════════════════════════════════
// FUNCTION 2: Notify Trader when requirement is updated
// ═══════════════════════════════════════════════════════════════
exports.onRequirementUpdated = functions.firestore
  .onDocumentUpdated('requirements/{requirementId}', async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const requirementId = event.params.requirementId;

    // Only proceed if status changed
    if (before.status === after.status) return;

    try {
      const traderId = after.traderId;
      const productName = after.productName;
      const newStatus = after.status;

      // Get trader FCM token
      const traderDoc = await db.collection('users').doc(traderId).get();
      if (!traderDoc.exists) return;

      const traderData = traderDoc.data();

      // Determine notification content based on status
      let title, body, notifType;

      switch (newStatus) {
        case 'approved':
          title = '✅ Requirement Approved!';
          body = `Your requirement for ${productName} has been approved.`;
          notifType = 'requirementApproved';
          break;
        case 'rejected':
          title = '❌ Requirement Rejected';
          body = `Your requirement for ${productName} was not approved. Reason: ${after.rejectionReason || 'See details'}`;
          notifType = 'requirementRejected';
          break;
        case 'counterOffer':
          title = '🔄 Counter Offer Received';
          body = `Admin suggested ₹${after.counterPrice} for ${productName}. Tap to respond.`;
          notifType = 'counterOffer';
          break;
        default:
          return;
      }

      // Add to Firestore notifications
      await db
        .collection('notifications')
        .doc(traderId)
        .collection('items')
        .add({
          title,
          message: body,
          type: notifType,
          referenceId: requirementId,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      // Send push notification
      if (traderData.fcmToken) {
        await messaging.send({
          notification: { title, body },
          data: {
            type: notifType,
            requirementId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          token: traderData.fcmToken,
          android: {
            notification: {
              channelId: 'price_catalog_channel',
              priority: 'high',
              sound: 'default',
            },
          },
          apns: {
            payload: {
              aps: { sound: 'default', badge: 1 },
            },
          },
        });
      }

      functions.logger.info(
        `Requirement ${requirementId} update notification sent to trader ${traderId}`
      );
    } catch (error) {
      functions.logger.error('Error in onRequirementUpdated:', error);
    }
  });

// ═══════════════════════════════════════════════════════════════
// FUNCTION 3: Notify Traders when price updated
// ═══════════════════════════════════════════════════════════════
exports.onProductPriceUpdated = functions.firestore
  .onDocumentUpdated('products/{productId}', async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    const oldPrice = before.currentPrice?.sellingPrice;
    const newPrice = after.currentPrice?.sellingPrice;

    // Only notify if selling price changed
    if (oldPrice === newPrice) return;

    try {
      // Get all approved traders
      const tradersSnapshot = await db
        .collection('users')
        .where('role', '==', 'trader')
        .where('traderStatus', '==', 'approved')
        .get();

      if (tradersSnapshot.empty) return;

      const priceChange = newPrice - oldPrice;
      const isIncrease = priceChange > 0;
      const emoji = isIncrease ? '📈' : '📉';

      const fcmTokens = [];
      const notifications = [];

      for (const traderDoc of tradersSnapshot.docs) {
        const traderData = traderDoc.data();

        // Add Firestore notification
        notifications.push(
          db.collection('notifications')
            .doc(traderDoc.id)
            .collection('items')
            .add({
              title: `${emoji} Price Updated: ${after.name}`,
              message: `Price ${isIncrease ? 'increased' : 'decreased'} from ₹${oldPrice} to ₹${newPrice} per ${after.unit}`,
              type: 'priceUpdated',
              referenceId: event.params.productId,
              read: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            })
        );

        if (traderData.fcmToken) {
          fcmTokens.push(traderData.fcmToken);
        }
      }

      await Promise.all(notifications);

      // Batch send FCM (max 500 per batch)
      if (fcmTokens.length > 0) {
        const chunks = chunkArray(fcmTokens, 500);
        for (const chunk of chunks) {
          await messaging.sendEachForMulticast({
            notification: {
              title: `${emoji} Price Update: ${after.name}`,
              body: `₹${oldPrice} → ₹${newPrice} per ${after.unit}`,
            },
            data: {
              type: 'priceUpdated',
              productId: event.params.productId,
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            tokens: chunk,
            android: {
              notification: {
                channelId: 'price_catalog_channel',
                priority: 'default',
              },
            },
          });
        }
      }

      functions.logger.info(
        `Price update notification sent for product ${event.params.productId}`
      );
    } catch (error) {
      functions.logger.error('Error in onProductPriceUpdated:', error);
    }
  });

// ═══════════════════════════════════════════════════════════════
// FUNCTION 4: Notify Admin when new trader registers
// ═══════════════════════════════════════════════════════════════
exports.onNewTraderRegistered = functions.firestore
  .onDocumentCreated('users/{userId}', async (event) => {
    const userData = event.data.data();

    // Only for traders
    if (userData.role !== 'trader') return;

    try {
      // Get all admins
      const adminSnapshot = await db
        .collection('users')
        .where('role', '==', 'admin')
        .get();

      const notifications = [];
      const fcmTokens = [];

      for (const adminDoc of adminSnapshot.docs) {
        const adminData = adminDoc.data();

        notifications.push(
          db.collection('notifications')
            .doc(adminDoc.id)
            .collection('items')
            .add({
              title: '👤 New Trader Registration',
              message: `${userData.name} (${userData.businessName}) wants to join. Please review.`,
              type: 'newTrader',
              referenceId: event.params.userId,
              read: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            })
        );

        if (adminData.fcmToken) {
          fcmTokens.push(adminData.fcmToken);
        }
      }

      await Promise.all(notifications);

      if (fcmTokens.length > 0) {
        await messaging.sendEachForMulticast({
          notification: {
            title: '👤 New Trader Registration',
            body: `${userData.name} from ${userData.businessName} wants to join.`,
          },
          data: {
            type: 'newTrader',
            traderId: event.params.userId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          tokens: fcmTokens,
        });
      }
    } catch (error) {
      functions.logger.error('Error in onNewTraderRegistered:', error);
    }
  });

// ═══════════════════════════════════════════════════════════════
// FUNCTION 5: Update FCM Token (HTTP callable)
// ═══════════════════════════════════════════════════════════════
exports.updateFcmToken = functions.https.onCall(
  async (request) => {
    const { token } = request.data;
    const uid = request.auth?.uid;

    if (!uid) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    if (!token) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'FCM token is required'
      );
    }

    try {
      await db.collection('users').doc(uid).update({
        fcmToken: token,
        lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

// ═══════════════════════════════════════════════════════════════
// FUNCTION 6: Get Dashboard Stats (HTTP callable)
// ═══════════════════════════════════════════════════════════════
exports.getDashboardStats = functions.https.onCall(
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    try {
      const [
        productsSnap,
        tradersSnap,
        pendingReqSnap,
        approvedReqSnap,
      ] = await Promise.all([
        db.collection('products').where('isActive', '==', true).count().get(),
        db.collection('users').where('role', '==', 'trader').where('traderStatus', '==', 'approved').count().get(),
        db.collection('requirements').where('status', '==', 'pending').count().get(),
        db.collection('requirements').where('status', '==', 'approved').count().get(),
      ]);

      return {
        totalProducts: productsSnap.data().count,
        totalTraders: tradersSnap.data().count,
        pendingRequirements: pendingReqSnap.data().count,
        approvedDeals: approvedReqSnap.data().count,
      };
    } catch (error) {
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

// ─── HELPER ──────────────────────────────────────────────────
function chunkArray(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}