import 'package:cloud_firestore/cloud_firestore.dart';
import 'karma_service.dart';

class MissionService {
  final String uid;
  MissionService(this.uid) {
    if (uid.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
  }

  CollectionReference get _missionsCol =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('missions');

  Stream<List<Map<String, dynamic>>> streamMissions() {
    return _missionsCol.limit(20).snapshots().map(
      (querySnapshot) {
        final uniqueMissions = <String, Map<String, dynamic>>{};
        for (var doc in querySnapshot.docs) {
          final data = doc.data()! as Map<String, dynamic>;
          final id = data['id'] as String?;
          if (id != null && !uniqueMissions.containsKey(id)) {
            uniqueMissions[id] = data;
          }
        }
        return uniqueMissions.values.toList();
      },
    );
  }

  Future<void> addMissionFromMap(Map<String, dynamic> missionMap) async {
    final id = missionMap['id'] as String?;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Mission map must contain a non-empty "id" field');
    }
    await _missionsCol.doc(id).set(missionMap);
  }

  Future<void> completeMission(String missionId) async {
    final missionDoc = _missionsCol.doc(missionId);
    final karmaService = KarmaService(uid);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(missionDoc);
      if (!snap.exists) {
        throw Exception('Mission $missionId does not exist');
      }
      final data = snap.data()! as Map<String, dynamic>;
      if (data['done'] == true) {
        // Already done, no update needed
        return;
      }
      txn.update(missionDoc, {'done': true});
    });

    // Update score outside transaction to avoid nested transaction issues
    await karmaService.updateScore(10);

    await FirebaseFirestore.instance.collection('users').doc(uid).collection('karma_events').add({
      'date': DateTime.now(),
      'delta': 10,
      'reason': 'Mission completed: $missionId',
    });
  }
}
