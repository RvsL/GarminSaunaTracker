import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Activity;
import Toybox.Math;

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


        // --- 5. ВРЕМЯ СУТОК (Слева) ---
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var timeStr = Lang.format("$1$:$2$", [today.hour, today.min.format("%02d")]);
        // Чуть опустил (Y=38), чтобы не конфликтовать с SAUNA наверху
        dc.drawText(22, 38, Graphics.FONT_MEDIUM, timeStr, Graphics.TEXT_JUSTIFY_LEFT);


        // --- 6. ТАЙМЕР (Центр) ---
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


        // --- 8. НИЗ + КНОПКА SAVE ---
        
        // Кнопка SAVE
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

        // Данные (Температура и Общее время)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var tVal = mDataParams.temperature; 
        var tStr = "--";
        if (tVal != null && tVal != 0.0) { tStr = tVal.format("%.0f"); }
        var totalMin = mDataParams.totalDuration / 60;
        
        var bottomStr = "T:" + tStr + "°  Σ " + totalMin + "min";
        // Смещаем левее (halfW - 15)
        dc.drawText(halfW - 15, 138, Graphics.FONT_XTINY, bottomStr, Graphics.TEXT_JUSTIFY_CENTER);
    }
}