import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/bluetooth/ng_command_state.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:universal_ble/universal_ble.dart';

import '../../providers/next_gen_provider.dart';

class NextGenOptionsDialog extends StatefulWidget {
  final BleDevice device;
  final DataTransferManager manager;

  const NextGenOptionsDialog({
    super.key,
    required this.device,
    required this.manager,
  });

  @override
  State<NextGenOptionsDialog> createState() => _NextGenOptionsDialogState();
}

class _NextGenOptionsDialogState extends State<NextGenOptionsDialog> {
  int _brightnessLevel = 1;
  bool _alwaysOnBle = false;
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _executeCommand(List<int> command, String successMessage) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final state = NgCommandState(
        device: widget.device,
        command: command,
      );

      final result = await state.process();

      if (result != null) {
        ToastUtils().showToast(successMessage);
      }
    } catch (e) {
      ToastUtils().showErrorToast(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveConfiguration() async {
    await _executeCommand(NgCommand.saveCfg(), "Configuration saved to Flash!");
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      elevation: 6,
      title: Row(
        children: [
          Icon(Icons.bolt, color: colorPrimary, size: 24.sp),
          SizedBox(width: 8.w),
          Text(
            "Next-Gen Options",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: _isLoading
            ? Container(
                height: 200.h,
                alignment: Alignment.center,
                child: CircularProgressIndicator(color: colorPrimary),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      color: drawerHeaderTitle,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Badge Brightness: $_brightnessLevel",
                              style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87),
                            ),
                            Slider(
                              value: _brightnessLevel.toDouble(),
                              min: 0,
                              max: 3,
                              divisions: 3,
                              activeColor: colorPrimary,
                              inactiveColor: mdGrey400,
                              onChanged: (val) {
                                setState(() => _brightnessLevel = val.toInt());
                              },
                              onChangeEnd: (val) {
                                _executeCommand(
                                  NgCommand.setBrightness(val.toInt()),
                                  "Brightness updated!",
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Card(
                      color: drawerHeaderTitle,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                      child: SwitchListTile(
                        title: Text(
                          "BLE Always On",
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                        subtitle: Text(
                          "Keeps Bluetooth active during the animation.",
                          style: TextStyle(fontSize: 10.sp, color: mdGrey400),
                        ),
                        value: _alwaysOnBle,
                        activeColor: colorPrimary,
                        onChanged: (val) {
                          setState(() => _alwaysOnBle = val);
                          _executeCommand(
                            NgCommand.setAlwaysOnBle(val),
                            val
                                ? "BLE set to Always On!"
                                : "BLE Standard restored",
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Card(
                      color: drawerHeaderTitle,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                maxLength: 20,
                                decoration: InputDecoration(
                                  labelText: "Rename Badge",
                                  labelStyle: TextStyle(
                                      fontSize: 12.sp, color: mdGrey400),
                                  counterText: "",
                                  isDense: true,
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: colorPrimary),
                                  ),
                                ),
                                style: TextStyle(fontSize: 13.sp),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.check_circle,
                                  color: colorPrimary, size: 28.sp),
                              onPressed: () {
                                if (_nameController.text.trim().isNotEmpty) {
                                  _executeCommand(
                                    NgCommand.setBleName(
                                        _nameController.text.trim()),
                                    "Name submitted successfully!",
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 8.h),
                          ),
                          onPressed: () {
                            _executeCommand(
                                NgCommand.powerOff(), "Shutdown command sent!");
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.power_settings_new, size: 16.sp),
                          label: Text("Power Off",
                              style: TextStyle(fontSize: 12.sp)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 8.h),
                          ),
                          onPressed: _saveConfiguration,
                          icon: Icon(Icons.save, size: 16.sp),
                          label: Text("Save to Flash",
                              style: TextStyle(fontSize: 12.sp)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            try {
              await UniversalBle.disconnect(widget.device.deviceId);
              ToastUtils().showToast("Disconnected from the badge");
            } catch (e) {
              debugPrint("Error during controlled disconnection: $e");
            }
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: Text(
            "Close",
            style: TextStyle(
                color: colorAccent,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
