import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.System;

// Глобальный класс данных
class SaunaData {
    public var heartRate = 0;
    public var temperature = 0.0f;
    
    public var durationConfig = 900; // Настройка (по умолчанию 15 мин)
    public var timeLeft = 900;       // Текущий счетчик
    
    public var totalDuration = 0;
    public var round = 0;
    public var isSaunaMode = true;   // true = Сауна, false = Отдых
    public var isSessionActive = false; // Запущена ли таймером активность
}

class SaunaApp extends Application.AppBase {

    var mData = new SaunaData();

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        try {
           Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE, Sensor.SENSOR_TEMPERATURE]);
           Sensor.enableSensorEvents(method(:onSensor));
        } catch(e) {
           System.println("Err: " + e.getErrorMessage());
        }
    }

    function onStop(state as Dictionary?) as Void {
        Sensor.setEnabledSensors([]);
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new SaunaView(mData), new SaunaDelegate(mData) ];
    }

    function onSensor(sensorInfo as Sensor.Info) as Void {
        if (sensorInfo.heartRate != null) { mData.heartRate = sensorInfo.heartRate; }
        if (sensorInfo.temperature != null) { mData.temperature = sensorInfo.temperature; }
    }
}