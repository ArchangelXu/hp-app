import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app/extensions/extensions.dart';
import 'package:app/models/network/requests.dart';
import 'package:app/models/network/responses.dart';
import 'package:app/utils/design_colors.dart';
import 'package:app/utils/network.dart';
import 'package:app/utils/ui_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:screenshot/screenshot.dart';
import 'package:universal_io/io.dart';

class ImageEditorScreen extends ConsumerStatefulWidget {
  final AssetEntity entity;

  const ImageEditorScreen({
    required this.entity,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends ConsumerState<ImageEditorScreen> {
  Uint8List? imageFileBytes;
  Uint8List? imageBytes;
  Uint8List? tonedImageFileBytes;
  int? selectedFilter;
  img.Image? decodeImage;
  bool editText = false;
  TextEditingController textEditingController = TextEditingController();
  String? text;
  double textX = 0;
  double textY = 0;
  bool touchingFrame = false;
  bool movingFrame = false;
  final textFrameKey = GlobalKey();
  final imageFrameKey = GlobalKey();
  bool drawTextFrame = false;
  var touchStartTime;
  late Offset originalFrameLocation;
  late Size textFrameSize;
  late ui.Offset panStartLocation;
  double horizontalPadding = 40;
  late double imageHeight;

  @override
  void initState() {
    super.initState();
    widget.entity.originBytes.then((value) {
      setState(() {
        imageFileBytes = value;
        decodeImage = img.decodeImage(getCurrentImageFileBytes()!.toList());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    imageHeight = decodeImage == null ? 300 : (decodeImage!.height / decodeImage!.width * (MediaQuery.of(context).size.width - horizontalPadding * 2));
    debugPrint("imageHeight=$imageHeight");
    return Scaffold(
      appBar: AppBar(
        backgroundColor: editText ? Colors.transparent : null,
        leading: editText
            ? TextButton(
                onPressed: () {
                  setState(() {
                    editText = false;
                  });
                },
                child: Text("取消"))
            : null,
        actions: editText
            ? [
                TextButton(
                    onPressed: () {
                      String newText = textEditingController.text;
                      if (newText.trim().isEmpty) {
                        showHoohDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: Text("尚未输入文字"),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        textX = 0;
                        textY = 0;
                        text = newText;
                        editText = false;
                      });
                    },
                    child: Text("完成"))
              ]
            : [
                TextButton(
                    onPressed: () {
                      createPost();
                    },
                    child: Text("发布"))
              ],
      ),
      extendBody: editText,
      extendBodyBehindAppBar: editText,
      body: editText ? buildInputView() : buildNormalStateView(),
    );
  }

  Padding buildNormalStateView() {
    return Padding(
      padding: editText ? EdgeInsets.zero : EdgeInsets.only(top: 8.0, bottom: 48, left: horizontalPadding, right: horizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(height: imageHeight, child: getCurrentImageFileBytes() == null ? CircularProgressIndicator() : buildMainView()),
          SizedBox(
            height: 24,
          ),
          Visibility(
            visible: !editText,
            child: SizedBox(
              height: 100,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Row(
                      children: [
                        buildFilterItemWidget(0, "assets/images/ic_filter_1.jpg", "滤镜1"),
                        SizedBox(
                          width: 16,
                        ),
                        buildFilterItemWidget(1, "assets/images/ic_filter_2.jpg", "滤镜2")
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Positioned buildAddTextButton() {
    return Positioned(
      right: 16,
      top: 16,
      child: Visibility(
        visible: !editText,
        child: GestureDetector(
          onTap: () {
            setState(() {
              editText = true;
            });
          },
          child: HoohIcon(
            "assets/images/ic_add_text.svg",
            width: 38,
            height: 38,
            color: designColors.light_01.light,
          ),
        ),
      ),
    );
  }

  Widget buildInputView() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.memory(
            getCurrentImageFileBytes()!,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            padding: EdgeInsets.all(horizontalPadding),
            color: Colors.black.withOpacity(0.70),
            child: Center(
              child: TextField(
                controller: textEditingController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                cursorColor: designColors.light_01.light,
                decoration:
                    InputDecoration(border: InputBorder.none, hintText: "输入文字", hintStyle: TextStyle(color: designColors.light_01.light.withOpacity(0.5))),
                style: TextStyle(fontSize: 20, color: designColors.light_01.light),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Uint8List? getCurrentImageFileBytes() {
    if (selectedFilter == null) {
      return imageFileBytes;
    } else {
      return tonedImageFileBytes;
    }
  }

  Widget buildMainView() {
    Widget image;
    Widget textWidget;
    List<Widget> children = [
      Positioned.fill(
        child: GestureDetector(
          onTap: () {
            setState(() {
              drawTextFrame = false;
            });
          },
          child: ClipRRect(
              key: imageFrameKey,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              child: Image.memory(
                getCurrentImageFileBytes()!,
                fit: editText ? BoxFit.cover : BoxFit.contain,
              )),
        ),
      ),
      Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Center(
            child: Visibility(
              visible: movingFrame,
              child: DragTarget(
                onAccept: (data) {
                  setState(() {
                    text = null;
                    textEditingController.text = "";
                  });
                },
                onWillAccept: (data) => true,
                builder: (context, candidateData, rejectedData) {
                  return Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: designColors.light_01.light.withOpacity(0.25), shape: BoxShape.circle),
                      child: Center(
                        child: HoohIcon(
                          "assets/images/ic_delete.svg",
                          width: 32,
                          height: 33,
                          color: designColors.light_01.light,
                        ),
                      ));
                },
              ),
            ),
          ))
    ];
    children.add(buildAddTextButton());
    if (text != null) {
      textWidget = buildTextView();
      children.add(
        Positioned(
            top: textY,
            left: textX,
            child: Draggable(
              data: 0,
              feedback: textWidget,
              childWhenDragging: Container(),
              child: textWidget,
              onDragStarted: () {
                ui.Rect? rect = textFrameKey.globalPaintBounds;
                if (rect == null) {
                  return;
                }
                originalFrameLocation = Offset(rect.left, rect.top);
                setState(() {
                  movingFrame = true;
                });
              },
              onDragEnd: (details) {
                debugPrint("details=${details.offset}");
                setState(() {
                  ui.Size screenSize = MediaQuery.of(context).size;
                  textX += details.offset.dx - originalFrameLocation.dx;
                  textY += details.offset.dy - originalFrameLocation.dy;
                  ui.Rect? rect = textFrameKey.globalPaintBounds;
                  if (rect == null) {
                    return;
                  }
                  if (textX < 0) {
                    textX = 0;
                  } else if (textX + rect.width > screenSize.width - 2 * horizontalPadding) {
                    textX = screenSize.width - 2 * horizontalPadding - rect.width;
                  }
                  if (textY < 0) {
                    textY = 0;
                  } else if (textY + rect.height > imageHeight) {
                    textY = imageHeight - rect.height;
                  }
                });
                setState(() {
                  movingFrame = false;
                });
              },
            )),
      );
    }
    image = Stack(
      children: children,
    );

    // Widget clipRRect = GestureDetector(
    //   onTap: () {
    //     setState(() {
    //       drawTextFrame = false;
    //     });
    //   },
    //   child: ClipRRect(
    //       key: imageFrameKey,
    //       borderRadius: BorderRadius.all(Radius.circular(10)),
    //       child: Image.memory(
    //         imageFileBytes!,
    //         fit: editText ? BoxFit.cover : BoxFit.contain,
    //       )),
    // );
    // Widget textWidget;
    // if (text != null) {
    //   textWidget = buildTextView();
    //   image = Stack(
    //     children: [
    //       Positioned.fill(
    //         child: clipRRect,
    //       ),
    //       Positioned(
    //           top: textY,
    //           left: textX,
    //           child: Draggable(
    //             data: 0,
    //             feedback: textWidget,
    //             childWhenDragging: Container(),
    //             child: textWidget,
    //             onDragStarted: () {
    //               ui.Rect? rect = textFrameKey.globalPaintBounds;
    //               if (rect == null) {
    //                 return;
    //               }
    //               originalFrameLocation = Offset(rect.left, rect.top);
    //               setState(() {
    //                 movingFrame = true;
    //               });
    //             },
    //             onDragEnd: (details) {
    //               debugPrint("details=${details.offset}");
    //               setState(() {
    //                 ui.Size screenSize = MediaQuery.of(context).size;
    //                 textX += details.offset.dx - originalFrameLocation.dx;
    //                 textY += details.offset.dy - originalFrameLocation.dy;
    //                 ui.Rect? rect = textFrameKey.globalPaintBounds;
    //                 if (rect == null) {
    //                   return;
    //                 }
    //                 if (textX < 0) {
    //                   textX = 0;
    //                 } else if (textX + rect.width > screenSize.width - 2 * horizontalPadding) {
    //                   textX = screenSize.width - 2 * horizontalPadding - rect.width;
    //                 }
    //                 if (textY < 0) {
    //                   textY = 0;
    //                 } else if (textY + rect.height > imageHeight) {
    //                   textY = imageHeight - rect.height;
    //                 }
    //               });
    //               setState(() {
    //                 movingFrame = false;
    //               });
    //             },
    //           )),
    //       buildAddTextButton(),
    //       Positioned(
    //           left: 0,
    //           right: 0,
    //           bottom: 16,
    //           child: Center(
    //             child: Visibility(
    //               visible: movingFrame,
    //               child: DragTarget(
    //                 onAccept: (data) {
    //                   setState(() {
    //                     text = null;
    //                     textEditingController.text = "";
    //                   });
    //                 },
    //                 onWillAccept: (data) => true,
    //                 builder: (context, candidateData, rejectedData) {
    //                   return Container(
    //                       width: 64,
    //                       height: 64,
    //                       decoration: BoxDecoration(color: designColors.light_01.light.withOpacity(0.25), shape: BoxShape.circle),
    //                       child: Center(
    //                         child: HoohIcon(
    //                           "assets/images/ic_delete.svg",
    //                           width: 32,
    //                           height: 33,
    //                           color: designColors.light_01.light,
    //                         ),
    //                       ));
    //                 },
    //               ),
    //             ),
    //           ))
    //     ],
    //   );
    // } else {
    //   image = clipRRect;
    // }
    return image;
  }

  GestureDetector buildTextView({bool forScreenshot = false}) {
    return GestureDetector(
      onTap: forScreenshot
          ? null
          : () {
              setState(() {
                drawTextFrame = true;
              });
            },
      child: Container(
        key: forScreenshot ? null : textFrameKey,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            border: Border.all(color: (!forScreenshot && drawTextFrame) ? designColors.blue.auto(ref) : Colors.transparent, width: 2),
            borderRadius: BorderRadius.all(Radius.circular(2))),
        child: Text(
          text!,
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }

  Widget buildFilterItemWidget(int index, String filterImage, String filterName) {
    return GestureDetector(
      onTap: () {
        if (selectedFilter == index) {
          //clear
          setState(() {
            selectedFilter = null;
          });
        } else {
          showHoohDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return LoadingDialog(LoadingDialogController());
              });
          setState(() {
            selectedFilter = index;
            if (index == 0) {
              tonedImageFileBytes = getTonedImageFileBytes(0.3, -0.2);
            } else if (index == 1) {
              tonedImageFileBytes = getTonedImageFileBytes(0, -0.7);
            } else {
              selectedFilter = null;
            }
          });
          Navigator.of(
            context,
          ).pop();
        }
      },
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(color: index == selectedFilter ? designColors.blue.auto(ref) : Colors.transparent),
            borderRadius: BorderRadius.all(Radius.circular(4))),
        padding: EdgeInsets.all(4),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(5)),
              child: HoohIcon(
                filterImage,
                width: 48,
                height: 62,
              ),
            ),
            SizedBox(
              height: 3,
            ),
            Text(
              filterName,
              style: TextStyle(color: designColors.dark_01.auto(ref)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> createPost() async {
    File file = await createImageFile();
    // showHoohDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(content: Image.file(file)),
    // );
    // return;
    RequestUploadingFileResponse response = await requestUploadingImage(file);
    debugPrint("file size=${await file.length()}");
    bool uploadSuccess = await uploadImageFile(response.uploadingUrl, response.key, file);
    debugPrint("uploadSuccess=$uploadSuccess");
    if (uploadSuccess) {
      network.requestAsync(network.createPost(CreatePostRequest(response.key)), (post) {
        showHoohDialog(
            context: context,
            builder: (context) => AlertDialog(
                  content: Text("发布成功"),
                )).then((value) {
          Navigator.of(
            context,
          ).pop(true);
        });
      }, (error) {
        showHoohDialog(
            context: context,
            builder: (context) => AlertDialog(
                  content: Text(error.message),
                ));
      });
    }
  }

  Future<File> createImageFile() async {
    return await _saveScreenshot();
  }

  Future<bool> uploadImageFile(String url, String key, File file) {
    String ext = file.path;
    ext = ext.substring(ext.lastIndexOf(".") + 1).toLowerCase();
    return network.uploadFile(url, file.readAsBytesSync(), headers: {"content-type": "image/${ext == "png" ? "png" : "jpeg"}"});
    // return network.uploadFile(url, file.readAsBytesSync(), );
  }

  Future<RequestUploadingFileResponse> requestUploadingImage(File file) => network.requestUploadingPostImage(file);

  Future<File> _saveScreenshot() async {
    var children = [
      Positioned.fill(
          child: Image.memory(
        getCurrentImageFileBytes()!,
        fit: editText ? BoxFit.cover : BoxFit.contain,
      )),
    ];
    if (text != null) {
      children.add(
        Positioned(top: textY, left: textX, child: buildTextView(forScreenshot: true)),
      );
    }
    Widget widget = ProviderScope(
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 2 * horizontalPadding,
        height: imageHeight,
        child: Stack(
          children: children,
        ),
      ),
    );
    ScreenshotController screenshotController = ScreenshotController();
    Uint8List fileBytes = await screenshotController.captureFromWidget(widget, pixelRatio: 3);
    img.Image image = img.decodeImage(fileBytes)!;
    List<int> jpgBytes = img.encodeJpg(image, quality: 100);
    // List<int> jpgBytes = img.encodePng(image);
    String name = md5.convert(jpgBytes).toString();
    Directory saveDir = await getApplicationDocumentsDirectory();
    File file = File('${saveDir.path}/$name.jpg');
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsBytesSync(jpgBytes, flush: true);
    return file;
  }

  Uint8List getTonedImageFileBytes(double saturation, double lightness) {
    img.Image? image = img.decodeImage(imageFileBytes!);
    Uint32List pixels = image!.data;
    for (int i = 0; i < pixels.length; i++) {
      int pixel = pixels[i];
      Color color = Color(pixel);
      int a = color.alpha;
      int b = color.red;
      int g = color.green;
      int r = color.blue;
      color = Color.fromARGB(a, r, g, b);
      HSLColor hslColor = HSLColor.fromColor(color);
      // double hue2 = hslColor.hue + hue;
      // if (hue2 > 360) {
      //   hue2 -= 360;
      // }
      double saturation2 = hslColor.saturation + saturation;
      if (saturation2 > 1) {
        saturation2 = 1;
      } else if (saturation2 < 0) {
        saturation2 = 0;
      }
      double lightness2 = hslColor.lightness + lightness;
      if (lightness2 > 1) {
        lightness2 = 1;
      } else if (lightness2 < 0) {
        lightness2 = 0;
      }
      hslColor = hslColor.withSaturation(saturation2).withLightness(lightness2);
      color = hslColor.toColor();
      pixels[i] = Color.fromARGB(color.alpha, color.blue, color.green, color.red).value;
    }
    return Uint8List.fromList(img.encodeJpg(image));
  }
}
