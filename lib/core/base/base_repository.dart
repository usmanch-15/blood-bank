import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseRepository {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<DocumentSnapshot> getById(String collection, String id) async {
    return await db.collection(collection).doc(id).get();
  }

  Future<void> save(String collection, String id, Map<String, dynamic> data) async {
    await db.collection(collection).doc(id).set(data, SetOptions(merge: true));
  }

  Future<void> update(String collection, String id, Map<String, dynamic> data) async {
    await db.collection(collection).doc(id).update(data);
  }

  Future<void> delete(String collection, String id) async {
    await db.collection(collection).doc(id).delete();
  }

  Future<QuerySnapshot> getAll(String collection) async {
    return await db.collection(collection).get();
  }
}