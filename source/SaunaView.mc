import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

class SaunaView extends WatchUi.View {

    var mDataParams; 

    function initialize(params) {
        View.initialize();
        mDataParams = params;
    }

    // Вызывается системой при обновлении экрана
    function onUpdate(dc as Graphics.Dc) as Void {
        // Очистка экрана (Черный фон, Белый текст)
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();

        // 1. ВРЕМЯ ДНЯ (сверху)
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var timeString = Lang.format("$1$:$2$", [today.hour, today.min.format("%02d")]);
        dc.drawText(width / 2, 20, Graphics.FONT_XTINY, timeString, Graphics.TEXT_JUSTIFY_CENTER);

        // 2. ТАЙМЕР (По центру)
        var minutes = mDataParams.timeLeft / 60;
        var seconds = mDataParams.timeLeft % 60;
        var timerStr = Lang.format("$1$:$2$", [minutes, seconds.format("%02d")]);
        
        // Шрифт побольше для таймера
        dc.drawText(width / 2, height / 2 - 20, Graphics.FONT_NUMBER_HOT, timerStr, Graphics.TEXT_JUSTIFY_CENTER);

        // 3. Tемпература и Общее время (Снизу)
        var tempVal = (mDataParams.temperature != null) ? mDataParams.temperature : 0.0;
        var tempStr = tempVal.format("%.1f") + "C";
        
        var totalMin = mDataParams.totalDuration / 60;
        var bottomStr = tempStr + " | " + totalMin + " min";
        
        dc.drawText(width / 2, height - 50, Graphics.FONT_XTINY, bottomStr, Graphics.TEXT_JUSTIFY_CENTER);

        // 4. ПУЛЬС (В правом верхнем кружочке Instinct 2S)
        // Координаты для "глаза" примерно X=148, Y=25 (надо тестить в симуляторе)
        var hrStr = (mDataParams.heartRate != null) ? mDataParams.heartRate.toString() : "--";
        dc.drawText(width - 35, 30, Graphics.FONT_SYSTEM_NUMBER_MILD, hrStr, Graphics.TEXT_JUSTIFY_CENTER);
        
        // 5. СТАТУС (Rest / Sauna)
        var statusStr = (mDataParams.isSaunaMode) ? "SAUNA #" + mDataParams.round : "REST";
        dc.drawText(width / 2, height / 2 + 30, Graphics.FONT_XTINY, statusStr, Graphics.TEXT_JUSTIFY_CENTER);
    }
}