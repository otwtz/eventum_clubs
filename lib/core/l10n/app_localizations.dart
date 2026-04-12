import 'package:flutter/material.dart';

/// Slim l10n: auth, profile, home, shell, map, errors, language.
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
      'map': 'Карта',
      'homePenaltyGameTitle': 'Пенальти',
      'homePenaltyGameScore': 'Голы: {g} · Сейвы: {s}',
      'homePenaltyGameHint': 'Тапните по воротам, чтобы пробить.',
      'homePenaltyGameGoal': 'Гол!',
      'homePenaltyGameSave': 'Сейв!',
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
      'errorFavoriteFormatInvalid': 'Неверный формат избранного.',
      'errorPreferredFootInvalid': 'Укажите корректную рабочую ногу.',
      'errorStrongSidesRequired': 'Укажите сильные стороны (минимум одну).',
      'errorStatusesRequired': 'Выберите хотя бы один статус.',
      'errorCaptainRolePatch': 'Роль капитана нельзя изменить таким образом.',
      'inviteInvalidLoginOrEmail': 'Введите корректный никнейм или email.',
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
      'map': 'Map',
      'homePenaltyGameTitle': 'Penalty shootout',
      'homePenaltyGameScore': 'Goals: {g} · Saves: {s}',
      'homePenaltyGameHint': 'Tap the goal to shoot.',
      'homePenaltyGameGoal': 'Goal!',
      'homePenaltyGameSave': 'Save!',
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
      'errorFavoriteFormatInvalid': 'Invalid favorite format.',
      'errorPreferredFootInvalid': 'Invalid preferred foot.',
      'errorStrongSidesRequired': 'Select at least one strong side.',
      'errorStatusesRequired': 'Choose at least one status.',
      'errorCaptainRolePatch': 'Captain role cannot be changed this way.',
      'inviteInvalidLoginOrEmail': 'Enter a valid username or email.',
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
  String get map => _get('map');
  String get homePenaltyGameTitle => _get('homePenaltyGameTitle');
  String homePenaltyGameScore(int goals, int saves) =>
      _get('homePenaltyGameScore').replaceAll('{g}', '$goals').replaceAll('{s}', '$saves');
  String get homePenaltyGameHint => _get('homePenaltyGameHint');
  String get homePenaltyGameGoal => _get('homePenaltyGameGoal');
  String get homePenaltyGameSave => _get('homePenaltyGameSave');
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
  String get errorFavoriteFormatInvalid => _get('errorFavoriteFormatInvalid');
  String get errorPreferredFootInvalid => _get('errorPreferredFootInvalid');
  String get errorStrongSidesRequired => _get('errorStrongSidesRequired');
  String get errorStatusesRequired => _get('errorStatusesRequired');
  String get errorCaptainRolePatch => _get('errorCaptainRolePatch');
  String get inviteInvalidLoginOrEmail => _get('inviteInvalidLoginOrEmail');
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
