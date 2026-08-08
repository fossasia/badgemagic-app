import 'package:badgemagic/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class LicenseDialogContainer extends StatelessWidget {
  final String title;
  final String content;
  final String url;
  const LicenseDialogContainer({
    super.key,
    required this.title,
    required this.content,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 16,
            ),
            Text(
              title,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            // SizedBox(
            //   width: 8,
            // ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: GestureDetector(
            onTap: () => openUrl(url),
            child: Text(
              url,
              style: GoogleFonts.sora(
                decoration: TextDecoration.underline,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[300],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Text(
              content,
              style: GoogleFonts.sora(
                wordSpacing: 10,
                letterSpacing: 0.6,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void showLicenseDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: EdgeInsets.all(8),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: 500.h),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(left: 16.0, top: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Notices',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LicenseDialogContainer(
                            title: '• Moshi',
                            url: 'https://github.com/square/moshi',
                            content: ''''Copyright 2015 Square, Inc.
                    
                    Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
                    
                    http://www.apache.org/licenses/LICENSE- 2.0
                    
                    Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.''',
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          LicenseDialogContainer(
                            title: '• Moshi',
                            url: 'https://github.com/JakeWharton/timber',
                            content: ''''Copyright 2013 Jake Wharton\n'
                                  'Permission is hereby granted, free of charge, to any person obtaining a copy '
                                  'of this software and associated documentation files (the "Software"), to deal '
                                  'in the Software without restriction, including without limitation the rights to use, '
                                  'copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, '
                                  'and to permit persons to whom the Software is furnished to do so, subject to the following conditions:',''',
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          LicenseDialogContainer(
                            title: '• android-gif-drawable',
                            url:
                                'https://github.com/koral--/android-gif- drawable',
                            content:
                                ''''Copyright 2013 Droids on Roids LLC present Karol Wrótniak,
                    
                    Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
                    
                    http://www.apache.org/licenses/LICENSE-
                    
                    2.0
                    
                    Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.''',
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          LicenseDialogContainer(
                            title: '• Timber',
                            url: 'https://github.com/JakeWharton/timber',
                            content: ''''Copyright 2013 Jake Wharton
                    
                    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
                    
                    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
                    
                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.''',
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          LicenseDialogContainer(
                            title: '• Android BLE Scanner Compat library',
                            url:
                                'https://github.com/NordicSemiconductor/Android-Scanner-Compat-Library',
                            content: ''''Copyright 2015, Nordic Semiconductor
                    
                    Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
                    
                    http://www.apache.org/licenses/LICENSE-
                    
                    2.0
                    
                    Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.''',
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          LicenseDialogContainer(
                            title: '• LicensesDialog',
                            url: 'http://psdev.de/LicensesDialog',
                            content: ''''Copyright 2013-2016 Philip Schiffer
                    
                    Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
                    
                    http://www.apache.org/licenses/LICENSE- 2.0
                    
                    Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.''',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
