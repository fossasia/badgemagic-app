import 'package:badgemagic/constants.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:get_it/get_it.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  @override
  void initState() {
    _setOrientation();
    // TODO: implement initState
    super.initState();
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return CommonScaffold(
      title: l10n.aboutUs,
      index: 5,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.grey,
                      offset: Offset(0, 1),
                      blurRadius: 2.0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 25,
                      ),
                      Center(
                        child: Image.asset(
                          'assets/icons/icon.png',
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        l10n.aboutBadgeMagic,
                        textAlign: TextAlign.justify,
                        style: GoogleFonts.sora(
                          wordSpacing: 3,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                          fontSize: 12,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              l10n.developedBy,
                              style: GoogleFonts.sora(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 10),
                          Flexible(
                            child: GestureDetector(
                              onTap: () => openUrl(
                                  'https://github.com/fossasia/badgemagic-app/graphs/contributors'),
                              child: Text(
                                l10n.fossasiaContributors,
                                style: GoogleFonts.sora(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 1,
                      color: Colors.grey,
                      offset: Offset(0, 1),
                    )
                  ],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 12.0, top: 12.0),
                      child: Text(
                        l10n.contactWithUs,
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Image.asset(
                        'assets/icons/github.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                      title: Text(
                        l10n.github,
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        l10n.githubDescription,
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                        softWrap: true,
                      ),
                      onTap: () =>
                          openUrl('https://github.com/fossasia/badgemagic-app'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 1,
                      color: Colors.grey,
                      offset: Offset(0, 1),
                    )
                  ],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        l10n.license,
                        style: GoogleFonts.sora(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Image.asset(
                        'assets/icons/badge.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                      title: Text(
                        l10n.license,
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        '${l10n.checkApacheLicense} ${l10n.appTitle}',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                        softWrap: true,
                      ),
                      onTap: () => openUrl(
                          'https://github.com/fossasia/badgemagic-app/blob/development/LICENSE'),
                    ),
                    // ListTile(
                    //   leading: Image.asset('assets/icons/book.png', height: 40),
                    //   title: Text(
                    //     'Library Licenses',
                    //     style: GoogleFonts.sora(
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.w500,
                    //         color: Colors.black),
                    //   ),
                    //   subtitle: Text(
                    //     'Check third-party libs used on Badge Magic.',
                    //     style: GoogleFonts.sora(
                    //         fontSize: 12,
                    //         fontWeight: FontWeight.w500,
                    //         color: Colors.grey),
                    //   ),
                    //   onTap: () => showLicenseDialog(context),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
