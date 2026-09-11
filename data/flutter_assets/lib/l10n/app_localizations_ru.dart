// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Badge Magic';

  @override
  String get create => 'Create';

  @override
  String get checkApacheLicense =>
      'Ознакомьтесь с условиями лицензии Apache 2.0, применяемой к';

  @override
  String get saveButton => 'Сохранить';

  @override
  String get save => 'Сохранить';

  @override
  String get savedBadges => 'Сохранённые бейджи';

  @override
  String get savedBadgesTitle => 'Сохранённые бейджи';

  @override
  String get drawClipart => 'Нарисовать клипарт';

  @override
  String get drawClipartTitle => 'Нарисовать клипарт';

  @override
  String get transferButton => 'Перенести';

  @override
  String get settings => 'Настройки';

  @override
  String get language => 'Язык';

  @override
  String get selectBadge => 'Выбрать бейдж';

  @override
  String get english => 'Английский';

  @override
  String get hindi => 'Хинди';

  @override
  String get italian => 'Итальянский';

  @override
  String get russian => 'Русский';

  @override
  String get cancel => 'Отмена';

  @override
  String get overwrite => 'Перезаписать';

  @override
  String get badgeNameExists => 'Название бейджа уже используется';

  @override
  String get similarBadgeNameExists => 'Найден бейдж с похожим названием';

  @override
  String badgeNameExistsMessage(Object badgeName) {
    return 'Уже существует бейдж с таким названием: \'$badgeName\'. Хотите его перезаписать?';
  }

  @override
  String similarBadgeNameMessage(Object badgeName) {
    return 'Уже существует бейдж с похожим названием: \'$badgeName\'. Хотите его перезаписать?';
  }

  @override
  String get delete => 'Удалить';

  @override
  String get areYouSure => 'Вы уверены?';

  @override
  String get deleteConfirmation =>
      'Это действие нельзя отменить. Хотите продолжить?';

  @override
  String get deleteBadgeConfirmation => 'Вы точно хотите удалить этот бейдж?';

  @override
  String get error => 'Ошибка';

  @override
  String get success => 'Успех';

  @override
  String get saved => 'Сохранено';

  @override
  String get loading => 'Загрузка...';

  @override
  String get noBadgesFound => 'Бейджи не найдены';

  @override
  String get noClipartFound => 'Клипарты не найдены';

  @override
  String get import => 'Импортировать';

  @override
  String get export => 'Экспортировать';

  @override
  String get about => 'О приложении';

  @override
  String get version => 'Версия';

  @override
  String get createBadges => 'Создать бейджи';

  @override
  String get savedCliparts => 'Сохраненные клипарты';

  @override
  String get aboutUs => 'О нас';

  @override
  String get other => 'Другое';

  @override
  String get shareApp => 'Поделиться приложением';

  @override
  String get rateUs => 'Оценить приложение';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get termsOfService => 'Условия предоставления услуг';

  @override
  String get contactUs => 'Связаться с нами';

  @override
  String get buyBadge => 'Купить бейдж';

  @override
  String get feedbackBugReports => 'Отзывы/Сообщения об ошибках';

  @override
  String get shareAppText =>
      'Badge Magic — это приложение для управления светодиодными именными бейджами. Оно позволяет отображать на светодиодных бейджах имена, графические изображения и простые анимации. Вы также можете скачать его по ссылке ниже: https://play.google.com/store/apps/details?id=org.fossasia.badgemagic';

  @override
  String get noSavedClipart => 'Нет сохраненных клипартов!';

  @override
  String get noSavedClipartMessage => 'Похоже, сохраненных клипартов пока нет.';

  @override
  String get savedClipartTitle => 'Сохраненные клипарты';

  @override
  String get aboutBadgeMagic =>
      'Badge Magic — это приложение для управления светодиодными именными бейджами. Оно позволяет отображать на светодиодных бейджах имена, графические изображения и простые анимации. Для передачи данных со смартфона на светодиодный бейдж используется Bluetooth. Проект основан на разработке Nihlcem.';

  @override
  String get developedBy => 'Разработано';

  @override
  String get fossasiaContributors => 'Контрибьюторы FOSSASIA';

  @override
  String get contactWithUs => 'Связаться с нами';

  @override
  String get license => 'Лицензия';

  @override
  String get appLicense => 'Лицензия на приложение (Apache 2.0)';

  @override
  String get openSourceLicenses => 'Лицензии на ПО с открытым исходным кодом';

  @override
  String get openSourceLicensesDescription =>
      'Просмотреть лицензии библиотек с открытым исходным кодом, используемых в этом приложении.';

  @override
  String get speed => 'Скорость';

  @override
  String get speedTitle => 'Скорость';

  @override
  String get animation => 'Анимация';

  @override
  String get animationSplitting => 'Разделение';

  @override
  String get transition => 'Переход';

  @override
  String get transitionTitle => 'Переход';

  @override
  String get effects => 'Эффекты';

  @override
  String get effectsTitle => 'Эффекты';

  @override
  String get effectsTab => 'Эффекты';

  @override
  String get pacman => 'Pacman';

  @override
  String get chevron => 'Шеврон';

  @override
  String get diamond => 'Бриллиант';

  @override
  String get brokenHearts => 'Разбитые сердца';

  @override
  String get cupid => 'Купидон';

  @override
  String get feet => 'Футы';

  @override
  String get fishKiss => 'Рыбий поцелуй';

  @override
  String get diagonal => 'Диагональ';

  @override
  String get emergency => 'Экстренная ситуация';

  @override
  String get beatingHearts => 'Бьющиеся сердца';

  @override
  String get fireworks => 'Фейерверк';

  @override
  String get equalizer => 'Эквалайзер';

  @override
  String get switchToSpecialAnimation =>
      'Переключиться на специальную анимацию?';

  @override
  String get specialAnimationWarning =>
      'При выборе этой анимации текущий текст будет перезаписан.';

  @override
  String get copyText => 'Копировать текст';

  @override
  String get textCopied => 'Текст скопирован в буфер обмена!';

  @override
  String get githubDescription =>
      'Сделайте форк репозитория и отправьте изменения или сообщите о новой проблеме.';

  @override
  String get github => 'GitHub';

  @override
  String get editingBadge => 'Редактирование бейджа';

  @override
  String get failedToLoadBadgeData => 'Не удалось загрузить данные о бейдже';

  @override
  String get saveBadge => 'Сохранить бейдж';

  @override
  String get fileName => 'Имя файла';

  @override
  String get createNewBadge => 'Создать новый бейдж';

  @override
  String get enterTextHere => 'Введите текст здесь...';

  @override
  String get applyEffects => 'Применить эффекты';

  @override
  String get preview => 'Предварительный просмотр';

  @override
  String get sendToBadge => 'Отправить на бейдж';

  @override
  String get savedSuccessfully => 'Сохранено успешно!';

  @override
  String get errorSaving => 'Ошибка при сохранении бейджа';

  @override
  String get enterBadgeName => 'Введите название бейджа';

  @override
  String get invertEffect => 'Инверсия';

  @override
  String get invertTitle => 'Инверсия';

  @override
  String get fixedAnimation => 'Исправлено';

  @override
  String get fixedTitle => 'Исправлено';

  @override
  String get flashEffect => 'Вспышка';

  @override
  String get marqueeEffect => 'Рамка';

  @override
  String get slow => 'Медленно';

  @override
  String get normal => 'Нормально';

  @override
  String get fast => 'Быстро';

  @override
  String get veryFast => 'Очень быстро';

  @override
  String get selectLanguage => 'Выбрать язык';

  @override
  String get selectBadgeType => 'Выбрать тип бейджа';

  @override
  String get badgeTypeLsled => 'LS LED';

  @override
  String get badgeTypeVblab => 'VB Lab';

  @override
  String get aboutApp => 'О Badge Magic';

  @override
  String get appDescription =>
      'Создавайте и настраивайте тексты для светодиодных бейджей – легко и быстро. Разрабатывайте, сохраняйте и делитесь своими проектами.';

  @override
  String get allRightsReserved => 'Все права защищены';

  @override
  String get ok => 'ОК';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get back => 'Назад';

  @override
  String get next => 'Дальше';

  @override
  String get done => 'Готово';

  @override
  String get left => 'Влево';

  @override
  String get right => 'Вправо';

  @override
  String get up => 'Вверх';

  @override
  String get down => 'Вниз';

  @override
  String get fixed => 'Исправлено';

  @override
  String get snowflake => 'Снежинки';

  @override
  String get picture => 'Картинка';

  @override
  String get laser => 'Лазер';

  @override
  String get wipe => 'Стереть';

  @override
  String get inText => 'В';

  @override
  String get outText => 'Из';

  @override
  String get animationLeft => 'Влево';

  @override
  String get animationRight => 'Вправо';

  @override
  String get animationUp => 'Вверх';

  @override
  String get animationDown => 'Вниз';

  @override
  String get animationFixed => 'Исправлено';

  @override
  String get animationSnowflake => 'Снежинки';

  @override
  String get animationPicture => 'Картинка';

  @override
  String get animationLaser => 'Лазер';

  @override
  String get deleteSelected => 'Удалить выбранные';

  @override
  String get badgeImportedSuccessfully => 'Бейдж успешно импортирован';

  @override
  String get draw => 'Рисовать';

  @override
  String get erase => 'Стереть';

  @override
  String get reset => 'Сброс';

  @override
  String get clipartSavedSuccessfully => 'Клипарт успешно сохранен';

  @override
  String get failedToSaveBadge => 'Не удалось сохранить бейдж';

  @override
  String get transfer => 'Перенести';

  @override
  String get pleaseEnterMessage => 'Введите текст сообщения';

  @override
  String get badgeUpdatedSuccessfully => 'Бейдж успешно обновлен';

  @override
  String get badgeExistsMessage =>
      'Бейдж с таким названием уже существует. Что вы хотите сделать?';

  @override
  String get similarBadgeExists => 'Найден бейдж с похожим названием';

  @override
  String similarBadgeExistsMessage(Object badgeName) {
    return 'Уже существует бейдж с похожим названием: \'$badgeName\'. Что вы хотите сделать?';
  }

  @override
  String get enterNewBadgeName =>
      'Введите, пожалуйста, название нового бейджа.';

  @override
  String get deleteSelectedBadges => 'Удалить выбранные бейджи';

  @override
  String get deleteBadgesConfirmation =>
      'Вы точно хотите удалить выбранные бейджи?';

  @override
  String get transferBadge => 'Перенести бейдж';

  @override
  String get transferConfirmation =>
      'Вы уверены, что хотите перенести бейдж на устройство?';

  @override
  String get editBadge => 'Редактировать бейдж';

  @override
  String get editBadgeConfirmation => 'Хотите отредактировать этот бейдж?';

  @override
  String get badgesDeletedSuccessfully => 'Выбранные значки успешно удалены';

  @override
  String get pleaseEnterNewBadgeName =>
      'Введите, пожалуйста, название нового бейджа.';

  @override
  String get badgeSavedSuccessfully => 'Бейдж успешно сохранен';

  @override
  String get badgeName => 'Название бейджа';

  @override
  String get invertColors => 'Инвертировать цвета';

  @override
  String get badge => 'Бейдж';

  @override
  String get shapes => 'Фигуры';

  @override
  String get free => 'Бесплатно';

  @override
  String get square => 'Квадрат';

  @override
  String get rectangle => 'Прямоугольник';

  @override
  String get circle => 'Круг';

  @override
  String get connectToBadgesWithNames =>
      'Подключиться к бейджам со следующими названиями';

  @override
  String get selectAll => 'Выбрать все';

  @override
  String get clearAll => 'Очистить всё';

  @override
  String get addMore => 'Добавить ещё';

  @override
  String get scanSettingsSaved => 'Настройки сканирования сохранены';

  @override
  String get saveSettings => 'Сохранить настройки';

  @override
  String get connectToAnyBadge => 'Подключиться к любому бейджу';

  @override
  String get badgeNameHint => 'Название бейджа';

  @override
  String get triangle => 'Треугольник';

  @override
  String get badgeScanMode => 'Режим сканирования бейджей';

  @override
  String get pleaseSelectClipart =>
      'Перед сохранением нарисуйте или выберите клипарт';

  @override
  String get searchingDeviceBLE => 'Searching for device...';

  @override
  String get turnOnBluetoothMessage => 'Please turn on Bluetooth';

  @override
  String get connexionFailed => 'Failed to connect. Retrying...';

  @override
  String get connectionSucceeded => 'Device connected successfully';

  @override
  String get scanError => 'Scan error occurred';

  @override
  String get deviceFound => 'Device found. Connecting...';

  @override
  String get transferFailed => 'Transfer failed, please try again';

  @override
  String get transferAborted => 'Transfer aborted';

  @override
  String get transferSucceeded => 'Data transferred successfully';

  @override
  String get noBLEServiceFound => 'Required BLE service not found on device';

  @override
  String get unknownError => 'Unknown Error';

  @override
  String get importFromFile => 'Импортировать из файла';

  @override
  String get scanQrCode => 'Отсканируйте QR-код';

  @override
  String get couldNotImportBadgeFromQr =>
      'Не удалось импортировать бейдж из QR-кода.';

  @override
  String get shareAsFile => 'Отправить как файл';

  @override
  String get shareViaQrCode => 'Поделиться через QR-код';

  @override
  String get scanBadgeQrCode => 'Отсканируйте QR-код бейджа';

  @override
  String get toggleTorch => 'Переключить фонарик';

  @override
  String get switchCamera => 'Переключить камеру';

  @override
  String get scanQrInstruction =>
      'Наведите камеру на QR-код бейджа, отправленный с другого устройства.';

  @override
  String get importFromImage => 'Импортировать из изображения';

  @override
  String get couldNotReadBadgeQr => 'Не удалось считать QR-код этого бейджа.';

  @override
  String get noBadgeQrInImage => 'На этом изображении не найден QR-код бейджа.';

  @override
  String get couldNotReadQrFromImage =>
      'Не удалось считать QR-код с этого изображения.';

  @override
  String get badgeTooLargeForQr =>
      'Этот бейдж слишком большой, чтобы поделиться им в виде QR-кода. Воспользуйтесь вместо этого функцией обмена файлами.';

  @override
  String get shareBadgeQrCode => 'Поделиться бейджем через QR-код';

  @override
  String get shareQrImage => 'Поделиться изображением QR-кода';

  @override
  String get couldNotGenerateQrImage =>
      'Не удалось создать изображение QR-кода.';

  @override
  String get couldNotShareQrImage =>
      'Не удалось поделиться изображением QR-кода.';

  @override
  String get qrShareInstruction =>
      'Отсканируйте этот код с другого устройства или нажмите «Поделиться», чтобы отправить изображение QR-кода.';

  @override
  String get renameBadge => 'Rename Badge';

  @override
  String get newName => 'New name';

  @override
  String get rename => 'Rename';

  @override
  String get badgeNameEmpty => 'Badge name cannot be empty.';

  @override
  String get badgeAlreadyExists => 'A badge with that name already exists.';

  @override
  String get couldNotRenameBadge =>
      'Could not rename the badge. Please try again.';

  @override
  String get badgeRenamedSuccessfully => 'Badge renamed successfully!';

  @override
  String get turnBLEOn => 'Please turn on Bluetooth in your settings';

  @override
  String get checkUpdateStartup =>
      'Check for badge firmware updates on startup';

  @override
  String get firmwareUpdate => 'Firmware Update';

  @override
  String get checkFirmwareUpdateButton => 'Check for Updates';

  @override
  String get newFirmwareVersionFound => 'New Firmware Available';

  @override
  String get dialogNewFirmwareVersionFound =>
      'A new firmware version is available for your badge.';

  @override
  String get dontRememberFirmwareVersionUpdate =>
      'Don\'t remind me again for this version';

  @override
  String get laterButton => 'Later';

  @override
  String get updateButton => 'Update';

  @override
  String get dismissButton => 'Dismiss';

  @override
  String get alreadyUpdatedStatusMessage => 'No new firmware versions found';

  @override
  String get checkFirmwareFailed =>
      'Firmware update check failed, please retry';

  @override
  String get notSupportedEmojis => 'System emojis are not supported';

  @override
  String get firmwareDownloadProgress => 'Firmware download in progress...';

  @override
  String get writingOnUsbIsp => 'Writing on USB ISP...';

  @override
  String flashUsbProgress(Object progress) {
    return 'Flash USB: $progress%';
  }

  @override
  String versionLabel(Object version) {
    return '• Version: $version';
  }

  @override
  String releasedLabel(Object date) {
    return '• Released: $date';
  }

  @override
  String get firmwareUpdateInstruction =>
      'Connect the badge via OTG cable in Bootloader mode (button pressed upon insertion)';

  @override
  String get flashViaUsb => 'Flash via USB';

  @override
  String removeWithCount(Object count) {
    return 'Remove ($count)';
  }

  @override
  String get firmwareUpdateSuccess => 'Firmware updated successfully via USB!';

  @override
  String get badgeIspNotFound =>
      'Badge ISP not found. Connect the ledtag with the boot button pressed.';

  @override
  String get usbPermissionDenied => 'USB permission denied by user';

  @override
  String get firmwareUpdateSuccessShort => 'Firmware updated successfully!';

  @override
  String get flashUsbConfirmationTitle => 'USB Flash Instructions';

  @override
  String get flashUsbInstructions =>
      'Connect the USB cable to the badge while clicking the button immediately above the USB port.';

  @override
  String get batteryDesolderedWarning =>
      'Note: The battery must be desoldered to perform this operation.';

  @override
  String get batteryDesolderedLink =>
      'Visit the official GitHub page for more details';

  @override
  String get doneButton => 'Start Flash';
}
