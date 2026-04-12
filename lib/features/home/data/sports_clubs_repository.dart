import '../models/sports_club.dart';

class SportsClubsRepository {
  Future<List<SportsClub>> fetchAvailableClubs() async {
    // TODO(eventum-clubs): Replace mock list with API request.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const [
      SportsClub(
        id: '1',
        name: 'Spartak Junior',
        city: 'Москва',
        district: 'ЦАО',
        sport: 'Футбол',
        minAge: 8,
        maxAge: 14,
        address: 'ул. Красная Пресня, 21',
        description: 'Тренировки 3 раза в неделю, участие в городских лигах.',
        latitude: 55.7601,
        longitude: 37.5739,
      ),
      SportsClub(
        id: '2',
        name: 'North Swim Club',
        city: 'Москва',
        district: 'САО',
        sport: 'Плавание',
        minAge: 7,
        maxAge: 16,
        address: 'Ленинградский пр-т, 64',
        description: 'Группы для начинающих и продвинутых, подготовка к стартам.',
        latitude: 55.7994,
        longitude: 37.5315,
      ),
      SportsClub(
        id: '3',
        name: 'Volley Arena',
        city: 'Санкт-Петербург',
        district: 'Приморский',
        sport: 'Волейбол',
        minAge: 10,
        maxAge: 17,
        address: 'ул. Савушкина, 112',
        description: 'Секции для юношей и девушек, турниры по выходным.',
        latitude: 59.9921,
        longitude: 30.2121,
      ),
      SportsClub(
        id: '4',
        name: 'Go Fight Academy',
        city: 'Казань',
        district: 'Вахитовский',
        sport: 'Единоборства',
        minAge: 12,
        maxAge: 21,
        address: 'ул. Баумана, 8',
        description: 'Бокс, ММА и ОФП под руководством сертифицированных тренеров.',
        latitude: 55.7906,
        longitude: 49.1146,
      ),
      SportsClub(
        id: '5',
        name: 'Ace Tennis',
        city: 'Екатеринбург',
        district: 'Ленинский',
        sport: 'Теннис',
        minAge: 6,
        maxAge: 15,
        address: 'ул. Малышева, 55',
        description: 'Индивидуальные и групповые занятия, летние сборы.',
        latitude: 56.8328,
        longitude: 60.6153,
      ),
    ];
  }
}
