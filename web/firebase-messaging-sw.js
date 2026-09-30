// web/firebase-messaging-sw.js
// Shows push notifications on the WEB app when the tab is in the background
// or closed. Fill in the same values as lib/firebase_options.dart (web).

importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyA2gnFWXfFn_x135H86Hzyt1oNnkd6m9Xc',
  authDomain: 'airotrack-b67c4.firebaseapp.com',
  projectId: 'airotrack-b67c4',
  storageBucket: 'airotrack-b67c4.firebasestorage.app',
  messagingSenderId: '521325798783',
  appId: '1:521325798783:web:airotrack-b67c4',
});

const messaging = firebase.messaging();

// Data-only messages: build the notification here.
// (Messages that already have a "notification" block are shown
//  automatically by Firebase.)
messaging.onBackgroundMessage((payload) => {
  if (payload.notification) return;
  const data = payload.data || {};
  self.registration.showNotification(data.title || 'Airotrack', {
    body: data.body || '',
    icon: '/icons/Icon-192.png',
    data: data,
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow('/'));
});
