import 'package:flutter/material.dart';

/// Slim l10n for current Eventum Clubs features.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const _localizedValues = <String, Map<String, String>>{
    'ru': {
      'appTitle': 'Eventum Clubs',
      'registration': 'Регистрация',
      'login': 'Вход',
      'email': 'Email',
      'emailOrNick': 'Email или никнейм',
      'password': 'Пароль',
      'nickname': 'Никнейм',
      'firstName': 'Имя',
      'lastName': 'Фамилия',
      'city': 'Город',
      'next': 'Далее',
      'back': 'Назад',
      'register': 'Зарегистрироваться',
      'noAccount': 'Нет аккаунта? Зарегистрироваться',
      'hasAccount': 'Уже есть аккаунт? Войти',
      'profile': 'Профиль',
      'editProfile': 'Редактировать профиль',
      'changePassword': 'Сменить пароль',
      'theme': 'Тема приложения',
      'themeDark': 'Тёмная',
      'themeLight': 'Светлая',
      'logout': 'Выйти',
      'language': 'Язык',
      'russian': 'Русский',
      'english': 'English',
      'cancel': 'Отмена',
      'save': 'Сохранить',
      'addPhoto': 'Добавить фото',
      'contactInfo': 'Контактная информация',
      'fillAllFields': 'Заполните все поля',
      'profileUpdated': 'Профиль обновлён',
      'currentPassword': 'Текущий пароль',
      'newPassword': 'Новый пароль',
      'repeatPassword': 'Повторите новый пароль',
      'fillPassword': 'Заполните текущий и новый пароль',
      'passwordMin6': 'Новый пароль минимум 6 символов',
      'passwordsDontMatch': 'Пароли не совпадают',
      'passwordChanged': 'Пароль изменён',
      'change': 'Сменить',
      'locationDisabled': 'Геолокация отключена',
      'locationDeniedForever': 'Доступ к геолокации запрещён',
      'locationDenied': 'Нет разрешения на геолокацию',
      'locationError': 'Не удалось получить локацию',
      'home': 'Клубы',
      'news': 'Новости',
      'newsPlaceholder':
          'Лента новостей появится здесь после подключения к серверу EVENTUM.',
      'map': 'Карта',
      'mapClubBriefHint': 'Нажмите, чтобы открыть расписание и подробности.',
      'mapGoToSchedule': 'Перейти к расписанию',
      'agreeToLicense': 'Я согласен с ',
      'licenseTermsLink': 'условиями лицензионного соглашения',
      'agreeToPrivacy': 'Я ознакомлен и принимаю ',
      'privacyPolicyLink': 'политику конфиденциальности',
      'confirmAdult': 'Мне исполнилось 18 лет',
      'apiConnectionFailed':
          'Сервер не отвечает. Запустите EVENTUM API на порту 4000. На телефоне/эмуляторе вместо localhost укажите IP компьютера.',
      'genericNetworkError': 'Ошибка сети. Попробуйте позже.',
      'errorServerTryAgain': 'Не удалось выполнить действие. Попробуйте позже.',
      'errorUnauthorized': 'Войдите в аккаунт снова или проверьте пароль.',
      'errorInvalidCredentials': 'Неверный email/ник или пароль.',
      'errorEmailTaken': 'Этот email уже занят.',
      'errorUsernameTaken': 'Этот никнейм уже занят.',
      'errorConflict': 'Данные конфликтуют с существующей записью.',
      'errorValidation': 'Проверьте введённые данные.',
      'inviteInvalidLoginOrEmail': 'Введите корректный никнейм или email.',
      'errorAccountBlocked':
          'Аккаунт заблокирован. Обратитесь в поддержку, если это ошибка.',
      'blockedUserBadge': 'Заблокирован',
      'clubAbout': 'О клубе',
      'clubCoaches': 'Тренерский состав',
      'clubSchedule': 'Расписание',
      'clubOpenInMaps': 'Открыть в Яндекс.Картах',
      'clubEnrollTraining': 'Записаться на тренировку',
      'clubEnrollComingSoon':
          'Онлайн-запись скоро появится. Свяжитесь с клубом или дождитесь обновления приложения.',
      'clubEnrollSheetTitle': 'Выбор записи',
      'clubEnrollFreeFirst': 'Бесплатная первая тренировка',
      'clubEnrollFreeFirstSubtitle':
          'Ознакомительное занятие в этом клубе без оплаты абонемента',
      'clubEnrollPassSection': 'Абонемент',
      'clubEnrollNoPassesHint':
          'Список абонементов для клуба пока не загружен. Можно записаться на бесплатное занятие или уточнить варианты у клуба.',
      'clubEnrollContinue': 'Продолжить',
      'clubEnrollAckFree':
          'Выбрана бесплатная первая тренировка. Оформление в приложении скоро появится.',
      'clubEnrollAckPass':
          'Выбран абонемент «{name}». Оформление в приложении скоро появится.',
      'subscriptionDurationDays': '{n} дн.',
      'clubPassScopeClub': 'Конкретный зал',
      'clubPassScopeSport': 'Все залы вида спорта',
      'mySubscriptionsTitle': 'Мои абонементы',
      'subscriptionsEmpty': 'У вас пока нет оплаченных абонементов.',
      'subscriptionStatusActive': 'Активен',
      'subscriptionStatusExpired': 'Истёк',
      'subscriptionStatusCancelled': 'Отменён',
      'subscriptionClubNamed': 'Зал: {name}',
      'subscriptionSportNamed': 'Вид спорта: {name}',
      'subscriptionUntitled': 'Абонемент',
      'subscriptionAdminEndpointDenied':
          'Нет доступа к админскому API абонементов. Войдите под администратором или реализуйте GET /api/me/subscriptions для обычных пользователей.',
      'coachProfileTitle': 'Профиль тренера',
      'coachProfileHint':
          'Анкета в экосистеме EVENTUM. Можно привязать клуб и загрузить фото (сервер: /uploads/coaches).',
      'coachBioLabel': 'О себе',
      'coachClubLabel': 'Клуб',
      'coachClubNone': 'Не привязан',
      'coachSpecializationLabel': 'Специализация',
      'coachExperienceYearsLabel': 'Стаж (лет)',
      'coachProfileSaved': 'Анкета сохранена',
      'coachPhotoUpdated': 'Фото обновлено',
      'deleteAccountTitle': 'Удалить аккаунт',
      'deleteAccountBody':
          'Это действие необратимо. На сервере удаляются связанные данные (командная логика, заявки, абонементы и т.д.).',
      'deleteAccountPasswordHint': 'Текущий пароль (если требуется API)',
      'deleteAccountConfirm': 'Удалить навсегда',
      'clubNoCoaches': 'Состав уточняется у клуба.',
      'clubNoSchedule': 'Расписание пока не опубликовано.',
      'retry': 'Повторить',
      'clubDayMon': 'Пн',
      'clubDayTue': 'Вт',
      'clubDayWed': 'Ср',
      'clubDayThu': 'Чт',
      'clubDayFri': 'Пт',
      'clubDaySat': 'Сб',
      'clubDaySun': 'Вс',
    },
    'en': {
      'appTitle': 'Eventum Clubs',
      'registration': 'Registration',
      'login': 'Login',
      'email': 'Email',
      'emailOrNick': 'Email or nickname',
      'password': 'Password',
      'nickname': 'Nickname',
      'firstName': 'First name',
      'lastName': 'Last name',
      'city': 'City',
      'next': 'Next',
      'back': 'Back',
      'register': 'Register',
      'noAccount': "Don't have an account? Sign up",
      'hasAccount': 'Already have an account? Sign in',
      'profile': 'Profile',
      'editProfile': 'Edit profile',
      'changePassword': 'Change password',
      'theme': 'App theme',
      'themeDark': 'Dark',
      'themeLight': 'Light',
      'logout': 'Log out',
      'language': 'Language',
      'russian': 'Russian',
      'english': 'English',
      'cancel': 'Cancel',
      'save': 'Save',
      'addPhoto': 'Add photo',
      'contactInfo': 'Contact information',
      'fillAllFields': 'Fill in all fields',
      'profileUpdated': 'Profile updated',
      'currentPassword': 'Current password',
      'newPassword': 'New password',
      'repeatPassword': 'Repeat new password',
      'fillPassword': 'Fill in current and new password',
      'passwordMin6': 'New password must be at least 6 characters',
      'passwordsDontMatch': "Passwords don't match",
      'passwordChanged': 'Password changed',
      'change': 'Change',
      'locationDisabled': 'Location services disabled',
      'locationDeniedForever': 'Location access denied permanently',
      'locationDenied': 'No location permission',
      'locationError': 'Failed to get location',
      'home': 'Clubs',
      'news': 'News',
      'newsPlaceholder':
          'The news feed will appear here once connected to the EVENTUM API.',
      'map': 'Map',
      'mapClubBriefHint': 'Open for full schedule and details.',
      'mapGoToSchedule': 'Go to schedule',
      'agreeToLicense': 'I agree with the ',
      'licenseTermsLink': 'license agreement terms',
      'agreeToPrivacy': 'I have read and accept the ',
      'privacyPolicyLink': 'privacy policy',
      'confirmAdult': 'I am 18 years of age or older',
      'apiConnectionFailed':
          'Cannot reach the server. Start the EVENTUM API on port 4000. On a device/emulator use your computer IP instead of localhost.',
      'genericNetworkError': 'Network error. Please try again.',
      'errorServerTryAgain': 'Something went wrong. Please try again.',
      'errorUnauthorized': 'Sign in again or check your password.',
      'errorInvalidCredentials': 'Wrong email/username or password.',
      'errorEmailTaken': 'This email is already registered.',
      'errorUsernameTaken': 'This nickname is already taken.',
      'errorConflict': 'This conflicts with existing data.',
      'errorValidation': 'Please check your input.',
      'inviteInvalidLoginOrEmail': 'Enter a valid username or email.',
      'errorAccountBlocked':
          'This account is blocked. Contact support if this is a mistake.',
      'blockedUserBadge': 'Blocked',
      'clubAbout': 'About',
      'clubCoaches': 'Coaches',
      'clubSchedule': 'Schedule',
      'clubOpenInMaps': 'Open in Yandex Maps',
      'clubEnrollTraining': 'Book a training session',
      'clubEnrollComingSoon':
          'Online booking is coming soon. Contact the club directly or wait for an app update.',
      'clubEnrollSheetTitle': 'Booking option',
      'clubEnrollFreeFirst': 'Free first session',
      'clubEnrollFreeFirstSubtitle':
          'A complimentary trial class at this club without buying a pass',
      'clubEnrollPassSection': 'Membership / pass',
      'clubEnrollNoPassesHint':
          'Passes for this club are not loaded yet. You can book a free trial or ask the club for options.',
      'clubEnrollContinue': 'Continue',
      'clubEnrollAckFree':
          'Free first session selected. In-app checkout will be available soon.',
      'clubEnrollAckPass':
          'Pass «{name}» selected. In-app checkout will be available soon.',
      'subscriptionDurationDays': '{n} days',
      'clubPassScopeClub': 'Specific venue',
      'clubPassScopeSport': 'All venues for this sport',
      'mySubscriptionsTitle': 'My passes',
      'subscriptionsEmpty': 'You have no purchased passes yet.',
      'subscriptionStatusActive': 'Active',
      'subscriptionStatusExpired': 'Expired',
      'subscriptionStatusCancelled': 'Cancelled',
      'subscriptionClubNamed': 'Club: {name}',
      'subscriptionSportNamed': 'Sport: {name}',
      'subscriptionUntitled': 'Pass',
      'subscriptionAdminEndpointDenied':
          'No access to the admin subscriptions API. Sign in as admin or add GET /api/me/subscriptions for regular users.',
      'coachProfileTitle': 'Coach profile',
      'coachProfileHint':
          'Your coach profile in the EVENTUM ecosystem. Link a club and upload a photo (server: /uploads/coaches).',
      'coachBioLabel': 'About you',
      'coachClubLabel': 'Club',
      'coachClubNone': 'Not linked',
      'coachSpecializationLabel': 'Specialization',
      'coachExperienceYearsLabel': 'Years of experience',
      'coachProfileSaved': 'Profile saved',
      'coachPhotoUpdated': 'Photo updated',
      'deleteAccountTitle': 'Delete account',
      'deleteAccountBody':
          'This cannot be undone. The server removes related data (teams, registrations, subscriptions, etc.).',
      'deleteAccountPasswordHint': 'Current password (if required by API)',
      'deleteAccountConfirm': 'Delete permanently',
      'clubNoCoaches': 'Coach list is not available yet.',
      'clubNoSchedule': 'Schedule has not been published yet.',
      'retry': 'Retry',
      'clubDayMon': 'Mon',
      'clubDayTue': 'Tue',
      'clubDayWed': 'Wed',
      'clubDayThu': 'Thu',
      'clubDayFri': 'Fri',
      'clubDaySat': 'Sat',
      'clubDaySun': 'Sun',
    },
  };

  String _get(String key) => _localizedValues[locale.languageCode]?[key] ?? key;

  String get appTitle => _get('appTitle');
  String get registration => _get('registration');
  String get login => _get('login');
  String get email => _get('email');
  String get emailOrNick => _get('emailOrNick');
  String get password => _get('password');
  String get nickname => _get('nickname');
  String get firstName => _get('firstName');
  String get lastName => _get('lastName');
  String get city => _get('city');
  String get next => _get('next');
  String get back => _get('back');
  String get register => _get('register');
  String get noAccount => _get('noAccount');
  String get hasAccount => _get('hasAccount');
  String get profile => _get('profile');
  String get editProfile => _get('editProfile');
  String get changePassword => _get('changePassword');
  String get theme => _get('theme');
  String get themeDark => _get('themeDark');
  String get themeLight => _get('themeLight');
  String get logout => _get('logout');
  String get language => _get('language');
  String get russian => _get('russian');
  String get english => _get('english');
  String get cancel => _get('cancel');
  String get save => _get('save');
  String get addPhoto => _get('addPhoto');
  String get contactInfo => _get('contactInfo');
  String get fillAllFields => _get('fillAllFields');
  String get profileUpdated => _get('profileUpdated');
  String get currentPassword => _get('currentPassword');
  String get newPassword => _get('newPassword');
  String get repeatPassword => _get('repeatPassword');
  String get fillPassword => _get('fillPassword');
  String get passwordMin6 => _get('passwordMin6');
  String get passwordsDontMatch => _get('passwordsDontMatch');
  String get passwordChanged => _get('passwordChanged');
  String get change => _get('change');
  String get locationDisabled => _get('locationDisabled');
  String get locationDeniedForever => _get('locationDeniedForever');
  String get locationDenied => _get('locationDenied');
  String get locationError => _get('locationError');
  String get home => _get('home');
  String get news => _get('news');
  String get newsPlaceholder => _get('newsPlaceholder');
  String get map => _get('map');
  String get mapClubBriefHint => _get('mapClubBriefHint');
  String get mapGoToSchedule => _get('mapGoToSchedule');
  String get agreeToLicense => _get('agreeToLicense');
  String get licenseTermsLink => _get('licenseTermsLink');
  String get agreeToPrivacy => _get('agreeToPrivacy');
  String get privacyPolicyLink => _get('privacyPolicyLink');
  String get confirmAdult => _get('confirmAdult');
  String get apiConnectionFailed => _get('apiConnectionFailed');
  String get genericNetworkError => _get('genericNetworkError');
  String get errorServerTryAgain => _get('errorServerTryAgain');
  String get errorUnauthorized => _get('errorUnauthorized');
  String get errorInvalidCredentials => _get('errorInvalidCredentials');
  String get errorEmailTaken => _get('errorEmailTaken');
  String get errorUsernameTaken => _get('errorUsernameTaken');
  String get errorConflict => _get('errorConflict');
  String get errorValidation => _get('errorValidation');
  String get inviteInvalidLoginOrEmail => _get('inviteInvalidLoginOrEmail');
  String get errorAccountBlocked => _get('errorAccountBlocked');
  String get blockedUserBadge => _get('blockedUserBadge');
  String get clubAbout => _get('clubAbout');
  String get clubCoaches => _get('clubCoaches');
  String get clubSchedule => _get('clubSchedule');
  String get clubOpenInMaps => _get('clubOpenInMaps');
  String get clubEnrollTraining => _get('clubEnrollTraining');
  String get clubEnrollComingSoon => _get('clubEnrollComingSoon');
  String get clubEnrollSheetTitle => _get('clubEnrollSheetTitle');
  String get clubEnrollFreeFirst => _get('clubEnrollFreeFirst');
  String get clubEnrollFreeFirstSubtitle => _get('clubEnrollFreeFirstSubtitle');
  String get clubEnrollPassSection => _get('clubEnrollPassSection');
  String get clubEnrollNoPassesHint => _get('clubEnrollNoPassesHint');
  String get clubEnrollContinue => _get('clubEnrollContinue');
  String get clubEnrollAckFree => _get('clubEnrollAckFree');
  String clubEnrollAckPass(String name) =>
      _get('clubEnrollAckPass').replaceAll('{name}', name);
  String subscriptionDurationDays(int n) =>
      _get('subscriptionDurationDays').replaceAll('{n}', '$n');
  String get clubPassScopeClub => _get('clubPassScopeClub');
  String get clubPassScopeSport => _get('clubPassScopeSport');
  String get mySubscriptionsTitle => _get('mySubscriptionsTitle');
  String get subscriptionsEmpty => _get('subscriptionsEmpty');
  String get subscriptionStatusActive => _get('subscriptionStatusActive');
  String get subscriptionStatusExpired => _get('subscriptionStatusExpired');
  String get subscriptionStatusCancelled =>
      _get('subscriptionStatusCancelled');
  String subscriptionClubNamed(String name) =>
      _get('subscriptionClubNamed').replaceAll('{name}', name);
  String subscriptionSportNamed(String name) =>
      _get('subscriptionSportNamed').replaceAll('{name}', name);
  String get subscriptionUntitled => _get('subscriptionUntitled');
  String get subscriptionAdminEndpointDenied =>
      _get('subscriptionAdminEndpointDenied');
  String get coachProfileTitle => _get('coachProfileTitle');
  String get coachProfileHint => _get('coachProfileHint');
  String get coachBioLabel => _get('coachBioLabel');
  String get coachClubLabel => _get('coachClubLabel');
  String get coachClubNone => _get('coachClubNone');
  String get coachSpecializationLabel => _get('coachSpecializationLabel');
  String get coachExperienceYearsLabel => _get('coachExperienceYearsLabel');
  String get coachProfileSaved => _get('coachProfileSaved');
  String get coachPhotoUpdated => _get('coachPhotoUpdated');
  String get deleteAccountTitle => _get('deleteAccountTitle');
  String get deleteAccountBody => _get('deleteAccountBody');
  String get deleteAccountPasswordHint => _get('deleteAccountPasswordHint');
  String get deleteAccountConfirm => _get('deleteAccountConfirm');
  String get clubNoCoaches => _get('clubNoCoaches');
  String get clubNoSchedule => _get('clubNoSchedule');
  String get retry => _get('retry');
  String get clubDayMon => _get('clubDayMon');
  String get clubDayTue => _get('clubDayTue');
  String get clubDayWed => _get('clubDayWed');
  String get clubDayThu => _get('clubDayThu');
  String get clubDayFri => _get('clubDayFri');
  String get clubDaySat => _get('clubDaySat');
  String get clubDaySun => _get('clubDaySun');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ru', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
