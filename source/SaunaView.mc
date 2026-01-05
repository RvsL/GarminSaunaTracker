import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Activity;
import Toybox.Math;
import Toybox.SensorHistory;

class SaunaView extends WatchUi.View {

    var mDataParams;

    function initialize(params) {
        View.initialize();
        mDataParams = params;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        // --- 1. СБОР ДАННЫХ ---
        var info = Activity.getActivityInfo();
        var currentHR = mDataParams.heartRate;
        if (currentHR == 0 && info != null && info.currentHeartRate != null) {
            currentHR = info.currentHeartRate;
        }
        
        // Получаем температуру из SensorHistory (для Instinct 2S Solar Surf)
        if (SensorHistory has :getTemperatureHistory) {
            var tempIter = SensorHistory.getTemperatureHistory({});
            if (tempIter != null) {
                var sample = tempIter.next();
                if (sample != null && sample.data != null) {
                    mDataParams.temperature = sample.data;
                }
            }
        }

        // --- 2. ОЧИСТКА ---
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();   // 156
        var height = dc.getHeight(); // 156
        var halfW = width / 2;

        // Координаты центра "Глаза" (Instinct 2S)
        // Немного сдвинул влево и вверх, чтобы визуально было идеально
        var eyeX = 135; 
        var eyeY = 27;
        var eyeRadius = 23; // Увеличил радиус до края

        // --- 3. ЗАГОЛОВОК (Всегда сверху) ---
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        // Самый верх экрана
        dc.drawText(halfW-10, 0, Graphics.FONT_XTINY, "SAUNA", Graphics.TEXT_JUSTIFY_CENTER);


        // --- 4. КРУГЛОЕ ОКОШКО (ГЛАЗ) ---
        
        // Рисуем круговую шкалу ТОЛЬКО в режиме САУНЫ (даже если время вышло)
        if (mDataParams.isSessionActive && mDataParams.isSaunaMode) {
            
            dc.setPenWidth(3); // Толщина линии
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

            if (mDataParams.timeLeft > 0) {
                // ИДЕТ ВРЕМЯ: Рисуем дугу прогресса
                var duration = mDataParams.durationConfig.toFloat();
                var left = mDataParams.timeLeft.toFloat();
                // Прогресс заполняется (от 0 до 1)
                var progress = 1.0 - (left / duration);
                
                // 90 градусов = 12 часов. Clockwise = по часовой.
                var startDegree = 90;
                var endDegree = 90 - (360 * progress);
                
                dc.drawArc(eyeX, eyeY, eyeRadius, Graphics.ARC_CLOCKWISE, startDegree, endDegree);
            } else {
                // ВРЕМЯ ВЫШЛО: Рисуем ПОЛНЫЙ круг
                dc.drawCircle(eyeX, eyeY, eyeRadius);
            }
        }
        
        // ПУЛЬС (Всегда рисуем внутри глаза)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var hrStr = (currentHR > 0) ? currentHR.toString() : "--";
        // Центрируем точно по заданным координатам
        dc.drawText(eyeX, eyeY, Graphics.FONT_MEDIUM, hrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);


        // --- 5. ВРЕМЯ СУТОК (Слева) - Кастомный стиль ---
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var hourStr = today.hour.toString();
        var minStr = today.min.format("%02d");
        
        var timeX = 20;
        var timeY = 30;
        var timeFont = Graphics.FONT_NUMBER_MEDIUM;
        
        // ЧАСЫ: Заполненные (bold - рисуем с небольшим смещением для толщины)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(timeX, timeY, timeFont, hourStr, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(timeX + 1, timeY, timeFont, hourStr, Graphics.TEXT_JUSTIFY_LEFT); // Смещение для bold
        
        // ДВОЕТОЧИЕ
        var hourWidth = dc.getTextWidthInPixels(hourStr, timeFont);
        dc.drawText(timeX + hourWidth + 2, timeY, timeFont, ":", Graphics.TEXT_JUSTIFY_LEFT);
        
        // МИНУТЫ: Черные внутри с белой обводкой
        var colonWidth = dc.getTextWidthInPixels(":", timeFont);
        var minX = timeX + hourWidth + colonWidth + 4;
        
        // Рисуем белую обводку (8 направлений)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var ox = -1; ox <= 1; ox++) {
            for (var oy = -1; oy <= 1; oy++) {
                if (ox != 0 || oy != 0) {
                    dc.drawText(minX + ox, timeY + oy, timeFont, minStr, Graphics.TEXT_JUSTIFY_LEFT);
                }
            }
        }
        
        // Рисуем черный текст внутри (создает эффект черного с белой обводкой)
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(minX, timeY, timeFont, minStr, Graphics.TEXT_JUSTIFY_LEFT);

        
        // --- 5.5. ПАР/ДЫМ (Слева, декоративный эффект) ---
        // Рисуем пар только во время сауны
        if (mDataParams.isSessionActive && mDataParams.isSaunaMode) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            
            // Создаем волнистые облачка пара, поднимающиеся снизу вверх
            // Используем totalDuration для анимации (медленное движение)
            var steamOffset = (mDataParams.totalDuration % 6) * 2;
            
            // Нижнее облачко пара (самое плотное)
            dc.fillCircle(8, 95 - steamOffset, 4);
            dc.fillCircle(12, 93 - steamOffset, 3);
            dc.fillCircle(6, 90 - steamOffset, 3);
            
            // Среднее облачко (немного выше и прозрачнее)
            dc.drawCircle(10, 78 - steamOffset, 5);
            dc.drawCircle(14, 75 - steamOffset, 4);
            dc.drawCircle(7, 74 - steamOffset, 3);
            
            // Верхнее облачко (самое рассеянное)
            dc.drawCircle(9, 62 - steamOffset, 3);
            dc.drawCircle(12, 60 - steamOffset, 2);
            dc.drawCircle(6, 59 - steamOffset, 2);
        }


        // --- 6. ТАЙМЕР (Центр) ---
        // Сбрасываем цвет на БЕЛЫЙ после черных минут
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var t = mDataParams.timeLeft;
        // Модуль числа
        var absT = (t < 0) ? -t : t;
        var min = absT / 60;
        var sec = absT % 60;
        var timerStr = Lang.format("$1$:$2$", [min, sec.format("%02d")]);
        
        // Если Сауна и овертайм -> плюс
        if (mDataParams.isSaunaMode && t < 0) { timerStr = "+" + timerStr; }
        
        // Y = 80 (чуть ниже геометрического центра)
        dc.drawText(halfW, 80, Graphics.FONT_NUMBER_HOT, timerStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);


        // --- 7. СТАТУС (Над таймером) ---
        var statusStr = "";
        
        if (!mDataParams.isSessionActive) {
            // -- НАСТРОЙКА --
            statusStr = "SET: " + (mDataParams.durationConfig/60) + " MIN";
            
            // Подсказки кнопок
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(6, 70, Graphics.FONT_XTINY, "+", Graphics.TEXT_JUSTIFY_LEFT); 
            dc.drawText(6, 105, Graphics.FONT_XTINY, "-", Graphics.TEXT_JUSTIFY_LEFT); 
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
            // -- СЕССИЯ --
            if (mDataParams.isSaunaMode) {
                statusStr = "ROUND #" + mDataParams.round;
            } else {
                statusStr = "- REST -";
            }
        }
        dc.drawText(halfW, 110, Graphics.FONT_XTINY, statusStr, Graphics.TEXT_JUSTIFY_CENTER);


        // --- 8. НИЗ + КНОПКИ SAVE и DISCARD ---
        
        // Кнопка SAVE (справа внизу)
        if (mDataParams.isSessionActive) {
            var saveW = 38;
            var saveH = 17;
            var saveX = width - saveW - 4;
            var saveY = height - saveH - 28;
            
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.fillRoundedRectangle(saveX, saveY, saveW, saveH, 2);
            
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(saveX + saveW/2, saveY + saveH/2 - 1, Graphics.FONT_XTINY, "save", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        
        // Кнопка DISCARD (слева внизу, только в первом раунде)
        if (mDataParams.isSessionActive && mDataParams.round == 1) {
            var discardW = 38;
            var discardH = 17;
            var discardX = 4;
            var discardY = height - discardH - 28;
            
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.fillRoundedRectangle(discardX, discardY, discardW, discardH, 2);
            
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(discardX + discardW/2, discardY + discardH/2 - 1, Graphics.FONT_XTINY, "cncl", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Данные (Температура и Общее время)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var tVal = mDataParams.temperature;
        var tStr = "--";
        if (tVal != null && tVal != 0.0) { tStr = tVal.format("%.0f"); }
        var totalMin = mDataParams.totalDuration / 60;
        
        var bottomStr = "T:" + tStr + "°  Σ " + totalMin + "min";
        // Увеличенный размер, позиция не пересекается с ROUND
        dc.drawText(halfW - 15, 133, Graphics.FONT_TINY, bottomStr, Graphics.TEXT_JUSTIFY_CENTER);
    }
}