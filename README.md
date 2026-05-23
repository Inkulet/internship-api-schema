# API для тестового задания

Реализация API из `tz/openapi.yaml`: ученики, классы, школы. Rails 7.2 (API-only), PostgreSQL 16, всё крутится в Docker.

## Как запустить

```bash
cp .env.example .env
docker compose up --build
```

На первом запуске Rails сам создаст базу, прогонит миграции и засеет её парой школ с классами и учениками. Когда увидите в логах строчку про `Listening on http://0.0.0.0:3000`, всё готово.

API доступен на `http://localhost:3000`.

Остановить: `Ctrl+C`. Полностью снести (включая БД): `docker compose down -v`.

## Эндпоинты

Все примеры curl ниже работают сразу после `docker compose up` на сидированной БД. Конкретные id студентов и классов будут зависеть от того, что насеялось — посмотреть можно через `GET /schools/1/classes`.

### Создать студента

```bash
curl -i -X POST http://localhost:3000/students \
  -H 'Content-Type: application/json' \
  -d '{
    "first_name": "Иван",
    "last_name":  "Иванов",
    "surname":    "Иванович",
    "class_id":   1,
    "school_id":  1
  }'
```

Ответ — `201 Created`, тело со схемой `Student` из openapi, плюс заголовок `X-Auth-Token`. Токен нужно сохранить: только им можно удалить этого студента позже. Если потеряли — не восстановить.

### Удалить студента

```bash
curl -i -X DELETE http://localhost:3000/students/42 \
  -H 'Authorization: Bearer e9b16f2671fbe6073df27776f9c22f745bee830e269cf968c938c4abef3801a9'
```

`204 No Content` на успех. Без заголовка или с неправильным токеном — `401`. Если id студента кривой или его уже нет — `400`.

### Классы школы

```bash
curl http://localhost:3000/schools/1/classes
```

Возвращает `{ "data": [...] }` со списком классов: номер, буква, количество учеников.

### Ученики класса

```bash
curl http://localhost:3000/schools/1/classes/1/students
```

Тоже `{ "data": [...] }`. Если школы или класса нет — список просто пустой.

## Что под капотом

Три модели: `School`, `SchoolClass` (таблица называется `classes`, потому что `Class` в Ruby занят), `Student`. У классов есть колонка `students_count` с counter_cache — `GET /schools/:id/classes` не делает COUNT по каждому классу, число берётся из колонки и обновляется при создании/удалении ученика.

Токен — это `sha256(student_id + SECRET_SALT)`. Соль читается в порядке `ENV → Rails credentials → "dev-salt" в dev/test → KeyError в production`. Меняете соль — старые токены перестают работать, это нормально.

Бизнес-инварианты живут на уровне модели:
- ученик не может оказаться в классе чужой школы;
- в одной школе не может быть двух классов «1А»;
- `students_count` всегда соответствует фактическому числу учеников (counter_cache + транзакции).

Авторизация вынесена в concern `Authenticatable` и подключается к `StudentsController#destroy` через `before_action`. Сравнение токенов — через `secure_compare`, чтобы не светить байты через тайминг.

Тесты — RSpec, 60+ примеров: модели (валидации, ассоциации, counter_cache, генерация токена) и request specs на все 4 эндпоинта (happy paths + ошибки 400/401/405 + пагинация).

## Решения и компромиссы

Места, где я сознательно выбрал один путь, а не другой:

**HTTP 405 на невалидный POST.** Семантически это «Method Not Allowed», в реальном проекте я бы взял 422 или 400. Но в openapi прописано «405 Invalid input» — следую за документом, чтобы не отклоняться от спеки.

**Pagination опциональная.** Эндпоинты-списки поддерживают `?page=` и `?per_page=`, но без них отдают весь scope. Это сохраняет 100% совместимость с openapi-схемой (там пагинации нет вовсе) и одновременно даёт реальный механизм на случай больших классов.

**`SchoolClass`, а не `Class`.** Имя `Class` зарезервировано в Ruby. Модель — `SchoolClass` с явным `self.table_name = "classes"`, чтобы таблица в БД и URL в API назывались одинаково (`/schools/:id/classes`).

**`auth_token` генерируется в `after_create`, не в `before_create`.** Хэш привязан к `id`, а `id` известен только после `INSERT`. Альтернатива — генерировать `SecureRandom`-токен без привязки к id, но openapi прямо говорит `sha256(user_id + secret_salt)`.

**`Student` хранит `school_id` явно, а не только через `class.school_id`.** Денормализация — openapi-схема `Student` требует оба поля. Согласованность гарантирована валидацией `school_matches_class`.

**400 на «студент не найден» при DELETE, а не 404.** В openapi для `DELETE /students/{user_id}` определены только 400 и 401. Мапим «не найден» в 400 «некорректный id». Это лёгкая утечка существования id (400 vs 401), но контракт диктует именно так.

**Trim Rails.** В `config/application.rb` загружаются только `active_model`, `active_job`, `active_record`, `action_controller`. ActionMailer/Cable/Storage/Text/Mailbox/View не нужны, удалены. Boot немного быстрее, образ чуть меньше.

**Локализация на русский (ru).** EdTech-приложение, ошибки валидации должны быть на русском. Перевод вынесен в `config/locales/ru.yml`.

## Если что-то пошло не так

**Порт 3000 занят.** Прокиньте другой — поправьте `ports` в `docker-compose.yml` (`"3001:3000"`).

**Web стартует, а БД ещё нет.** Не должно случаться: в compose стоит `depends_on: condition: service_healthy`, web ждёт пока postgres ответит на `pg_isready`. Если всё-таки случилось — `docker compose restart web`.

**Хочу залезть в консоль Rails.**
```bash
docker compose exec web bundle exec rails console
```

**Хочу посмотреть, что в БД.**
```bash
docker compose exec db psql -U postgres -d app_development
```

**Изменил Gemfile — гемы не подхватились.** Пересоберите образ: `docker compose build web`.

**Хочу всё снести и засеять заново.** `docker compose down -v && docker compose up`.

## Структура проекта

```
app/
  controllers/
    application_controller.rb          — rescue_from для 400/405
    students_controller.rb             — POST /students, DELETE /students/:user_id
    classes_controller.rb              — GET /schools/:id/classes
    class_students_controller.rb       — GET /schools/:id/classes/:id/students
    concerns/authenticatable.rb        — проверка Bearer-токена
  models/
    school.rb
    school_class.rb                    — table_name = "classes"
    student.rb                         — генерация auth_token в after_create
config/
  routes.rb                            — ровно 4 маршрута из openapi
  database.yml                         — все параметры из ENV
db/
  migrate/                             — 3 миграции: schools, classes, students
  seeds.rb                             — 2 школы, 5 классов, 10 учеников
tz/
  README.md, openapi.yaml              — исходное задание
```
