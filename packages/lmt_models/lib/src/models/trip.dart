import 'package:json_annotation/json_annotation.dart';

part 'trip.g.dart';

@JsonSerializable()
class Trip {
  final int? id;
  final String? name;
  final DateTime startTime;
  final DateTime? endTime;
  final double? distance;
  final bool isSynced;

  Trip({
    this.id,
    this.name,
    required this.startTime,
    this.endTime,
    this.distance,
    this.isSynced = false,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
  Map<String, dynamic> toJson() => _$TripToJson(this);
}
