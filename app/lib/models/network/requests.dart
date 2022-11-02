import 'package:json_annotation/json_annotation.dart';

part 'requests.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CreatePostRequest {
  String imageKey;

  CreatePostRequest(this.imageKey);

  factory CreatePostRequest.fromJson(Map<String, dynamic> json) => _$CreatePostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePostRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class RequestUploadingFileRequest {
  String md5;
  String ext;

  RequestUploadingFileRequest(this.md5, this.ext);

  factory RequestUploadingFileRequest.fromJson(Map<String, dynamic> json) => _$RequestUploadingFileRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RequestUploadingFileRequestToJson(this);
}
