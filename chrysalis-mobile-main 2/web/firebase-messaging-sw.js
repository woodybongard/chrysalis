importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyB_9nKSGNpzsZwH2lEXPRr0XHlvH2xe9mI",
  authDomain: "woody-56b3f.firebaseapp.com",
  projectId: "woody-56b3f",
  storageBucket: "woody-56b3f.firebasestorage.app",
  messagingSenderId: "219263940122",
  appId: "1:219263940122:web:8ce8ea975d091f424e03a3",
  measurementId: "G-FWE453QEXB"
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification.title || 'New Message';
  const notificationOptions = {
    body: payload.notification.body || 'You have a new message',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});