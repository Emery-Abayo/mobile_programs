# Shopping List

A simple Flutter app for keeping track of what you need to buy. Type an item, add it to the list, tick it off when you have bought it, and clear everything you have bought in one tap.

Built as part of **Mobile Programming, Week 2, Session 3** at the Innovation Center.

**Author:** YOUR NAME HERE
**Date:** 12 October 2026

---

## Screenshots

> Replace each placeholder with your own screenshot. Save the images in a `screenshots/` folder at the root of the project (next to `pubspec.yaml`) and keep the file names below, or update the paths.

| Home screen | Adding an item |
|:---:|:---:|
| ![Home screen](screenshots/01-home.png) | ![Adding an item](screenshots/02-add-item.png) |
| *The starting list: Milk, Bread, Rice* | *Typing an item and tapping Add* |

| Empty field message | Marked as bought |
|:---:|:---:|
| ![Empty field message](screenshots/03-empty-message.png) | ![Marked as bought](screenshots/04-bought.png) |
| *"Type an item first" appears at the bottom* | *Bought items crossed out, count in the title* |

| Deleting an item | Clearing bought items |
|:---:|:---:|
| ![Deleting an item](screenshots/05-delete.png) | ![Clearing bought items](screenshots/06-clear-bought.png) |
| *The bin removes only that row* | *The top bar button removes all bought items* |

---

## Features

- Add an item by typing it and tapping **Add** (or pressing Enter)
- Empty items are refused, with a message at the bottom of the screen
- Delete a single item with the bin icon on its row
- Tap an item to mark it as bought: its name is crossed out and its icon becomes a tick. Tap again to undo
- The title shows how many items are left, for example *Shopping List (2 left)*
- One button in the top bar removes all bought items at once

---

## Built with

- [Flutter](https://flutter.dev) 3.x
- [Dart](https://dart.dev)
- Material 3 design
- Android Studio

---

## How to run

**Requirements:** Flutter SDK installed, and either an Android emulator, an Android phone, or Chrome.

```bash
# 1. Clone the repository
git clone https://github.com/YOUR-USERNAME/shopping_list.git

# 2. Go into the project
cd shopping_list

# 3. Download the packages
flutter pub get

# 4. Run the app (choose your device when asked)
flutter run
```

To run in Chrome: `flutter run -d chrome`

---

## Project structure

```
shopping_list/
├── lib/
│   └── main.dart        All the app code
├── screenshots/         Images used in this README
├── pubspec.yaml         App settings and packages
└── README.md
```

### Inside `lib/main.dart`

| Piece | What it does |
|---|---|
| `main()` | Starts the app |
| `Item` | The model: a name and a bought status |
| `ShoppingApp` | The app: its theme and first screen |
| `HomeScreen` | The screen's settings (its title) |
| `_HomeScreenState` | The screen's data (`items`, `controller`) and rules (`addItem`) |
| `build()` | Draws the screen from the data |

---

## What I learned

- Everything on screen in Flutter is a widget, and screens are trees of widgets
- The difference between `StatelessWidget` and `StatefulWidget`
- How `setState` tells Flutter to redraw the screen after the data changes
- Building lists with `ListView.builder` and `ListTile`
- Reading user input with `TextField` and `TextEditingController`
- Using a model class (`Item`) to describe data separately from the screen
- Reading error messages and using hot reload and hot restart

---

## Known limitations

- The list is not saved: closing the app resets it to Milk, Bread and Rice

## Possible improvements

- Save the list on the device so it survives closing the app
- Show "Your list is empty" when there are no items
- Add a quantity to each item
- Move bought items to the bottom of the list

---

## Author

**YOUR NAME HERE**
Mobile Programming, Innovation Center
GitHub: [@YOUR-USERNAME](https://github.com/YOUR-USERNAME)