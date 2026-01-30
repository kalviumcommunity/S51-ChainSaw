const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * Send push notification when a new notification document is created
 * Triggers on: notifications/{notificationId}
 */
exports.sendPushNotification = onDocumentCreated('notifications/{notificationId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log('No data associated with the event');
    return null;
  }

  const notification = snapshot.data();
  const notificationId = event.params.notificationId;

  console.log('New notification created:', notificationId);
  console.log('Notification data:', JSON.stringify(notification));

  const userId = notification.userId;
  if (!userId) {
    console.log('No userId in notification, skipping push');
    return null;
  }

  try {
    // Get user's FCM token from Firestore
    const userDoc = await db.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      console.log('User document not found:', userId);
      return null;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      console.log('No FCM token for user:', userId);
      return null;
    }

    // Prepare notification payload
    // FCM data values must be strings only
    const dataPayload = {
      notificationId: notificationId,
      type: notification.type || 'system_alert',
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    };

    // Add any extra data as stringified JSON if present
    if (notification.data) {
      dataPayload.extraData = JSON.stringify(notification.data);
    }

    const message = {
      token: fcmToken,
      notification: {
        title: notification.title || 'GateKeeper',
        body: notification.body || 'You have a new notification',
      },
      data: dataPayload,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'gatekeeper_notifications',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
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

    // Send the push notification
    const response = await messaging.send(message);
    console.log('Push notification sent successfully:', response);

    return response;
  } catch (error) {
    console.error('Error sending push notification:', error);

    // If token is invalid, remove it from user document
    if (error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered') {
      console.log('Invalid token, removing from user document');
      const { FieldValue } = require('firebase-admin/firestore');
      await db.collection('users').doc(userId).update({
        fcmToken: FieldValue.delete(),
      });
    }

    return null;
  }
});

/**
 * Send push notification to all residents of a flat when a visitor arrives
 * This is triggered when a visitor document with status 'pending' is created
 */
exports.notifyResidentsOnVisitorArrival = onDocumentCreated('visitors/{visitorId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log('No data associated with the event');
    return null;
  }

  const visitor = snapshot.data();
  const visitorId = event.params.visitorId;

  // Only notify for pending visitors
  if (visitor.status !== 'pending') {
    return null;
  }

  console.log('New visitor arrived:', visitorId);

  const flatNumber = visitor.flatNumber;
  if (!flatNumber) {
    console.log('No flat number for visitor');
    return null;
  }

  try {
    // Get the flat document to find resident IDs
    const flatsSnapshot = await db.collection('flats')
      .where('flatNumber', '==', flatNumber)
      .limit(1)
      .get();

    if (flatsSnapshot.empty) {
      console.log('Flat not found:', flatNumber);
      return null;
    }

    const flatDoc = flatsSnapshot.docs[0];
    const flatData = flatDoc.data();
    const residentIds = flatData.residentIds || [];

    if (residentIds.length === 0) {
      console.log('No residents in flat:', flatNumber);
      return null;
    }

    // Get FCM tokens for all residents
    const tokens = [];
    for (const residentId of residentIds) {
      const userDoc = await db.collection('users').doc(residentId).get();
      if (userDoc.exists) {
        const fcmToken = userDoc.data().fcmToken;
        if (fcmToken) {
          tokens.push(fcmToken);
        }
      }
    }

    if (tokens.length === 0) {
      console.log('No FCM tokens for residents');
      return null;
    }

    // Prepare notification
    const message = {
      notification: {
        title: 'New Visitor',
        body: `${visitor.name} is waiting at the gate`,
      },
      data: {
        visitorId: visitorId,
        visitorName: visitor.name,
        flatNumber: flatNumber,
        type: 'visitor_arrived',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'gatekeeper_notifications',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    // Send to all resident tokens
    const response = await messaging.sendEachForMulticast({
      tokens: tokens,
      ...message,
    });

    console.log('Sent to', response.successCount, 'devices,',
                response.failureCount, 'failed');

    return response;
  } catch (error) {
    console.error('Error notifying residents:', error);
    return null;
  }
});

/**
 * Notify guard when visitor is approved or denied
 */
exports.notifyGuardOnVisitorStatusChange = onDocumentUpdated('visitors/{visitorId}', async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const visitorId = event.params.visitorId;

  // Only trigger if status changed from 'pending'
  if (beforeData.status !== 'pending') {
    return null;
  }

  // Only trigger for approved or denied
  if (afterData.status !== 'approved' && afterData.status !== 'denied') {
    return null;
  }

  console.log('Visitor status changed:', visitorId, beforeData.status, '->', afterData.status);

  const guardId = afterData.guardId;
  if (!guardId) {
    console.log('No guard ID for visitor');
    return null;
  }

  try {
    // Get guard's FCM token
    const guardDoc = await db.collection('users').doc(guardId).get();

    if (!guardDoc.exists) {
      console.log('Guard not found:', guardId);
      return null;
    }

    const fcmToken = guardDoc.data().fcmToken;
    if (!fcmToken) {
      console.log('No FCM token for guard');
      return null;
    }

    // Prepare notification based on status
    const isApproved = afterData.status === 'approved';
    const message = {
      token: fcmToken,
      notification: {
        title: isApproved ? 'Visitor Approved' : 'Visitor Denied',
        body: `${afterData.name} was ${isApproved ? 'approved' : 'denied'} by Flat ${afterData.flatNumber}`,
      },
      data: {
        visitorId: visitorId,
        visitorName: afterData.name,
        flatNumber: afterData.flatNumber,
        status: afterData.status,
        type: isApproved ? 'visitor_approved' : 'visitor_denied',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'gatekeeper_notifications',
        },
      },
    };

    const response = await messaging.send(message);
    console.log('Push sent to guard:', response);

    return response;
  } catch (error) {
    console.error('Error notifying guard:', error);
    return null;
  }
});
