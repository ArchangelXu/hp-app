// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
      json['id'] as String,
      json['image_url'] as String,
      json['device_type'] as int,
      DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
      'id': instance.id,
      'image_url': instance.imageUrl,
      'device_type': instance.deviceType,
      'created_at': instance.createdAt.toIso8601String(),
    };
