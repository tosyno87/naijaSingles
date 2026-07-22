import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

FirebaseFirestore firebaseFireStoreInstance = FirebaseFirestore.instance;
FirebaseAuth firebaseAuthInstance = FirebaseAuth.instance;

/// Prefer the default bucket from Firebase app options. Avoids reading
/// [bucketId]/dotenv during library init when `.env` is not bundled.
FirebaseStorage firebaseStorageInstance = FirebaseStorage.instance;
