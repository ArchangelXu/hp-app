import 'package:app/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ImageSelectorScreen extends ConsumerStatefulWidget {
  const ImageSelectorScreen({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState createState() => _ImageSelectorScreenState();
}

class _ImageSelectorScreenState extends ConsumerState<ImageSelectorScreen> {
  bool loading = true;
  bool noMore = false;
  AssetPathEntity? mainPath;
  int page = 0;
  List<AssetEntity> imageEntities = [];
  RefreshController refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    PhotoManager.getAssetPathList(type: RequestType.image).then((paths) {
      debugPrint("paths=${paths.map((e) => e.name)}");
      setState(() {
        mainPath = paths[0];
        loadImages();
        loading = false;
      });
    });
  }

  void loadImages({bool refresh = false}) {
    if (refresh) {
      page = 0;
      setState(() {
        imageEntities.clear();
      });
    }
    mainPath?.getAssetListPaged(page: page, size: 100).then((entities) {
      setState(() {
        if (entities.isEmpty) {
          noMore = true;
        }
        imageEntities.addAll(entities);
      });
      refreshController.refreshCompleted();
      refreshController.loadComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("选择照片")),
      body: loading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SmartRefresher(
              enablePullDown: true,
              enablePullUp: noMore,
              onRefresh: () {
                loadImages(refresh: true);
              },
              onLoading: () {
                loadImages();
              },
              controller: refreshController,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 1),
                itemCount: imageEntities.length,
                itemBuilder: (context, index) {
                  AssetEntity item = imageEntities[index];
                  return GestureDetector(
                    child: buildAssetImageWidget(item),
                    onTap: () {
                      Navigator.of(
                        context,
                      ).pop(item);
                    },
                  );
                },
              ),
            ),
    );
  }
}
