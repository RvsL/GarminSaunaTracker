import Toybox.WatchUi;
import Toybox.System;
import Toybox.Attention;
import Toybox.ActivityRecording;
import Toybox.Timer;
import Toybox.Lang;

class SaunaDelegate extends WatchUi.BehaviorDelegate {

    var mData;
    var session = null;
    var timer;

    function initialize(data) {
        BehaviorDelegate.initialize();
        mData = data;
        
        // Таймер тикает раз в секунду
        timer = new Timer.Timer();
        timer.start(method(:onTimerTick), 1000, true);
    }

    function onTimerTick() as Void {
        // Если сессия запущена - считаем время
        if (session != null && session.isRecording()) {
            mData.totalDuration++;
            
            // Логика обратного отсчета
            if (mData.timeLeft > 0) {
                mData.timeLeft--;
            } else if (mData.timeLeft == 0) {
                vibrateLong(); // 00:00 - вибрируем
                mData.timeLeft = -1; 
            } else {
                mData.timeLeft--; // Уходим в минус (показываем пересиживание)
            }
        }
        
        WatchUi.requestUpdate();
    }

    // --- КНОПКА GPS (СТАРТ / СЛЕДУЮЩИЙ РАУНД) ---
    function onSelect() as Boolean {
        if (session == null) {
            // 1. САМЫЙ ПЕРВЫЙ СТАРТ
            try {
                session = ActivityRecording.createSession({
                    :name => "Sauna",
                    :sport => ActivityRecording.SPORT_GENERIC,
                    :subSport => ActivityRecording.SUB_SPORT_GENERIC
                });
                session.start();
            } catch(e) {
                System.println("Session error");
            }
            
            mData.isSessionActive = true;
            mData.isSaunaMode = true; // Сразу попадаем в сауну
            mData.timeLeft = mData.durationConfig; 
            mData.round = 1;
            
            vibrateShort();
        } 
        else {
            // СЕССИЯ УЖЕ ИДЕТ - ПЕРЕКЛЮЧАЕМ РЕЖИМЫ
            if (mData.isSaunaMode) {
                // Был в Сауне -> Иду на ОТДЫХ
                mData.isSaunaMode = false;
                mData.timeLeft = 0; // Таймер отдыха считаем в «минус» (как секундомер)
            } else {
                // Был на Отдыхе -> Иду в САУНУ
                mData.isSaunaMode = true;
                mData.timeLeft = mData.durationConfig; // Сброс таймера на выбранное время
                mData.round++;
            }
            vibrateShort();
        }
        return true;
    }

    // --- НАСТРОЙКА ВРЕМЕНИ (Если сессия не идет) ---
    // Кнопка MENU/UP
    function onPreviousPage() as Boolean {
        return adjustTime(60); // +1 минута
    }
    // Кнопка ABC/DOWN
    function onNextPage() as Boolean {
        return adjustTime(-60); // -1 минута
    }
    
    function adjustTime(seconds) as Boolean {
        if (session == null) { // Менять можно только до старта
            mData.durationConfig += seconds;
            if (mData.durationConfig < 60) { mData.durationConfig = 60; } // Минимум 1 мин
            mData.timeLeft = mData.durationConfig;
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    // --- КНОПКА BACK (ВЫХОД) ---
    function onBack() as Boolean {
        if (session != null) {
            session.stop();
            session.save();
            session = null;
        }
        System.exit();
        return true;
    }
    
    function vibrateLong() {
        if (Attention has :vibrate) {
            Attention.vibrate([ new Attention.VibeProfile(100, 2000) ]);
        }
    }

    function vibrateShort() {
        if (Attention has :vibrate) {
            Attention.vibrate([ new Attention.VibeProfile(50, 200) ]);
        }
    }
}