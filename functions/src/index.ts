import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * NOTIF-2: Triggered on every new comment document.
 * Looks up the board owner's FCM token and sends a push notification.
 */
export const onNewComment = functions
  .region('europe-west1')
  .firestore.document('comments/{commentId}')
  .onCreate(async (snap, context) => {
    const comment = snap.data();
    const boardOwnerId: string = comment.boardOwnerId;
    const text: string = comment.text ?? '';
    const commentId: string = context.params.commentId;

    functions.logger.info('onNewComment triggered', { commentId, boardOwnerId });

    // Fetch the board owner's profile to get their FCM token
    const ownerSnap = await db.collection('users').doc(boardOwnerId).get();
    if (!ownerSnap.exists) {
      functions.logger.warn('Board owner not found', { boardOwnerId });
      return null;
    }

    const fcmToken: string | undefined = ownerSnap.data()?.fcmToken;
    if (!fcmToken) {
      functions.logger.info('No FCM token for owner', { boardOwnerId });
      return null;
    }

    // Truncate the preview to 100 chars
    const preview = text.length > 100 ? `${text.substring(0, 97)}...` : text;

    try {
      await messaging.send({
        token: fcmToken,
        notification: {
          title: 'Новое анонимное сообщение 👀',
          body: preview,
        },
        data: {
          type: 'new_comment',
          commentId,
          boardOwnerId,
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
            },
          },
        },
        android: {
          notification: {
            sound: 'default',
            channelId: 'new_comment',
          },
        },
      });
      functions.logger.info('Push sent successfully', { boardOwnerId });
    } catch (err) {
      functions.logger.error('Failed to send push', { boardOwnerId, err });
    }

    return null;
  });
