import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.System;

// Глобальный класс данных для обмена между View и Delegate
class SaunaData {
    public var heartRate = 0;
    public var temperature = 0.0f;
    public var timeLeft = 900; // 15 минут в секундах
    public var totalDuration = 0;
    public var round = 0;
    public var isSaunaMode = false;
}

class SaunaApp extends Application.AppBase {

    var mData = new SaunaData();

    function initialize() {
        AppBase.initialize();
    }

    // При запуске приложения
    function onStart(state as Dictionary?) as Void {
        // Включаем HR и Температуру
        try {
           Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE, Sensor.SENSOR_TEMPERATURE]);
           Sensor.enableSensorEvents(method(:onSensor));
        } catch(e) {
           System.println("Sensor Setup Error: " + e.getErrorMessage());
        }
    }

    function onStop(state as Dictionary?) as Void {
        Sensor.setEnabledSensors([]);
    }

    // Здесь мы возвращаем наш View и Delegate
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new SaunaView(mData), new SaunaDelegate(mData) ];
    }

    // Обработчик данных с сенсоров
    function onSensor(sensorInfo as Sensor.Info) as Void {
        if (sensorInfo.heartRate != null) {
            mData.heartRate = sensorInfo.heartRate;
        }
        if (sensorInfo.temperature != null) {
            mData.temperature = sensorInfo.temperature;
        }
    }
}