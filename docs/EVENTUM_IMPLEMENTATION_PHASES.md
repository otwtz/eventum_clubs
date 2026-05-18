# EVENTUM — этапы внедрения API в приложение

Бэкенд: `http://localhost:4000` (см. `--dart-define=API_BASE_URL=...` для устройства).

Формат авторизации приложения: `Authorization: Bearer <token>`.

---

## Клиентские фичи (актуально с бэкендом CoachProfile / ecosystem)

- [x] **Удаление аккаунта** — `DELETE /api/me`, опциональное тело `{ "password" }`; экран профиля → «Удалить аккаунт».
- [x] **Профиль тренера** — `GET /api/coach-profiles/me`, сохранение `PUT /api/coach-profiles/me` (при необходимости замените на `PATCH` в `PlayGoApiClient`), фото `POST /api/coach-profiles/me/photo` (multipart поле **`photo`**), статика `/uploads/coaches/*`.
- [x] **Экосистема** — `GET /api/ecosystem` (Bearer), клиент провайдер `ecosystemSnapshotProvider`; структура ответа — по договорённости с `routes/ecosystem.js`.
- [x] **Клубы** — списки ответов `coaches[]` поддерживают и строки, и объекты (в т.ч. вложенный `user`).
- Если пути на вашем сервере отличаются (camelCase vs kebab-case, `PATCH` вместо `PUT`), поправьте `PlayGoApiClient` один раз централизованно.

---

## Этап 0 (текущий) — базовая связка

- [x] Конфиг `API_BASE_URL`, по умолчанию `http://localhost:4000`
- [x] `GET /api/health`
- [x] Auth: `POST /api/auth/register`, `POST /api/auth/login`, `POST /api/auth/refresh` (тело `{ "refreshToken" }` → новый `accessToken` и при необходимости `refreshToken`), `GET/PATCH /api/me`, `DELETE /api/me`, пароль  
  Ответы логина/регистрации могут включать `refreshToken` (или `refresh_token` / вложенный объект `tokens`) — клиент сохраняет его и при 401 обновляет сессию без повторного ввода пароля.
- [x] `GET /api/matches` с query: `cityId`, `city`, `stadiumId`, `status` + Bearer
- [x] `GET /api/matches/:id` (клиент готов к использованию на экране детали)
- [x] `GET /api/stadiums` (клиент для карты/фильтров)

---

## Этап 1 — Заявки на матч (Match Registrations)

**Эндпоинты:** `GET/POST /api/registrations`, фильтры `matchId`, `status`, …

**Задачи:**

1. Модели: заявка (`status`, `teamId`, … по схеме API).
2. Экран матча: кнопка «Подать заявку» → `POST /api/registrations` с `matchId`, данными команды/капитана (см. тело в спецификации).
3. Обработка ошибок: нет команды, нет карточки игрока, дубликат заявки, нет мест.
4. Список своих заявок (при необходимости) через `GET /api/registrations`.

**Зависимости:** команда и карточка игрока (этапы 2–3).

---

## Этап 2 — Команда (Teams)

**Эндпоинты:** `GET/POST /api/me/team`, приглашения, `GET /api/teams/:id/public`

**Клиент (`TeamsApiClient`):** [x] `getMyTeam`, [x] `createTeam`, [x] `getTeamInvitations`, [x] `inviteToTeam`, [x] `acceptInvitation`, [x] `rejectInvitation`, [x] `updateMember`, [x] `getPublicTeam`.

**Задачи:**

1. [x] Экран «Моя команда» (`/profile/team`): загрузка `GET /api/me/team`, создание команды `POST`.
2. [x] Приглашения: список `GET /api/me/team-invitations`, accept/reject.
3. [x] Капитан: приглашение игроков `POST /api/me/team/invitations`, роли `PATCH .../members/:memberId`.
4. [x] UI ролей (`CAPTAIN`, `MEMBER`, `SUBSTITUTE`) и позиций (`GK`, `DF`, `MF`, `FW`).
5. [ ] Публичная карточка команды в UI (опционально): `GET /api/teams/:id/public`.

---

## Этап 3 — Карточка игрока (Player Cards)

**Эндпоинты:** `GET /api/player-card-options`, `GET/PUT /api/me/player-card`, `POST .../avatar`, `GET /api/players`, `GET /api/players/:userId`

**Клиент (`PlayerCardApiClient`):** [x] `getPlayerCardOptions`, [x] `getMyPlayerCard`, [x] `putMyPlayerCard`, [x] `uploadPlayerCardAvatar`, [x] `getPlayers` (query: `cityId`, `city`, `position`, `skill`, `minRating`, `maxRating`, `lookingForTeam`, `q`), [x] `getPlayerByUserId`.

**Ограничения по спецификации:** сильные стороны и статусы — только перечисленные в коде (`PlayerCardConstants`); не более 3 + не более 3.

**Задачи:**

1. [x] Онбординг/профиль: форма карточки с лимитами (до 3 сильных сторон, до 3 статусов).
2. [x] Справочник с `player-card-options` (подмешивается к дефолтным спискам в мастере).
3. [ ] UI загрузки аватара карточки → вызов `uploadPlayerCardAvatar` + URL из `GET /uploads/...`.
4. [ ] Экран каталога игроков с фильтрами `GET /api/players`.


---

## Этап 4 — Карта и стадионы

**Эндпоинты:** уже есть `GET /api/stadiums`; привязка к матчам по `stadiumId`

**Задачи:**

1. Маркеры стадионов + матчи по выбранному городу (`city` / `cityId`).
2. Согласование полей `MatchModel` с ответом API (стадион, координаты, статус матча).

---

## Этап 5 — Медиа и полировка

- Базовый URL для файлов: `GET /uploads/...` (аватар профиля, карточки, админские загрузки).
- Обработка 401: автоматический `POST /api/auth/refresh` при наличии refresh-токена, иначе выход.
- Локализация сообщений об ошибках с бэкенда.

---

## Админка

Эндпоинты `/api/admin/*` с **Basic Auth** — отдельное приложение/веб; в мобильном клиенте не используются.

---

## Примечания

- На физическом устройстве вместо `localhost` указывайте IP машины с API:  
  `flutter run --dart-define=API_BASE_URL=http://192.168.x.x:4000`
- Статические файлы раздаются с того же хоста, путь `/uploads/...`
