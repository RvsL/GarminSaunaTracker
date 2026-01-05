import Toybox.WatchUi;
import Toybox.System;
import Toybox.Attention;
import Toybox.ActivityRecording;
import Toybox.Timer;

class SaunaDelegate extends WatchUi.BehaviorDelegate {

    var mData; 
    var session = null; 
    var timer;   
    
    // 15 минут = 900 секунд
    const SAUNA_DURATION = 900; 

    function initialize(data) {
        BehaviorDelegate.initialize();
        mData = data;
        
        // Запускаем таймер, тикающий каждую секунду
        timer = new Timer.Timer();
        timer.start(method(:onTimerTick), 1000, true);
    }

    function onTimerTick() as Void {
        // Увеличиваем общее время, если сессия идет
        if (session != null && session.isRecording()) {
            mData.totalDuration++;
            
            // Логика таймера обратного отсчета
            if (mData.timeLeft > 0) {
                mData.timeLeft--;
            } else if (mData.timeLeft == 0) {
                // Таймер истек
                vibrate(); 
                mData.timeLeft = -1; // Чтобы вибрировал один раз и уходил в минус
            }
        }
        // Обновляем экран
        WatchUi.requestUpdate();
    }

    // Кнопка START / SELECT (Верхняя правая)
    function onSelect() as Toybox.Lang.Boolean {
        if (session == null) {
            // ПЕРВЫЙ СТАРТ
            session = ActivityRecording.createSession({
                :name => "Sauna",
                :sport => ActivityRecording.SPORT_GENERIC, 
                :subSport => ActivityRecording.SUB_SPORT_GENERIC
            });
            session.start();
            vibrateShort();
            startSaunaRound();
        } 
        else if (mData.isSaunaMode) {
            // ВЫШЕЛ ИЗ САУНЫ -> ПЕРЕРЫВ
            mData.isSaunaMode = false;
            mData.timeLeft = 0; // Сбрасываем таймер
            vibrateShort();
        } 
        else {
            // БЫЛ НА ПЕРЕРЫВЕ -> ЗАШЕЛ В САУНУ
            startSaunaRound();
            vibrateShort();
        }
        return true;
    }

    function startSaunaRound() {
        mData.isSaunaMode = true;
        mData.timeLeft = SAUNA_DURATION; 
        mData.round++;
    }

    // Кнопка BACK (Нижняя правая)
    function onBack() as Toybox.Lang.Boolean {
        if (session != null) {
            session.stop();
            session.save();
            session = null;
        }
        System.exit(); 
        return true;
    }
    
    // Длинная вибрация (когда таймер истек)
    function vibrate() {
        if (Attention has :vibrate) {
            var vibeData = [ new Attention.VibeProfile(100, 2000) ];
            Attention.vibrate(vibeData);
        }
    }

    // Короткая вибрация (подтверждение кнопки)
    function vibrateShort() {
        if (Attention has :vibrate) {
            var vibeData = [ new Attention.VibeProfile(50, 100) ];
            Attention.vibrate(vibeData);
        }
    }
}