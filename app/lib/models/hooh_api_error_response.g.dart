// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hooh_api_error_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HoohApiErrorResponse _$HoohApiErrorResponseFromJson(Map<String, dynamic> json) => HoohApiErrorResponse(
      json['error_code'] as int,
      json['message'] as String? ?? '',
    );

Map<String, dynamic> _$HoohApiErrorResponseToJson(HoohApiErrorResponse instance) => <String, dynamic>{
      'error_code': instance.errorCode,
      'message': instance.message,
    };
