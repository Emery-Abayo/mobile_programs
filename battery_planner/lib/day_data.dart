import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hour_slot.dart';

// Firestore access. Each user's day lives under users/{uid}/hours,
// one document per hour, with the document id equal to the hour ("7", "8"...).

CollectionReference<Map<String, dynamic>> myHours() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('hours');
}

/// Writes the whole sample day in one batch (all 17 hours or none).
/// Used when an account is created and by the Reset button.
Future<void> writeSampleDay() async {
  final batch = FirebaseFirestore.instance.batch();
  final col = myHours();
  for (final slot in sampleDay()) {
    batch.set(col.doc('${slot.hour}'), slot.toMap());
  }
  await batch.commit();
}

/// Saves one edited hour.
Future<void> saveSlot(HourSlot slot) {
  return myHours().doc('${slot.hour}').set(slot.toMap());
}
