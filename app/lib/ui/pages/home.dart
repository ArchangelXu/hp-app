import 'package:app/models/post.dart';
import 'package:app/ui/pages/image_editor.dart';
import 'package:app/ui/pages/image_selector.dart';
import 'package:app/ui/wigets/post.dart';
import 'package:app/utils/design_colors.dart';
import 'package:app/utils/network.dart';
import 'package:app/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Post> posts = [];
  DateTime? lastTimestamp;
  bool noMore = false;
  RefreshController refreshController = RefreshController(initialRefresh: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hyperbound Flutter Demo")),
      body: SmartRefresher(
        controller: refreshController,
        enablePullDown: true,
        enablePullUp: noMore,
        onRefresh: () {
          loadPosts(refresh: true);
        },
        onLoading: () {
          loadPosts();
        },
        child: ListView.separated(
          padding: EdgeInsets.only(bottom: 96),
          itemBuilder: (context, index) => PostWidget(post: posts[index]),
          itemCount: posts.length,
          separatorBuilder: (BuildContext context, int index) => Container(
            height: 1,
            color: designColors.dark_03.auto(ref).withOpacity(0.25),
          ),
        ),
      ),
      floatingActionButton: GestureDetector(
        child: HoohIcon(
          "assets/images/ic_home_button.svg",
          width: 78,
          height: 78,
        ),
        onTap: () async {
          PhotoManager.requestPermissionExtend().then((permission) {
            if (permission.isAuth) {
              Navigator.push<AssetEntity?>(context, MaterialPageRoute(builder: (context) => ImageSelectorScreen())).then((entity) {
                if (entity != null) {
                  Navigator.push<bool?>(context, MaterialPageRoute(builder: (context) => ImageEditorScreen(entity: entity))).then((published) {
                    if (published != null && published) {
                      refreshController.requestRefresh();
                    }
                  });
                }
              });
              // Granted.
            } else {
              if (permission == PermissionState.limited) {
                showHoohDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("您授予了有限权限"),
                      content: Text("若要使用，请授予完全相册权限"),
                      actions: [
                        TextButton(
                            onPressed: () {
                              PhotoManager.openSetting();
                            },
                            child: Text("去设置"))
                      ],
                    );
                  },
                );
              } else {
                showHoohDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("未授予权限"),
                      content: Text("若要使用，请授予相册权限"),
                    );
                  },
                );
              }
            }
          });
        },
      ),
    );
  }

  void loadPosts({bool refresh = false}) {
    if (refresh) {
      lastTimestamp = null;
      setState(() {
        posts.clear();
      });
    }
    network.requestAsync(network.getFeeds(date: lastTimestamp), (data) {
      if (data.isEmpty) {
        setState(() {
          noMore = true;
        });
      }
      setState(() {
        posts.addAll(data);
      });
      refreshController.refreshCompleted();
      refreshController.loadComplete();
    }, (error) {
      showHoohDialog(
        context: context,
        builder: (context) => AlertDialog(content: Text(error.message)),
      );
      refreshController.refreshCompleted();
      refreshController.loadComplete();
    });
  }
}
