# Архитектура приложения Memory Map

## 📁 Структура проекта

### Models (Модели данных)
- **Models.swift** - Общие модели и структуры
  - `IdentifiedImage` - обертка над UIImage с ID для SwiftUI
  - `PinConfiguration` - конфигурация для создания/обновления пина
  - `StickerSymbols` - константы символов для стикеров

- **MemoryPin+Extensions.swift** - расширения Core Data моделей
  - Computed properties для удобного доступа к данным
  - Форматирование и преобразование данных

### Services (Сервисы)
- **CoreDataStack.swift** - управление Core Data
  - Singleton для доступа к контексту
  - Обработка ошибок
  - Фоновые операции
  
- **PhotoService.swift** - работа с фотографиями
  - Загрузка из PhotosPicker
  - Сжатие изображений
  - Создание thumbnails

- **LocationManager.swift** - работа с геолокацией
  - Отслеживание текущего местоположения
  - Управление разрешениями

### ViewModels
- **MapViewModel.swift** - бизнес-логика приложения
  - CRUD операции с пинами
  - Async/await для всех операций
  - Обработка ошибок
  - State management

### Views

#### Main Views
- **ContentView.swift** - главный экран с картой
  - Отображение карты с пинами
  - Навигация между экранами
  
- **AddMemoryView.swift** - создание нового воспоминания
- **EditMemoryView.swift** - редактирование воспоминания
- **PinDetailView.swift** - детальный просмотр воспоминания
- **FullScreenPhotoGallery.swift** - полноэкранная галерея

#### Reusable Components
- **StickerPicker.swift** - компонент выбора стикера
- **PhotoGalleryView.swift** - горизонтальная галерея фото
- **StickerView.swift** - отображение стикера на карте (в ContentView)

## 🏗 Архитектурные принципы

### 1. **MVVM Pattern**
```
View ← ViewModel ← Model/Service
```
- Views отвечают только за UI
- ViewModels содержат бизнес-логику
- Models - данные и их преобразование

### 2. **Separation of Concerns**
- Каждый компонент имеет одну ответственность
- Сервисы изолированы от UI
- Переиспользуемые компоненты вынесены отдельно

### 3. **Async/await**
- Все сетевые и долгие операции асинхронные
- Использование Task для фоновой работы
- MainActor для UI updates

### 4. **Error Handling**
- Типизированные ошибки (CoreDataError)
- Отображение ошибок пользователю
- Graceful degradation

### 5. **Dependency Injection**
- CoreDataStack внедряется в ViewModel
- Легкое тестирование через mock объекты

## 🔄 Data Flow

```
User Action → View → ViewModel → Service → Core Data
                ↑                              ↓
                └──────── Published State ─────┘
```

1. Пользователь выполняет действие в UI
2. View вызывает метод ViewModel
3. ViewModel использует сервисы (CoreData, Photo)
4. Данные сохраняются/обновляются
5. @Published свойства обновляются
6. SwiftUI автоматически перерисовывает UI

## 📝 Примеры использования

### Создание пина
```swift
let config = PinConfiguration(
    title: "Мой пин",
    sticker: "heart",
    images: [image1, image2]
)
await viewModel.addPin(configuration: config, location: location)
```

### Обновление пина
```swift
let config = PinConfiguration(
    title: "Новое название",
    sticker: "star",
    images: [newImage]
)
await viewModel.updatePin(pin, configuration: config)
```

### Загрузка фотографий
```swift
let images = await PhotoService.loadImages(from: photoPickerItems)
```

## 🧪 Тестирование

Архитектура позволяет легко создавать моки:

```swift
// Mock ViewModel для превью и тестов
class MockMapViewModel: MapViewModel {
    override init() {
        super.init(coreDataStack: MockCoreDataStack())
    }
}
```

## 🚀 Улучшения

### Реализовано
✅ Async/await вместо callbacks
✅ Обработка ошибок
✅ Переиспользуемые компоненты
✅ Типизированные конфигурации
✅ Separation of concerns
✅ Dependency injection
✅ Loading states
✅ Validation

### Можно добавить
- [ ] Unit тесты
- [ ] UI тесты
- [ ] Кэширование изображений
- [ ] Пагинация для больших списков
- [ ] Поиск и фильтрация пинов
- [ ] Экспорт/импорт данных
- [ ] iCloud синхронизация
- [ ] Widgets для iOS 14+
- [ ] App Clips
- [ ] Локализация

## 📊 Performance

### Оптимизации
- Сжатие изображений перед сохранением (quality: 0.8)
- Lazy loading фотографий
- Фоновые операции Core Data
- Автоматический merge изменений

### Memory Management
- Weak references где необходимо
- Proper cleanup в deinit
- Избегание retain cycles

## 🔐 Security & Privacy
- Геолокация только при разрешении
- Фото только из выбранных пользователем
- Локальное хранение (Core Data)
- Нет отправки данных на сервер
