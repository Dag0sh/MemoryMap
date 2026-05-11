# 🔄 Руководство по миграции на новую архитектуру

## Шаг 1: Добавление новых файлов в проект

### 1.1 В Xcode создайте группы (если их нет):
```
Project
├── Models
├── Services
├── ViewModels
├── Views
└── Tests
```

### 1.2 Добавьте новые файлы:

**Models группа:**
- `Models.swift` ✨
- `MemoryPin+Extensions.swift` ✨

**Services группа:**
- `PhotoService.swift` ✨
- Переместите `CoreDataStack.swift` сюда (если не там)
- Переместите `LocationManager.swift` сюда (если не там)

**Views группа:**
- `StickerPicker.swift` ✨
- `PhotoGalleryView.swift` ✨

**Tests группа (Test Target):**
- `ExampleTests.swift` ✨

**Root уровень:**
- `README.md` ✨
- `ARCHITECTURE.md` ✨
- `IMPROVEMENTS.md` ✨
- `CHECKLIST.md` ✨
- `SUMMARY.md` ✨
- `DASHBOARD.md` ✨

## Шаг 2: Обновление существующих файлов

### 2.1 Замените содержимое файлов:

✅ **CoreDataStack.swift** - новая версия с error handling
✅ **MapViewModel.swift** - новая версия с async/await
✅ **EditMemoryView.swift** - полностью переписана
✅ **AddMemoryView.swift** - полностью переписана
✅ **ContentView.swift** - минимальные изменения (`.task` вместо `.onAppear`)
✅ **PinDetailView.swift** - удалите определение `IdentifiedImage`

### 2.2 Как заменить:

1. **Сделайте backup!**
   ```bash
   git commit -m "Backup before refactoring"
   ```

2. **Замените файлы по очереди**
   - Начните с Models и Services
   - Затем ViewModel
   - Потом Views
   - Последними - тесты и документацию

3. **После каждого изменения проверяйте build**
   ```
   Cmd + B
   ```

## Шаг 3: Обновление импортов

### 3.1 Убедитесь что все файлы имеют правильные импорты:

**Для Views:**
```swift
import SwiftUI
import PhotosUI  // если используется PhotosPicker
```

**Для ViewModels:**
```swift
import Foundation
import MapKit
import CoreData
```

**Для Services:**
```swift
import Foundation
import UIKit  // для PhotoService
import CoreLocation  // для LocationManager
```

**Для Tests:**
```swift
import Testing
import Foundation
@testable import MemoryMap  // Замените на имя вашего модуля!
```

## Шаг 4: Обновление Core Data (если нужно)

### 4.1 Проверьте модель:
- Откройте `.xcdatamodeld` файл
- Убедитесь что `MemoryPin` и `PhotoEntity` имеют все необходимые атрибуты:

**MemoryPin:**
- id: UUID
- title: String (optional)
- sticker: String (optional)
- date: Date (optional)
- latitude: Double
- longitude: Double
- photos: To-Many relationship to PhotoEntity

**PhotoEntity:**
- id: UUID
- imageData: Binary Data
- date: Date (optional)
- pin: To-One relationship to MemoryPin

### 4.2 Если нужно добавить новые атрибуты:
1. Editor → Add Model Version
2. Добавьте атрибуты
3. Set current model version
4. Create NSManagedObjectModel mapping если нужно

## Шаг 5: Info.plist

### 5.1 Добавьте описания разрешений:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Приложение использует вашу геолокацию для отметки мест воспоминаний на карте</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Приложение запрашивает доступ к фотографиям для добавления их к вашим воспоминаниям</string>
```

## Шаг 6: Обновление кода использования

### 6.1 Где вызывается MapViewModel - обновите вызовы:

**СТАРЫЙ КОД:**
```swift
viewModel.addPin(
    title: title,
    sticker: sticker,
    location: location,
    images: images
)
```

**НОВЫЙ КОД:**
```swift
Task {
    let config = PinConfiguration(
        title: title,
        sticker: sticker,
        images: images
    )
    await viewModel.addPin(configuration: config, location: location)
}
```

### 6.2 Обновите вызовы updatePin:

**СТАРЫЙ КОД:**
```swift
viewModel.updatePin(pin, title: title, sticker: sticker, newImages: images)
```

**НОВЫЙ КОД:**
```swift
Task {
    let config = PinConfiguration(
        title: title,
        sticker: sticker,
        images: images
    )
    await viewModel.updatePin(pin, configuration: config)
}
```

### 6.3 Обновите вызовы deletePin и deletePhoto:

**СТАРЫЙ КОД:**
```swift
viewModel.deletePin(pin)
```

**НОВЫЙ КОД:**
```swift
Task {
    await viewModel.deletePin(pin)
}
```

## Шаг 7: Тестирование

### 7.1 Build проект:
```
Cmd + B
```

### 7.2 Исправьте ошибки компиляции:
- Проверьте все импорты
- Убедитесь что `IdentifiedImage` не определен дважды
- Проверьте что все async функции вызываются с await

### 7.3 Запустите приложение:
```
Cmd + R
```

### 7.4 Протестируйте все сценарии:
- [ ] Создание нового воспоминания
- [ ] Редактирование воспоминания
- [ ] Удаление воспоминания
- [ ] Добавление фото
- [ ] Удаление фото
- [ ] Навигация по карте
- [ ] Просмотр деталей

## Шаг 8: Тесты

### 8.1 Добавьте Test Target если его нет:
```
File → New → Target → Unit Testing Bundle
```

### 8.2 Добавьте ExampleTests.swift в Test Target

### 8.3 Обновите имя модуля:
```swift
@testable import YourModuleName  // Замените на ваше имя!
```

### 8.4 Запустите тесты:
```
Cmd + U
```

## Шаг 9: Git

### 9.1 Закоммитьте изменения:
```bash
git add .
git commit -m "Refactor: Migrate to new MVVM architecture

- Add Models, Services layers
- Implement async/await throughout
- Add reusable UI components
- Improve error handling
- Add comprehensive documentation
- Add example tests"
```

### 9.2 Создайте branch для миграции (опционально):
```bash
git checkout -b feature/architecture-refactor
# Делайте изменения
git push origin feature/architecture-refactor
# Создайте PR
```

## Шаг 10: Code Review Checklist

Перед финальным merge проверьте:

### Код
- [ ] Нет build warnings
- [ ] Все файлы добавлены в проект
- [ ] Правильные импорты
- [ ] Нет дублирования кода
- [ ] Async/await используется правильно
- [ ] Error handling добавлен

### Функциональность
- [ ] Все функции работают
- [ ] Нет регрессий
- [ ] UI отзывчивый
- [ ] Loading states работают
- [ ] Error messages показываются

### Документация
- [ ] README.md обновлен
- [ ] Комментарии добавлены где нужно
- [ ] MARK: sections добавлены

### Тесты
- [ ] Примеры тестов работают
- [ ] Coverage удовлетворительный

## Troubleshooting

### Проблема 1: "Cannot find 'IdentifiedImage' in scope"
**Решение:** Убедитесь что `Models.swift` добавлен в проект и имеет правильный Target Membership.

### Проблема 2: "Value of type 'MapViewModel' has no member 'addPin' with 5 parameters"
**Решение:** Вы используете старую сигнатуру. Обновите на новую с `PinConfiguration`.

### Проблема 3: "'async' call in a function that does not support concurrency"
**Решение:** Оберните вызов в `Task { await ... }`.

### Проблема 4: Tests не компилируются
**Решение:** 
1. Проверьте что ExampleTests.swift добавлен в Test Target
2. Обновите `@testable import` на имя вашего модуля
3. Убедитесь что Swift Testing framework доступен (iOS 16+)

### Проблема 5: Core Data crashes
**Решение:**
1. Проверьте что модель Core Data не изменилась
2. Если изменилась - создайте migration
3. Или удалите приложение и переустановите (теряются данные!)

### Проблема 6: Photos not loading
**Решение:**
1. Проверьте NSPhotoLibraryUsageDescription в Info.plist
2. Проверьте что PhotoService.swift правильно импортирован
3. Проверьте что await используется для loadImages

## Откат изменений (если что-то пошло не так)

### Если используете Git:
```bash
git checkout main
# или
git reset --hard HEAD~1
```

### Если не используете Git:
Восстановите из backup который вы сделали в Шаге 2.1!

## Полезные команды

### Build
```bash
xcodebuild -scheme MemoryMap -configuration Debug
```

### Tests
```bash
xcodebuild test -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Clean
```bash
Product → Clean Build Folder (Shift + Cmd + K)
```

## Следующие шаги после миграции

1. ✅ Протестируйте тщательно
2. ✅ Попросите code review
3. ✅ Обновите CI/CD pipeline если есть
4. ✅ Обновите App Store описание если нужно
5. ✅ Создайте новый build для TestFlight
6. ✅ Соберите feedback от тестеров
7. ✅ Подготовьте к релизу

## Вопросы?

Если что-то непонятно:
1. Прочитайте ARCHITECTURE.md
2. Посмотрите IMPROVEMENTS.md
3. Проверьте примеры в ExampleTests.swift
4. Создайте issue в репозитории

---

**Удачи с миграцией! 🚀**
