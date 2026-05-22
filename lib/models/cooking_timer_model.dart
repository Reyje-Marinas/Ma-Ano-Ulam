import 'package:cloud_firestore/cloud_firestore.dart';

class CookingTimerModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final int durationSeconds;
  final String? linkedMealId;
  final String? linkedMealName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CookingTimerModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.durationSeconds,
    this.linkedMealId,
    this.linkedMealName,
    required this.createdAt,
    this.updatedAt,
  });

  CookingTimerModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    int? durationSeconds,
    String? linkedMealId,
    String? linkedMealName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CookingTimerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      linkedMealId: linkedMealId ?? this.linkedMealId,
      linkedMealName: linkedMealName ?? this.linkedMealName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'durationSeconds': durationSeconds,
      'linkedMealId': linkedMealId,
      'linkedMealName': linkedMealName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory CookingTimerModel.fromMap(
      String id,
      Map<String, dynamic> map,
      ) {
    return CookingTimerModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      linkedMealId: map['linkedMealId'],
      linkedMealName: map['linkedMealName'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}