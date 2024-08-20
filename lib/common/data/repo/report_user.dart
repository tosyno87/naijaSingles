import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/constants.dart';

abstract class ReportRepository {
  Future<String> reportUser(
      {required String reportedBy,
      required String reported,
      required String reason,
      required String? moreReason});
}

class ReportRepositoryImpl extends ReportRepository {
  @override
  Future<String> reportUser(
      {required String reportedBy,
      required String reported,
      required String reason,
      required String? moreReason}) async {
    await firebaseFireStoreInstance.collection("Reports").add({
      'reported_by': reportedBy,
      'victim_id': reported,
      'reason': reason,
      'details': moreReason,
      'timestamp': FieldValue.serverTimestamp()
    });
    return "done";
  }
}
