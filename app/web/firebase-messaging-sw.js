importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDdmn-CeGIjjODMH367TLOCohxV4z2LTe4',
  appId: '1:260654198138:web:70210dee1ee17f0f527ac3',
  messagingSenderId: '260654198138',
  projectId: 'pedro-f65a6',
  authDomain: 'pedro-f65a6.firebaseapp.com',
  storageBucket: 'pedro-f65a6.firebasestorage.app'
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title || 'Pedro';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/favicon.png',
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
