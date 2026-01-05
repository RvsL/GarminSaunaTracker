#!/bin/bash

# Настройка переменных окружения для Java
export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"

# Путь к SDK
SDK_PATH="/Users/rvsl/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.0-2025-12-03-5122605dc"

# Путь к проекту
PROJECT_PATH="/Users/rvsl/My Drive (sargezaitsev@gmail.com)/2 - рабочее/33 - BurgerKing/garmin/SaunaTracker"

# Устройство для симуляции
DEVICE="instinct2s"

# Ключ разработчика
DEVELOPER_KEY="/Users/rvsl/Library/Application Support/Garmin/ConnectIQ/Devices/developer_key.der"

echo "🔨 Компиляция проекта..."
cd "$PROJECT_PATH"

# Очищаем старые сборки ПОЛНОСТЬЮ
echo "🧹 Полная очистка bin/..."
rm -rf bin
mkdir -p bin

"$SDK_PATH/bin/monkeyc" \
  -o bin/SaunaTracker.prg \
  -f monkey.jungle \
  -y "$DEVELOPER_KEY" \
  -d "$DEVICE" \
  -w

if [ $? -ne 0 ]; then
  echo "❌ Ошибка компиляции!"
  exit 1
fi

echo "✅ Компиляция успешна!"
echo "🚀 Запуск симулятора..."

# Запускаем симулятор, если он еще не запущен
if ! pgrep -f "ConnectIQ.app" > /dev/null; then
  echo "🖥️  Запускаю симулятор Connect IQ..."
  "$SDK_PATH/bin/connectiq" &
  echo "⏳ Ожидание загрузки симулятора (10 секунд)..."
  sleep 10
else
  echo "✅ Симулятор уже запущен"
  sleep 2
fi

# Запускаем приложение в симуляторе
echo "📱 Загружаю приложение в симулятор..."
"$SDK_PATH/bin/monkeydo" "$PROJECT_PATH/bin/SaunaTracker.prg" "$DEVICE"

if [ $? -eq 0 ]; then
  echo "✅ Приложение запущено в симуляторе!"
  echo ""
  echo "💡 Если экран серый, попробуйте:"
  echo "   1. В меню симулятора: Simulation → Start Simulation"
  echo "   2. Или: дважды кликните по экрану часов в симуляторе"
  echo "   3. Или: перезапустите скрипт через 5 секунд"
else
  echo "❌ Ошибка запуска приложения"
fi
