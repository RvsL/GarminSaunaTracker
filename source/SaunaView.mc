import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Activity; // <--- Добавили импорт Activity

class SaunaView extends WatchUi.View {

    var mDataParams;

    function initialize(params) {
        View.initialize();
        mDataParams = params;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        // --- ПОДСТРАХОВКА ДАННЫХ ---
        // Если датчики молчат (как часто бывает в симуляторе),
        // берем данные напрямую из Activity Info
        var info = Activity.getActivityInfo();
        var currentHR = mDataParams.heartRate;
        
        // Если в данных пусто или 0, пробуем взять у системы
        if (currentHR == 0 && info != null && info.currentHeartRate != null) {
            currentHR = info.currentHeartRate;
        }

        // --- ОТРИСОВКА ---
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();   
        var height = dc.getHeight(); 

        // 1. ПУЛЬС В "ГЛАЗУ"
        var hrStr = (currentHR > 0) ? currentHR.toString() : "--";
        dc.drawText(123, 36, Graphics.FONT_NUMBER_MILD, hrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 2. ВРЕМЯ
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var timeStr = Lang.format("$1$:$2$", [today.hour, today.min.format("%02d")]);
        dc.drawText(20, 35, Graphics.FONT_MEDIUM, timeStr, Graphics.TEXT_JUSTIFY_LEFT);

        // 3. ТАЙМЕР
        var t = mDataParams.timeLeft;
        var absT = (t < 0) ? -t : t; 
        var min = absT / 60;
        var sec = absT % 60;
        var timerStr = Lang.format("$1$:$2$", [min, sec.format("%02d")]);
        if (t < 0) { timerStr = "-" + timerStr; }

        dc.drawText(width / 2, 80, Graphics.FONT_NUMBER_HOT, timerStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 4. СТАТУС
        var statusStr = "PRESS GPS";
        if (mDataParams.isSessionActive) {
            if (mDataParams.isSaunaMode) {
                statusStr = "SAUNA #" + mDataParams.round;
            } else {
                statusStr = "-- REST --";
            }
        } else {
            statusStr = "SET: " + (mDataParams.durationConfig/60) + " MIN";
        }
        dc.drawText(width / 2, 105, Graphics.FONT_XTINY, statusStr, Graphics.TEXT_JUSTIFY_CENTER);

        // 5. НИЗ (Температура)
        // Для температуры тоже пробуем взять из системы, если датчик молчит
        var tVal = mDataParams.temperature; 
        // В симуляторе температура часто 0.0, если не настроена
        
        var tStr = "--";
        if (tVal != null && tVal != 0.0) {
            tStr = tVal.format("%.0f");
        }
        
        var totalMin = mDataParams.totalDuration / 60;
        var bottomStr = "T:" + tStr + "° | Σ " + totalMin + "min";
        
        dc.drawText(width / 2, 135, Graphics.FONT_XTINY, bottomStr, Graphics.TEXT_JUSTIFY_CENTER);
    }
}