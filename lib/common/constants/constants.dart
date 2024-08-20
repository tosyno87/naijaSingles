import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hookup4u2/config/app_config.dart';

final firebaseFireStoreInstance = FirebaseFirestore.instance;
final firebaseAuthInstance = FirebaseAuth.instance;
final firebaseStorageInstance = FirebaseStorage.instanceFor(bucket: bucketId);
