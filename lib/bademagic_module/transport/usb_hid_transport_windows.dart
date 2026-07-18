import 'dart:ffi';
import 'dart:io';

import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/transport/badge_transport.dart';
import 'package:ffi/ffi.dart';
import 'package:logger/logger.dart';

const int _digcfPresent = 0x00000002;
const int _digcfDeviceInterface = 0x00000010;
const int _genericWrite = 0x40000000;
const int _fileShareRead = 0x00000001;
const int _fileShareWrite = 0x00000002;
const int _openExisting = 3;
const int _invalidHandle = -1;

final class _Guid extends Struct {
  @Uint32()
  external int data1;
  @Uint16()
  external int data2;
  @Uint16()
  external int data3;
  @Array(8)
  external Array<Uint8> data4;
}

final class _SpDeviceInterfaceData extends Struct {
  @Uint32()
  external int cbSize;
  external _Guid interfaceClassGuid;
  @Uint32()
  external int flags;
  @IntPtr()
  external int reserved;
}

final class _HiddAttributes extends Struct {
  @Uint32()
  external int size;
  @Uint16()
  external int vendorId;
  @Uint16()
  external int productId;
  @Uint16()
  external int versionNumber;
}

typedef _HidDGetHidGuidC = Void Function(Pointer<_Guid>);
typedef _HidDGetHidGuidDart = void Function(Pointer<_Guid>);

typedef _HidDGetAttributesC = Int32 Function(IntPtr, Pointer<_HiddAttributes>);
typedef _HidDGetAttributesDart = int Function(int, Pointer<_HiddAttributes>);

typedef _SetupDiGetClassDevsC = IntPtr Function(
    Pointer<_Guid>, Pointer<Utf16>, IntPtr, Uint32);
typedef _SetupDiGetClassDevsDart = int Function(
    Pointer<_Guid>, Pointer<Utf16>, int, int);

typedef _SetupDiEnumC = Int32 Function(IntPtr, Pointer<Void>, Pointer<_Guid>,
    Uint32, Pointer<_SpDeviceInterfaceData>);
typedef _SetupDiEnumDart = int Function(
    int, Pointer<Void>, Pointer<_Guid>, int, Pointer<_SpDeviceInterfaceData>);

typedef _SetupDiGetDetailC = Int32 Function(
    IntPtr,
    Pointer<_SpDeviceInterfaceData>,
    Pointer<Void>,
    Uint32,
    Pointer<Uint32>,
    Pointer<Void>);
typedef _SetupDiGetDetailDart = int Function(
    int,
    Pointer<_SpDeviceInterfaceData>,
    Pointer<Void>,
    int,
    Pointer<Uint32>,
    Pointer<Void>);

typedef _SetupDiDestroyC = Int32 Function(IntPtr);
typedef _SetupDiDestroyDart = int Function(int);

typedef _CreateFileC = IntPtr Function(
    Pointer<Utf16>, Uint32, Uint32, Pointer<Void>, Uint32, Uint32, IntPtr);
typedef _CreateFileDart = int Function(
    Pointer<Utf16>, int, int, Pointer<Void>, int, int, int);

typedef _WriteFileC = Int32 Function(
    IntPtr, Pointer<Uint8>, Uint32, Pointer<Uint32>, Pointer<Void>);
typedef _WriteFileDart = int Function(
    int, Pointer<Uint8>, int, Pointer<Uint32>, Pointer<Void>);

typedef _CloseHandleC = Int32 Function(IntPtr);
typedef _CloseHandleDart = int Function(int);

final DynamicLibrary _hid = DynamicLibrary.open('hid.dll');
final DynamicLibrary _setupapi = DynamicLibrary.open('setupapi.dll');
final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');

final _hidDGetHidGuid = _hid
    .lookupFunction<_HidDGetHidGuidC, _HidDGetHidGuidDart>('HidD_GetHidGuid');
final _hidDGetAttributes =
    _hid.lookupFunction<_HidDGetAttributesC, _HidDGetAttributesDart>(
        'HidD_GetAttributes');
final _setupDiGetClassDevs =
    _setupapi.lookupFunction<_SetupDiGetClassDevsC, _SetupDiGetClassDevsDart>(
        'SetupDiGetClassDevsW');
final _setupDiEnum = _setupapi.lookupFunction<_SetupDiEnumC, _SetupDiEnumDart>(
    'SetupDiEnumDeviceInterfaces');
final _setupDiGetDetail =
    _setupapi.lookupFunction<_SetupDiGetDetailC, _SetupDiGetDetailDart>(
        'SetupDiGetDeviceInterfaceDetailW');
final _setupDiDestroy =
    _setupapi.lookupFunction<_SetupDiDestroyC, _SetupDiDestroyDart>(
        'SetupDiDestroyDeviceInfoList');
final _createFile =
    _kernel32.lookupFunction<_CreateFileC, _CreateFileDart>('CreateFileW');
final _writeFile =
    _kernel32.lookupFunction<_WriteFileC, _WriteFileDart>('WriteFile');
final _closeHandle =
    _kernel32.lookupFunction<_CloseHandleC, _CloseHandleDart>('CloseHandle');

class UsbHidBadgeTransport extends BadgeTransport {
  static const int badgeVid = 0x0416;
  static const int badgePid = 0x5020;

  static const int reportLength = 65;
  static const int reportDataLength = reportLength - 1;

  final Logger logger = Logger();

  @override
  BadgeTransportType get type => BadgeTransportType.usb;

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isWindows) return false;
    return _findBadgePath() != null;
  }

  @override
  Future<void> send(DataTransferManager manager) async {
    if (!Platform.isWindows) {
      throw BadgeTransportException('USB is only supported on Windows.');
    }

    final path = _findBadgePath();
    if (path == null) {
      throw BadgeTransportException(
          'No USB badge found. Please check the cable and try again.');
    }

    final chunks = await manager.generateDataChunk();
    final payload = <int>[for (final chunk in chunks) ...chunk];

    await _writeToBadge(path, payload);
  }

  String? _findBadgePath() {
    final hidGuid = calloc<_Guid>();
    _hidDGetHidGuid(hidGuid);

    final devInfo = _setupDiGetClassDevs(
      hidGuid,
      nullptr,
      0,
      _digcfPresent | _digcfDeviceInterface,
    );
    if (devInfo == _invalidHandle) {
      calloc.free(hidGuid);
      return null;
    }

    final interfaceData = calloc<_SpDeviceInterfaceData>();
    interfaceData.ref.cbSize = sizeOf<_SpDeviceInterfaceData>();

    String? foundPath;
    var index = 0;
    try {
      while (
          _setupDiEnum(devInfo, nullptr, hidGuid, index, interfaceData) != 0) {
        index++;

        final requiredSize = calloc<Uint32>();
        _setupDiGetDetail(
            devInfo, interfaceData, nullptr, 0, requiredSize, nullptr);

        final detail = calloc<Uint8>(requiredSize.value);
        detail.cast<Uint32>().value = sizeOf<IntPtr>() == 8 ? 8 : 6;

        final ok = _setupDiGetDetail(
          devInfo,
          interfaceData,
          detail.cast(),
          requiredSize.value,
          nullptr,
          nullptr,
        );

        if (ok != 0) {
          final pathPtr = Pointer<Utf16>.fromAddress(detail.address + 4);
          if (_matchesBadge(pathPtr)) {
            foundPath = pathPtr.toDartString();
          }
        }

        calloc.free(detail);
        calloc.free(requiredSize);

        if (foundPath != null) break;
      }
    } finally {
      calloc.free(interfaceData);
      calloc.free(hidGuid);
      _setupDiDestroy(devInfo);
    }

    return foundPath;
  }

  bool _matchesBadge(Pointer<Utf16> pathPtr) {
    final handle = _createFile(
      pathPtr,
      0,
      _fileShareRead | _fileShareWrite,
      nullptr,
      _openExisting,
      0,
      0,
    );
    if (handle == _invalidHandle) return false;

    final attrs = calloc<_HiddAttributes>();
    attrs.ref.size = sizeOf<_HiddAttributes>();
    var matches = false;
    if (_hidDGetAttributes(handle, attrs) != 0) {
      matches =
          attrs.ref.vendorId == badgeVid && attrs.ref.productId == badgePid;
    }
    calloc.free(attrs);
    _closeHandle(handle);
    return matches;
  }

  Future<void> _writeToBadge(String path, List<int> payload) async {
    final pathPtr = path.toNativeUtf16();
    final handle = _createFile(
      pathPtr,
      _genericWrite,
      _fileShareRead | _fileShareWrite,
      nullptr,
      _openExisting,
      0,
      0,
    );

    if (handle == _invalidHandle) {
      calloc.free(pathPtr);
      throw BadgeTransportException(
          'Failed to open the USB badge for writing.');
    }

    final buffer = calloc<Uint8>(reportLength);
    final bufferList = buffer.asTypedList(reportLength);
    final bytesWritten = calloc<Uint32>();

    try {
      for (var offset = 0;
          offset < payload.length;
          offset += reportDataLength) {
        bufferList.fillRange(0, reportLength, 0);
        final end = (offset + reportDataLength) < payload.length
            ? offset + reportDataLength
            : payload.length;
        for (var i = offset; i < end; i++) {
          bufferList[i - offset + 1] = payload[i] & 0xFF;
        }

        final ok =
            _writeFile(handle, buffer, reportLength, bytesWritten, nullptr);
        if (ok == 0 || bytesWritten.value != reportLength) {
          throw BadgeTransportException(
              'Failed to transfer data to the USB badge.');
        }

        await Future.delayed(const Duration(milliseconds: 50));
      }
      logger.d('USB HID transfer complete: ${payload.length} bytes');
    } finally {
      calloc.free(buffer);
      calloc.free(bytesWritten);
      _closeHandle(handle);
      calloc.free(pathPtr);
    }
  }
}
