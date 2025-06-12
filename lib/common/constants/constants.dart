import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:naijasingles/config/app_config.dart';

FirebaseFirestore firebaseFireStoreInstance = FirebaseFirestore.instance;
FirebaseAuth firebaseAuthInstance = FirebaseAuth.instance;
FirebaseStorage firebaseStorageInstance =
    FirebaseStorage.instanceFor(bucket: bucketId);
