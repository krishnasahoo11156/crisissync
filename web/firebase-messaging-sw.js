importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAsNqvAVScKN8UrUFcv2NF1TLUxbkvFKG8",
  authDomain: "crisissync-11156.firebaseapp.com",
  projectId: "crisissync-11156",
  storageBucket: "crisissync-11156.firebasestorage.app",
  messagingSenderId: "63983001833",
  appId: "1:63983001833:web:1b9a0579a520a766cfd078",
  measurementId: "G-DX02QTVSJQ"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  const notificationTitle = payload.notification?.title || "CrisisSync Alert";
  const notificationOptions = {
    body: payload.notification?.body || "New incident requires your attention",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    tag: payload.data?.incidentId || "crisis-alert",
    requireInteraction: true,
  };
  return self.registration.showNotification(notificationTitle, notificationOptions);
});
