import 'package:badgemagic/providers/cardsprovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AniContainer extends StatefulWidget {
  final String animation;
  final String aniName;
  final int index;

  const AniContainer({
    super.key,
    required this.animation,
    required this.aniName,
    required this.index,
  });

  @override
  State<AniContainer> createState() => _AniContainerState();
}

class _AniContainerState extends State<AniContainer> {
  @override
  Widget build(BuildContext context) {
    CardProvider animationCardState = Provider.of<CardProvider>(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
      height: 50.h,
      width: 110.w,
      child: GestureDetector(
        onTap: () {
          animationCardState.setAnimationIndex(widget.index);
        },
        child: Card(
          surfaceTintColor: Colors.white,
          color: animationCardState.getAnimationIndex() == widget.index
              ? Colors.red
              : Colors.white,
          elevation: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                widget.animation,
                height: 30.h,
              ),
              Text(
                widget.aniName,
                style: TextStyle(fontSize: 9.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
