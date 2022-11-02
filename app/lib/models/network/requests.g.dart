// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'requests.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePostRequest _$CreatePostRequestFromJson(Map<String, dynamic> json) => CreatePostRequest(
      json['image_key'] as String,
    );

Map<String, dynamic> _$CreatePostRequestToJson(CreatePostRequest instance) => <String, dynamic>{
      'image_key': instance.imageKey,
    };

RequestUploadingFileRequest _$RequestUploadingFileRequestFromJson(Map<String, dynamic> json) => RequestUploadingFileRequest(
      json['md5'] as String,
      json['ext'] as String,
    );

Map<String, dynamic> _$RequestUploadingFileRequestToJson(RequestUploadingFileRequest instance) => <String, dynamic>{
      'md5': instance.md5,
      'ext': instance.ext,
    };
