import 'package:cloud_firestore/cloud_firestore.dart';

class HealthDetailsModel {
  const HealthDetailsModel({
    required this.bloodPressure,
    required this.bloodSugar,
    required this.heartRate,
    required this.painLevel,
    required this.age,
    required this.weight,
    required this.height,
    required this.yogaLevel,
    this.updatedAt,
  });

  final String bloodPressure;
  final double bloodSugar;
  final int heartRate;
  final int painLevel;
  final int age;
  final double weight;
  final double height;
  final String yogaLevel;
  final DateTime? updatedAt;

  factory HealthDetailsModel.fromMap(Map<String, dynamic> data) {
    return HealthDetailsModel(
      bloodPressure: data['bloodPressure'] as String? ?? '',
      bloodSugar: _toDouble(data['bloodSugar']),
      heartRate: _toInt(data['heartRate']),
      painLevel: _toInt(data['painLevel']),
      age: _toInt(data['age']),
      weight: _toDouble(data['weight']),
      height: _toDouble(data['height']),
      yogaLevel: data['yogaLevel'] as String? ?? 'Beginner',
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'bloodPressure': bloodPressure,
      'bloodSugar': bloodSugar,
      'heartRate': heartRate,
      'painLevel': painLevel,
      'age': age,
      'weight': weight,
      'height': height,
      'yogaLevel': yogaLevel,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'bloodPressure': bloodPressure,
      'bloodSugar': bloodSugar,
      'heartRate': heartRate,
      'painLevel': painLevel,
      'age': age,
      'weight': weight,
      'height': height,
      'yogaLevel': yogaLevel,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  HealthDetailsModel copyWith({DateTime? updatedAt}) {
    return HealthDetailsModel(
      bloodPressure: bloodPressure,
      bloodSugar: bloodSugar,
      heartRate: heartRate,
      painLevel: painLevel,
      age: age,
      weight: weight,
      height: height,
      yogaLevel: yogaLevel,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
