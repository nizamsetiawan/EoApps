const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendFCMNotification = functions.firestore
    .document('fcm_messages/{messageId}')
    .onCreate(async (snap, context) => {
        const message = snap.data();
        
        const payload = {
            notification: message.notification,
            data: message.data,
            token: message.token,
            android: {
                priority: 'high',
                notification: {
                    channelId: 'task_notification_channel',
                    priority: 'high',
                    defaultSound: true,
                    defaultVibrateTimings: true,
                    defaultLightSettings: true,
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                        contentAvailable: true,
                    },
                },
            },
        };
        
        try {
            await admin.messaging().send(payload);
            // Hapus pesan setelah berhasil dikirim
            await snap.ref.delete();
        } catch (error) {
            console.error('Error sending FCM:', error);
            // Jika token tidak valid, hapus pesan
            if (error.code === 'messaging/invalid-registration-token' ||
                error.code === 'messaging/registration-token-not-registered') {
                await snap.ref.delete();
            }
        }
    }); 