# simple_notepad_mobile

A notes app for Android with Markdown and LaTeX support, categories, JSON backups and optional sync with your own server.

## Features

- Create, edit and delete notes
- **Markdown and LaTeX** rendering, with a preview in the editor
- Automatic link detection: a link card shows an icon, the title, the description and the site name, without any requests to third-party services
- Categories with custom colors
- Local storage (SQLite); the app works fully offline
- Optional sync with a REST API (the server address is set in the app's settings)
- Backup export and import as JSON; on export you choose the folder where the file is saved, or share it instead

## Getting started

1. Clone the repository.
2. Run `flutter pub get`.
3. Start the app on an Android emulator or device: `flutter run`.

The local database uses `sqflite`, so the app does not work in Chrome or on Windows desktop (you get a blank screen). Run and test it on Android.

### Server address

Sync is optional and the app works fully without a server. To use one, open **Settings** (the gear icon on the main screen) and enter the **server address**, for example `https://notes.example.com/api`. The address is stored on the device only. Leave the field empty to use the default. A change applies to the next request, no restart needed.

The default address is `http://10.0.2.2:3000/api` (the host machine as seen from the Android emulator). You can change it at build time with `--dart-define`:

```
flutter run --dart-define=API_URL=https://notes.example.com/api
flutter build apk --release --dart-define=API_URL=https://notes.example.com/api
```

Plain `http://` is allowed only for `10.0.2.2`, `localhost` and `127.0.0.1` (development on the emulator); any other address needs `https://`. The Settings screen warns you if an `http://` address is blocked by Android. To test a server in your local network over `http://`, add its address to `android/app/src/main/res/xml/network_security_config.xml` and rebuild the app. There is no ready-made server in this repository.

## Development

### Code generation

Providers (Riverpod) and JSON models use code generation. The generated `*.g.dart` files are committed to the repository; after changing an annotated class, regenerate them:

```
dart run build_runner build --delete-conflicting-outputs
```

### Checks

```
flutter analyze
flutter test
```

CI (GitHub Actions) runs the same commands on every push and pull request to `main` and `develop`. CI fails on `flutter analyze` infos as well as warnings.

The detailed log of backup parsing is off by default. To turn it on, add `--dart-define=BACKUP_VERBOSE=true` to the `flutter run` command.

## Server contract

This is the interface the client expects. The base address is the server address from Settings (or `API_URL`). All requests and responses use JSON (`Content-Type: application/json`), and any 2xx status counts as success. The request timeout is 10 seconds. Any error or timeout simply skips the sync, and local data is left unchanged.

| Method and path | Purpose |
|---|---|
| `GET /notes?sort=new` | List notes. Parameters: `sort` (`new` by default, or `old`) and an optional `category` (category id) |
| `GET /notes/{id}` | One note |
| `POST /notes` | Create a note (body: a note object) |
| `PUT /notes/{id}` | Update a note (body: a note object) |
| `DELETE /notes/{id}` | Delete a note (response 200 or 204) |
| `GET /categories` | List categories |
| `POST /categories` | Create a category (body: a category object) |
| `DELETE /categories/{id}` | Delete a category (response 200 or 204) |
| `GET /settings` | Get settings |
| `PUT /settings` | Save settings |

The client does not use the response bodies of `POST` and `PUT`, so they may be empty.

**Note:**

```json
{
  "id": "3f2b8c1e-9a47-4d6b-8e21-5c0a7d4f9b12",
  "title": "A title or null",
  "content": "Markdown text or a URL",
  "category_id": "general",
  "date": "04.10.2026, 14:05",
  "created_timestamp": 1759500000000,
  "updated_timestamp": 1759500000000,
  "expanded": 0,
  "edit_mode": 0,
  "type": "note",
  "metadata": null,
  "preview_text": null
}
```

- `id` is a string: a UUID for new notes. For notes created earlier or imported from the web version it is a number (the creation time in milliseconds, sometimes with a fractional part) stored as a string. The client accepts both a number and a string. `type` is `note` or `link`.
- `expanded` and `edit_mode` are 0 or 1.
- For links, `metadata` is JSON encoded as a string (`title`, `description`, `image`, `favicon`, `siteName`) or `null`. The client accepts both a string and an object.

**Category:** `{"id": "general", "name": "General", "color": "#4CAF50", "custom": 0}`. `custom: 0` marks a system category, which cannot be removed from the list.

**Settings:** `{"sort_order": "new", "view_mode": "list"}`.

For now, sync only adds missing notes and categories in both directions. Edits and deletions are not carried between devices; this is planned in the "Reliable sync" milestone.

## Backup format

Export and import (the backup screen) use a single JSON file. On export you can pick the folder (and change the file name) in the system "save as" dialog, or share the file instead.

```json
{
  "notes": [ /* note objects, in the same form as for the server */ ],
  "categories": [ /* category objects */ ],
  "settings": { "sort_order": "new", "view_mode": "list" },
  "exportDate": "2026-10-04T14:05:00.000",
  "version": "1.0"
}
```

On import, older and web-version keys are accepted: `createdTimestamp`, `updatedTimestamp`, `editMode`, `category` instead of `category_id`, `sortOrder` and `viewMode` in settings, booleans instead of 0 and 1, and a numeric `id` (it is kept as a string without losing the value). Missing fields get default values, and malformed entries are skipped. Import only adds notes and categories that are missing and never overwrites existing ones.

## Privacy

The app does not contact third-party services: links are not sent to external servers, and site images and icons are not downloaded. Notes are stored only on the device. The only network traffic, if you set it up, is sync with your own server. If old data already contains a saved page title and description, they are shown from the local database.

## Built with

- Flutter
- Riverpod (state management, code generation)
- SQLite (sqflite)
- HTTP (http)
- Markdown and LaTeX (flutter_markdown)

## License

MIT
