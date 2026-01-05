#!/bin/bash

export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"

SDK_PATH="/Users/rvsl/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.0-2025-12-03-5122605dc"
PROJECT_PATH="/Users/rvsl/My Drive (sargezaitsev@gmail.com)/2 - рабочее/33 - BurgerKing/garmin/SaunaTracker"

echo "=== ОТЛАДОЧНЫЙ ЗАПУСК СИМУЛЯТОРА ==="
echo ""
echo "1️⃣ Проверка Java..."
java -version
echo ""

echo "2️⃣ Открываю симулятор GUI..."
open "$SDK_PATH/bin/ConnectIQ.app"
echo "✅ Команда открытия выполнена"
echo ""

echo "⏳ Ожидание 5 секунд..."
sleep 5

echo ""
echo "3️⃣ Проверка процесса симулятора..."
if pgrep -f "ConnectIQ" > /dev/null; then
    echo "✅ Симулятор запущен (процесс найден)"
else
    echo "⚠️  Процесс симулятора не найден"
    echo "Возможно, он всё ещё загружается..."
fi
echo ""

echo "4️⃣ Очистка и компиляция..."
rm -rf "$PROJECT_PATH/bin/*"
"$SDK_PATH/bin/monkeyc" \
  -o "$PROJECT_PATH/bin/SaunaTracker.prg" \
  -f "$PROJECT_PATH/monkey.jungle" \
  -y "/Users/rvsl/Library/Application Support/Garmin/ConnectIQ/Devices/developer_key.der" \
  -d instinct2s \
  -w

echo ""
echo "5️⃣ Попытка загрузки приложения..."
echo "Команда:"
echo "monkeydo $PROJECT_PATH/bin/SaunaTracker.prg instinct2s"
echo ""

"$SDK_PATH/bin/monkeydo" "$PROJECT_PATH/bin/SaunaTracker.prg" instinct2s
EXIT_CODE=$?

echo ""
echo "Exit code: $EXIT_CODE"

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Команда выполнена успешно"
else
    echo "❌ Ошибка выполнения (код $EXIT_CODE)"
fi

echo ""
echo "=== ИНСТРУКЦИЯ ==="
echo "Теперь в окне симулятора:"
echo "1. Убедитесь, что выбрано устройство: Instinct 2S"
echo "2. Если экран серый - нажмите в меню: Simulation → Start Simulation"
echo "3. Кликайте по кнопкам на изображении часов для управления"
echo ""
echo "Симулятор остаётся открытым. Не закрывайте его."
echo "Для повторной загрузки просто запустите этот скрипт снова."
