import 'package:app/models/post.dart';
import 'package:app/utils/date_util.dart';
import 'package:app/utils/design_colors.dart';
import 'package:app/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PostWidget extends ConsumerWidget {
  final Post post;

  const PostWidget({
    required this.post,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 30, bottom: 16, right: 30),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(7)),
                child: HoohImage(
                  imageUrl: post.imageUrl,
                  width: 158,
                  height: 158,
                ),
              ),
              SizedBox(
                height: 6,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateUtil.getZonedDateString(post.createdAt),
                    style: TextStyle(fontSize: 12, color: designColors.dark_03.auto(ref)),
                  ),
                  SizedBox(
                    width: 12,
                  ),
                  Text(
                    post.getDeviceTypeString(),
                    style: TextStyle(fontSize: 12, color: designColors.dark_03.auto(ref)),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
