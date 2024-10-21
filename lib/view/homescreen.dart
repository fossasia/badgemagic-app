import 'dart:async';

import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/badgeview_provider.dart';
import 'package:badgemagic/providers/cardsprovider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/view/special_text_field.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/view/widgets/homescreentabs.dart';
import 'package:badgemagic/view/widgets/save_badge_dialog.dart';
import 'package:badgemagic/view/widgets/speedial.dart';
import 'package:badgemagic/view/widgets/vectorview.dart';
import 'package:badgemagic/virtualbadge/view/badge_home_view.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ValueNotifier<String> textNotifier = ValueNotifier<String>('');
  late final TabController _tabController;
  BadgeMessageProvider badgeData = BadgeMessageProvider();
  CardProvider cardData = GetIt.instance<CardProvider>();
  ImageUtils imageUtils = ImageUtils();
  InlineImageProvider inlineImageProvider =
      GetIt.instance<InlineImageProvider>();
  Converters converters = Converters();
  DrawBadgeProvider drawBadgeProvider = GetIt.instance<DrawBadgeProvider>();
  bool isPrefixIconClicked = false;
  int textfieldLength = 0;

  @override
  void initState() {
    inlineImageProvider.getController().addListener(_controllerListner);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    if (drawBadgeProvider.timer == null) {
      drawBadgeProvider.initializeAnimation();
    }

    _startImageCaching();
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
  }

  void _controllerListner() {
    converters.badgeAnimation(inlineImageProvider.getController().text.isEmpty
        ? ""
        : inlineImageProvider.getController().text);
    inlineImageProvider.controllerListener();
  }

  @override
  void dispose() {
    inlineImageProvider.getController().removeListener(_controllerListner);
    _tabController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  Future<void> _startImageCaching() async {
    if (!inlineImageProvider.isCacheInitialized) {
      await inlineImageProvider.generateImageCache();
      setState(() {
        inlineImageProvider.isCacheInitialized = true;
      });
    }
  }

  ScrollPhysics scrollphysics = ScrollPhysics();

  @override
  Widget build(BuildContext context) {
    CardProvider cardData = Provider.of<CardProvider>(context);
    InlineImageProvider inlineImageProvider =
        Provider.of<InlineImageProvider>(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cardData.setContext(context);
    });

    return DefaultTabController(
        length: 3,
        child: CommonScaffold(
          title: 'BadgeMagic',
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: scrollphysics,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 120.h,
                      ),
                      Container(
                        margin: EdgeInsets.all(15.w),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                          elevation: 4,
                          child: ExtendedTextField(
                            onChanged: (value) {},
                            controller: inlineImageProvider.getController(),
                            specialTextSpanBuilder: MySpecialTextSpanBuilder(),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              prefixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isPrefixIconClicked = !isPrefixIconClicked;
                                  });
                                },
                                icon: const Icon(Icons.tag_faces_outlined),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                          visible: isPrefixIconClicked,
                          child: Container(
                              height: 150.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.r),
                                color: Colors.grey.shade100,
                              ),
                              margin: EdgeInsets.symmetric(horizontal: 15.w),
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.h, horizontal: 10.w),
                              child: VectorGridView())),
                      TabBar(
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.red,
                        controller: _tabController,
                        splashFactory: InkRipple.splashFactory,
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Colors.grey[300];
                            }
                            return null;
                          },
                        ),
                        tabs: const [
                          Tab(text: 'Speed'),
                          Tab(text: 'Animation'),
                          Tab(text: 'Effects'),
                        ],
                      ),
                      SizedBox(
                        height: 180.h, // Adjust the height dynamically
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          controller: _tabController,
                          children: [
                            RadialDial(),
                            AnimationTab(),
                            EffectTab(),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return SaveBadgeDialog(
                                            textController: inlineImageProvider
                                                .getController(),
                                          );
                                        });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 33.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2.r),
                                      color: Colors.grey.shade400,
                                    ),
                                    child: const Text('Save'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 100.w,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    badgeData.checkAndTransfer();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2.r),
                                      color: Colors.grey.shade400,
                                    ),
                                    child: const Text('Transfer'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const BMBadgeHome(),
              ],
            ),
          ),
          scaffoldKey: const Key(homeScreenTitleKey),
        ));
  }
}
