# 🗺 Memory Map - Приложение для воспоминаний на карте

> Современное iOS приложение для сохранения воспоминаний с привязкой к местам на карте

## 📱 О приложении

Memory Map позволяет создавать воспоминания с фотографиями и привязывать их к местам на карте. Каждое воспоминание представлено цветным стикером на карте, содержит название, фотографии и точное местоположение.

### ✨ Основные возможности

- 📍 **Карта с воспоминаниями** - визуализация всех ваших мест на интерактивной карте
- 📸 **Фотографии** - добавляйте до 10 фото к каждому воспоминанию
- 🎨 **Стикеры** - выбирайте из 22+ символов для персонализации
- 📝 **Описания** - добавляйте названия к воспоминаниям
- 🗑 **Редактирование** - изменяйте и удаляйте воспоминания
- 🔍 **Детальный просмотр** - полноэкранная галерея фотографий
- 📍 **Геокодирование** - автоматическое определение адреса места
- 🎯 **Текущее местоположение** - быстрая навигация к вашей позиции

## 🏗 Архитектура

Проект использует **MVVM** архитектуру с четким разделением ответственности:

```
├── Models/               # Модели данных
│   ├── Models.swift      # Общие структуры (IdentifiedImage, PinConfiguration)
│   └── MemoryPin+Extensions.swift  # Расширения Core Data моделей
│
├── Services/             # Бизнес-логика
│   ├── CoreDataStack.swift    # Управление Core Data
│   ├── PhotoService.swift     # Работа с фотографиями
│   └── LocationManager.swift  # Геолокация
│
├── ViewModels/          # View Models
│   └── MapViewModel.swift     # Главный ViewModel
│
├── Views/               # UI компоненты
│   ├── ContentView.swift          # Главный экран с картой
│   ├── AddMemoryView.swift        # Создание воспоминания
│   ├── EditMemoryView.swift       # Редактирование
│   ├── PinDetailView.swift        # Детальный просмотр
│   ├── StickerPicker.swift        # Выбор стикера (reusable)
│   └── PhotoGalleryView.swift     # Галерея фото (reusable)
│
└── Tests/               # Тесты
    └── ExampleTests.swift         # Примеры тестов
```

### 🎯 Ключевые технологии

- **SwiftUI** - современный declarative UI framework
- **Core Data** - локальное хранение данных
- **MapKit** - интерактивные карты
- **PhotosUI** - выбор фотографий
- **CoreLocation** - геолокация
- **Swift Concurrency** - async/await для всех операций
- **Swift Testing** - современный фреймворк для тестирования

## 🚀 Начало работы

### Требования

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Установка

1. Клонируйте репозиторий
```bash
git clone [your-repo-url]
cd MemoryMap
```

2. Откройте проект в Xcode
```bash
open MemoryMap.xcodeproj
```

3. Добавьте необходимые описания в Info.plist:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Для отметки мест воспоминаний на карте</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Для добавления фотографий к воспоминаниям</string>
```

4. Запустите проект (⌘R)

## 📖 Использование

### Создание воспоминания

1. Нажмите кнопку **"Добавить"** на главном экране
2. Введите название воспоминания
3. Выберите стикер из 22+ доступных вариантов
4. Добавьте до 10 фотографий
5. Нажмите **"Сохранить"**

### Просмотр воспоминания

1. Нажмите на стикер на карте
2. Откроется детальный просмотр с фотографиями
3. Свайпайте влево/вправо для переключения фото
4. Нажмите на фото для полноэкранного просмотра

### Редактирование

1. Долгое нажатие (long press) на стикер
2. Измените название, стикер или добавьте фото
3. Нажмите **"Сохранить"**

### Удаление

1. Откройте редактирование воспоминания
2. Нажмите **"Удалить воспоминание"**
3. Подтвердите действие

## 🎨 Особенности реализации

### Async/await повсюду
```swift
Task {
    let config = PinConfiguration(title: "Моё место", sticker: "heart", images: photos)
    await viewModel.addPin(configuration: config, location: currentLocation)
}
```

### Переиспользуемые компоненты
```swift
StickerPicker(selectedSticker: $sticker, stickers: StickerSymbols.extended)
PhotoGalleryView(existingPhotos: photos, onDeleteExisting: deletePhoto)
```

### Типизированные конфигурации
```swift
struct PinConfiguration {
    var title: String?
    var sticker: String
    var images: [UIImage]
    var isValid: Bool { /* validation */ }
}
```

### Обработка ошибок
```swift
enum CoreDataError: Error, LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
}
```

## 📚 Документация

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - детальное описание архитектуры
- **[IMPROVEMENTS.md](IMPROVEMENTS.md)** - руководство по новым фичам
- **[CHECKLIST.md](CHECKLIST.md)** - чек-лист для проверки
- **[ExampleTests.swift](ExampleTests.swift)** - примеры тестов

## 🧪 Тестирование

Проект использует Swift Testing framework:

```bash
# Запустить все тесты
swift test

# Запустить конкретную suite
swift test --filter ModelTests

# Запустить тесты с тегом
swift test --filter tag:performance
```

Пример теста:
```swift
@Test("PinConfiguration validation")
func pinConfigurationValidation() async throws {
    let config = PinConfiguration(title: "Test", sticker: "heart", images: [])
    #expect(config.isValid)
}
```

## 🔧 Конфигурация

### Настройка символов стикеров

Отредактируйте `Models.swift`:
```swift
enum StickerSymbols {
    static let common = ["camera", "heart", "star", /* ваши символы */]
}
```

### Изменение качества сжатия фото

В `PhotoService.swift`:
```swift
static func compressImage(_ image: UIImage, quality: CGFloat = 0.8) -> Data?
```

### Настройка количества фото

В `AddMemoryView.swift` и `EditMemoryView.swift`:
```swift
PhotosPicker("Выбрать фото", selection: $selectedItems, maxSelectionCount: 10)
```

## 🐛 Известные проблемы и ограничения

1. ❌ Нет синхронизации через iCloud
2. ❌ Нет поиска и фильтрации воспоминаний
3. ❌ Нет экспорта данных
4. ❌ Нет кэширования изображений
5. ❌ Ограничение в 10 фото на воспоминание

См. [IMPROVEMENTS.md](IMPROVEMENTS.md) для планов развития.

## 🤝 Contributing

Приветствуются pull requests! Для больших изменений сначала откройте issue.

### Гайдлайны

1. Следуйте существующей архитектуре
2. Используйте async/await для асинхронных операций
3. Добавляйте тесты для новой функциональности
4. Обновляйте документацию
5. Проверьте чек-лист перед PR

## 📄 Лицензия

[MIT License](LICENSE)

## 👤 Автор

Ваше имя - [@your_handle](https://twitter.com/your_handle)

## 🙏 Благодарности

- Apple за отличные фреймворки
- SwiftUI community
- Все contributors

## 📞 Поддержка

- 📧 Email: your.email@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/memorymap/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/memorymap/discussions)

---

**⭐️ Если проект понравился, поставьте звездочку на GitHub!**
