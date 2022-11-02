import 'package:json_annotation/json_annotation.dart';

part 'responses.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class RequestUploadingFileResponse {
  String uploadingUrl;
  String key;

  RequestUploadingFileResponse(this.uploadingUrl, this.key);

  factory RequestUploadingFileResponse.fromJson(Map<String, dynamic> json) => _$RequestUploadingFileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RequestUploadingFileResponseToJson(this);
}
