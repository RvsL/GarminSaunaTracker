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
        
        timer = new Timer.Timer();
        timer.start(method(:onTimerTick), 1000, true);
    }

    function onTimerTick() as Void {
        if (session != null && session.isRecording()) {
            mData.totalDuration++;
            
            if (mData.isSaunaMode) {
                // --- РЕЖИМ САУНЫ ---
                // Таймер идет вниз
                if (mData.timeLeft > 0) {
                    mData.timeLeft--;
                    // Если вдруг пришло к нулю именно сейчас
                    if (mData.timeLeft == 0) {
                        vibrateLong(); // БЗЗЗЗЗ! Время вышло
                    }
                } else {
                    // Если уже 0 или меньше (пересиживаем)
                    // Уменьшаем дальше в минус (будет -1, -2...),
                    // во View мы покажем это как положительное время пересиживания.
                    mData.timeLeft--; 
                }
            } else {
                // --- РЕЖИМ ОТДЫХА ---
                // Таймер идет вверх
                mData.timeLeft++;
            }
        }
        WatchUi.requestUpdate();
    }

    // --- КНОПКА GPS (СТАРТ / СМЕНА РЕЖИМА) ---
    function onSelect() as Boolean {
        if (session == null) {
            // ПЕРВЫЙ СТАРТ
            createSession();
            mData.isSessionActive = true;
            mData.isSaunaMode = true; 
            mData.timeLeft = mData.durationConfig; 
            mData.round = 1;
            vibrateShort();
        } 
        else {
            if (mData.isSaunaMode) {
                // Идем на ОТДЫХ
                mData.isSaunaMode = false;
                mData.timeLeft = 0; // Начинаем отдых с 0
            } else {
                // Идем в САУНУ
                mData.isSaunaMode = true;
                mData.timeLeft = mData.durationConfig; // Сброс на 15 мин (например)
                mData.round++;
            }
            vibrateShort();
        }
        return true;
    }

    // --- НАСТРОЙКА ВРЕМЕНИ (ДО СТАРТА) ---
    function onPreviousPage() as Boolean { return adjustTime(60); }
    
    function onNextPage() as Boolean {
        // DOWN button: Discard в Round 1, иначе настройка времени
        if (mData.isSessionActive && mData.round == 1) {
            System.println("DOWN button pressed - discarding session in Round 1");
            
            // Останавливаем сессию БЕЗ сохранения
            if (session != null) {
                session.stop();
                session.discard();
                System.println("Session discarded");
            }
            
            // Сбрасываем состояние
            session = null;
            mData.isSessionActive = false;
            mData.isSaunaMode = true;
            mData.round = 0;
            mData.totalDuration = 0;
            mData.timeLeft = mData.durationConfig;
            
            // Закрываем приложение
            System.println("Exiting app...");
            System.exit();
            return true;
        }
        
        // Если сессия не активна, настраиваем время
        return adjustTime(-60);
    }
    
    function adjustTime(seconds) as Boolean {
        if (session == null) {
            mData.durationConfig += seconds;
            if (mData.durationConfig < 60) { mData.durationConfig = 60; }
            mData.timeLeft = mData.durationConfig;
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    // --- КНОПКА ABC (DISCARD - ТОЛЬКО В ПЕРВОМ РАУНДЕ) ---
    function onMenu() as Boolean {
        System.println("ABC button pressed! Active: " + mData.isSessionActive + ", Round: " + mData.round);
        
        // Работает только в первом раунде сауны
        if (mData.isSessionActive && mData.round == 1) {
            System.println("Discarding session...");
            
            // Останавливаем сессию БЕЗ сохранения
            if (session != null) {
                session.stop();
                session.discard();
                System.println("Session discarded");
            }
            // Сбрасываем состояние
            session = null;
            mData.isSessionActive = false;
            mData.isSaunaMode = true;
            mData.round = 0;
            mData.totalDuration = 0;
            mData.timeLeft = mData.durationConfig;
            
            // Закрываем приложение
            System.println("Exiting app...");
            System.exit();
            return true; // Handled the event
        }
        System.println("ABC button ignored (not in round 1)");
        return false; // Not handled (not in round 1)
    }
    
    // --- КНОПКА BACK (СОХРАНИТЬ И ВЫЙТИ) ---
    function onBack() as Boolean {
        // Если сессия идет, завершаем её
        if (session != null) {
            session.stop();
            session.save();
        }
        // Закрываем приложение
        System.exit();
        // Удалён unreachable return true
    }
    
    function createSession() {
        try {
            session = ActivityRecording.createSession({
                :name => "Sauna",
                :sport => ActivityRecording.SPORT_TRAINING,
                :subSport => ActivityRecording.SUB_SPORT_STRENGTH_TRAINING
            });
            session.start();
        } catch(e) {
            System.println("Session Error");
        }
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