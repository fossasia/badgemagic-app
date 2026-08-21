import 'package:badgemagic/constants.dart';
import 'package:badgemagic/view/widgets/navigation_drawer.dart';
import 'package:flutter/material.dart';

class CommonScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Key? scaffoldKey;
  final int index;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;

  const CommonScaffold({
    super.key,
    required this.body,
    required this.title,
    this.scaffoldKey,
    this.actions,
    required this.index,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: colorSurface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: Builder(builder: (context) {
          return IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(
              Icons.menu,
              color: colorOnPrimary,
            ),
          );
        }),
        backgroundColor: colorPrimary,
        title: Text(
          title,
          style: const TextStyle(color: colorOnPrimary),
        ),
        actions: [
          if (actions != null) ...actions!,
        ],
      ),
      drawer: BMDrawer(
        selectedIndex: index,
      ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
