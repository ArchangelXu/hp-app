// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'responses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestUploadingFileResponse _$RequestUploadingFileResponseFromJson(Map<String, dynamic> json) => RequestUploadingFileResponse(
      json['uploading_url'] as String,
      json['key'] as String,
    );

Map<String, dynamic> _$RequestUploadingFileResponseToJson(RequestUploadingFileResponse instance) => <String, dynamic>{
      'uploading_url': instance.uploadingUrl,
      'key': instance.key,
    };
