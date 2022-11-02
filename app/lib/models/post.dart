import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Post {
  static const DEVICE_TYPE_ANDROID = 0;

  static const DEVICE_TYPE_IOS = 1;

  static const DEVICE_TYPE_OTHER = 2;

  String id;
  String imageUrl;
  int deviceType;
  DateTime createdAt;

  String getDeviceTypeString() {
    switch (deviceType) {
      case DEVICE_TYPE_ANDROID:
        return "Android";
      case DEVICE_TYPE_IOS:
        return "iOS";
      case DEVICE_TYPE_OTHER:
      default:
        return "Other";
    }
  }

  Post(this.id, this.imageUrl, this.deviceType, this.createdAt);

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);
}
