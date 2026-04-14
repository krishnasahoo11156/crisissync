import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration for CrisisSync web app.
class FirebaseConfig {
  FirebaseConfig._();

  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: 'AIzaSyAsNqvAVScKN8UrUFcv2NF1TLUxbkvFKG8',
    authDomain: 'crisissync-11156.firebaseapp.com',
    projectId: 'crisissync-11156',
    storageBucket: 'crisissync-11156.firebasestorage.app',
    messagingSenderId: '63983001833',
    appId: '1:63983001833:web:1b9a0579a520a766cfd078',
    measurementId: 'G-DX02QTVSJQ',
    databaseURL: 'https://crisissync-11156-default-rtdb.firebaseio.com',
  );
}
