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
        
        // 1. ПОЛУЧЕНИЕ ДАННЫХ (с подстраховкой для симулятора)
        var info = Activity.getActivityInfo();
        var currentHR = mDataParams.heartRate;
        if (currentHR == 0 && info != null && info.currentHeartRate != null) {
            currentHR = info.currentHeartRate;
        }

        // 2. ОЧИСТКА
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();   // 156
        var height = dc.getHeight(); // 156
        var halfW = width / 2;

        // --- 3. ИНДИКАТОР ПРОГРЕССА (Дуга) ---
        // Рисуем только в режиме Сауны и пока время положительное
        if (mDataParams.isSessionActive && mDataParams.isSaunaMode && mDataParams.timeLeft > 0) {
            var radius = (width / 2) - 3; // Чуть меньше края экрана
            dc.setPenWidth(4);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            
            // Считаем угол
            // Таймлефт уменьшается. 100% -> полный круг. 0% -> пусто.
            var percent = mDataParams.timeLeft.toFloat() / mDataParams.durationConfig.toFloat();
            
            // В Garmin 0 градусов = 3 часа. 90 = 12 часов.
            // Рисуем против часовой (COUNTER_CLOCKWISE) от 12 часов (90 deg)
            var startAngle = 90; 
            var endAngle = 90 + (360 * percent);
            
            dc.drawArc(halfW, height/2, radius, Graphics.ARC_COUNTER_CLOCKWISE, startAngle, endAngle);
            
            // Вернем цвет для текста
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }

        // --- 4. ПУЛЬС В "ГЛАЗУ" ---
        // Чуть сдвинул правее и ниже, и шрифт поменьше
        var hrStr = (currentHR > 0) ? currentHR.toString() : "--";
        // Центр глаза ~ (125, 40)
        dc.drawText(126, 42, Graphics.FONT_SMALL, hrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- 5. ВРЕМЯ СУТОК (Слева вверху) ---
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var timeStr = Lang.format("$1$:$2$", [today.hour, today.min.format("%02d")]);
        dc.drawText(20, 35, Graphics.FONT_MEDIUM, timeStr, Graphics.TEXT_JUSTIFY_LEFT);

        // --- 6. ТАЙМЕР (Центр) ---
        var t = mDataParams.timeLeft;
        // Если t < 0 (пересидели в сауне), делаем положительным для отсчета "минут после"
        // Если это отдых, t идет вверх от 0, тоже положительное.
        var absT = (t < 0) ? -t : t; 
        
        var min = absT / 60;
        var sec = absT % 60;
        var timerStr = Lang.format("$1$:$2$", [min, sec.format("%02d")]);
        
        // Если пересиживаем в сауне (время вышло), добавим "+" спереди для наглядности
        if (mDataParams.isSaunaMode && t < 0) {
            timerStr = "+" + timerStr;
        }

        dc.drawText(halfW, 80, Graphics.FONT_NUMBER_HOT, timerStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- 7. СТАТУС (Над таймером) ---
        var statusStr = "";
        if (mDataParams.isSessionActive) {
            if (mDataParams.isSaunaMode) {
                statusStr = "SAUNA #" + mDataParams.round;
                // Если пересидел
                if (mDataParams.timeLeft < 0) { statusStr = "OVERTIME"; }
            } else {
                statusStr = "- REST -";
            }
        } else {
            // До старта
            statusStr = "SET: " + (mDataParams.durationConfig/60) + " MIN";
        }
        dc.drawText(halfW, 108, Graphics.FONT_XTINY, statusStr, Graphics.TEXT_JUSTIFY_CENTER);

        // --- 8. НИЗ (Температура + Метка кнопки SAVE) ---
        
        // Температура
        var tVal = mDataParams.temperature; 
        var tStr = "--";
        if (tVal != null && tVal != 0.0) { tStr = tVal.format("%.0f"); }
        
        // Метка для кнопки BACK (Save) - справа внизу
        // Кнопка BACK находится примерно на 4-5 часов
        // Рисуем текст "SAVE" у края
        if (mDataParams.isSessionActive) {
            // Рисуем темным фоном или просто текст
            dc.drawText(width - 25, height - 35, Graphics.FONT_XTINY, "SAVE", Graphics.TEXT_JUSTIFY_RIGHT);
        }

        // Инфо строка по центру внизу
        var totalMin = mDataParams.totalDuration / 60;
        var bottomStr = "T:" + tStr + "° | Σ " + totalMin + "min";
        
        // Чуть сдвигаем влево, чтобы не наехать на SAVE
        dc.drawText(halfW - 10, 135, Graphics.FONT_XTINY, bottomStr, Graphics.TEXT_JUSTIFY_CENTER);
    }
}