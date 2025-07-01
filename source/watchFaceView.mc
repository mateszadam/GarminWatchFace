import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Time;
import Toybox.Weather;
import Toybox.Position;

class watchFaceView extends WatchUi.WatchFace {
	hidden var weather as Weather.CurrentConditions;
	hidden var costumeHelpers as CostumeHelpers;
	hidden var sunTime as String;
	hidden var battery as Number;
	hidden var batteryColor as Graphics.ColorType;
	hidden var pressure as String;
	hidden var temperature as String;
	hidden var day as String;
	hidden var today as Time.Gregorian.Info;
	hidden var bodyBattery as String;

	function initialize() {
		WatchFace.initialize();

		weather = Weather.getCurrentConditions();
		costumeHelpers = new CostumeHelpers();
		sunTime = costumeHelpers.getSunTimes();
		battery = 0;
		batteryColor = Graphics.COLOR_WHITE;
		pressure = (costumeHelpers.getPressure() / 100).format("%.0f");
		temperature = weather.temperature.format("%.1f");
		today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		day =
			today.year +
			". " +
			today.month +
			". " +
			today.day +
			". " +
			Gregorian.info(Time.now(), Time.FORMAT_MEDIUM).day_of_week;
		bodyBattery = Toybox.SensorHistory.getBodyBatteryHistory({})
			.next()
			.data.format("%.0f");
	}

	// Load your resources here
	function onLayout(dc as Dc) as Void {
		setLayout(Rez.Layouts.WatchFace(dc));
	}

	// Called when this View is brought to the foreground. Restore
	// the state of this View and prepare it to be shown. This includes
	// loading resources into memory.
	function onShow() as Void {
		var battery = View.findDrawableById("Battery") as Battery;
		battery.refresh();
		weather = Weather.getCurrentConditions();
		costumeHelpers = new CostumeHelpers();
		sunTime = costumeHelpers.getSunTimes();
		battery = 0;
		batteryColor = Graphics.COLOR_WHITE;
		pressure = (costumeHelpers.getPressure() / 100).format("%.0f");
		temperature = weather.temperature.format("%.1f");
		today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		day =
			today.year +
			". " +
			today.month +
			". " +
			today.day +
			". " +
			Gregorian.info(Time.now(), Time.FORMAT_MEDIUM).day_of_week;
		bodyBattery = Toybox.SensorHistory.getBodyBatteryHistory({})
			.next()
			.data.format("%.0f");
	}

	// Update the view
	function onUpdate(dc as Dc) as Void {
		var info = ActivityMonitor.getInfo();
		today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

		try {
			var bodyBatt = View.findDrawableById("bodyBatt") as Text;
			bodyBatt.setText(info.stressScore + "");
		} catch (ex) {
			var bodyBatt = View.findDrawableById("bodyBatt") as Text;
			bodyBatt.setText("N/A");
		}
		try {
			var deg = View.findDrawableById("deg") as Text;
			deg.setText(temperature + "°C");
		} catch (ex) {
			// Sys.println("Error getting temperature: " + ex);
			var deg = View.findDrawableById("deg") as Text;
			deg.setText("N/A");
		}
		try {
			var calories = View.findDrawableById("calories") as Text;
			calories.setText(pressure);
		} catch (ex) {
			// Sys.println("Error getting pressure: " + ex);
			var calories = View.findDrawableById("calories") as Text;
			calories.setText("N/A");
		}
		try {
			var dayField = View.findDrawableById("day") as Text;
			if (today.month == 7 && today.day == 4) {
				dayField.setText("Boldog szülinapot!");
			} else {
				dayField.setText(day);
			}
		} catch (ex) {
			// Sys.println("Error getting date: " + ex);
			var day = View.findDrawableById("day") as Text;
			day.setText("N/A");
		}
		try {
			var min =
				today.min > 0 ? (today.min < 10 ? "0" + today.min : today.min) : "00";
			var time = View.findDrawableById("time") as Text;
			time.setText(today.hour + ":" + min);
		} catch (ex) {
			// Sys.println("Error getting time: " + ex);
			var time = View.findDrawableById("time") as Text;
			time.setText("00:00");
		}
		try {
			var sun = View.findDrawableById("sun") as Text;
			sun.setText(sunTime + "");
		} catch (ex) {
			// Sys.println("Error getting sunrise/sunset: " + ex);
			var sun = View.findDrawableById("sun") as Text;
			sun.setText("N/A");
		}
		try {
			var levels = View.findDrawableById("levels") as Text;
			levels.setText(info.floorsClimbed + "");
		} catch (ex) {
			// Sys.println("Error getting floors climbed: " + ex);
			var levels = View.findDrawableById("levels") as Text;
			levels.setText("N/A");
		}
		try {
			var heartRate = View.findDrawableById("heartRate") as Text;
			heartRate.setText(costumeHelpers.getHR() + "");
		} catch (ex) {
			// Sys.println("Error getting heart rate: " + ex);
			var heartRate = View.findDrawableById("heartRate") as Text;
			heartRate.setText("N/A");
		}
		try {
			var bodyPower = View.findDrawableById("bodyPower") as Text;
			bodyPower.setText(bodyBattery + "");
		} catch (ex) {
			// Sys.println("Error getting body battery: " + ex);
			var bodyPower = View.findDrawableById("bodyPower") as Text;
			bodyPower.setText("N/A");
		}
		try {
			var steps = View.findDrawableById("steps") as Text;
			steps.setText(info.steps + "");
		} catch (ex) {
			// Sys.println("Error getting steps: " + ex);
			var steps = View.findDrawableById("steps") as Text;
			steps.setText("N/A");
		}
		try {
			var calories = View.findDrawableById("calorie") as Text;
			calories.setText(info.calories + "");
		} catch (ex) {
			// Sys.println("Error getting calories: " + ex);
			var calories = View.findDrawableById("calorie") as Text;
			calories.setText("N/A");
		}
		try {
			// manage bluetooth icon
			var bluetoothIcon = View.findDrawableById("bluetoothIcon") as Bitmap;
			if (System.getDeviceSettings().phoneConnected) {
				bluetoothIcon.setBitmap(Rez.Drawables.bluetooth);
			} else {
				bluetoothIcon.setBitmap(Rez.Drawables.bluetoothOff);
			}
		} catch (ex) {
			// Sys.println("Error getting bluetooth icon: " + ex);
			var bluetoothIcon = View.findDrawableById("bluetoothIcon") as Bitmap;
			bluetoothIcon.setBitmap(Rez.Drawables.bluetoothOff);
		}

		// manage notification icon
		try {
			var notificationIcon =
				View.findDrawableById("notificationIcon") as Bitmap;
			if (System.getDeviceSettings().notificationCount > 0) {
				notificationIcon.setVisible(true);
			} else {
				notificationIcon.setVisible(false);
			}
		} catch (ex) {
			// Sys.println("Error getting notification icon: " + ex);
			var notificationIcon =
				View.findDrawableById("notificationIcon") as Bitmap;
			notificationIcon.setVisible(false);
		}
		// manage alarm icon
		try {
			var alarmIcon = View.findDrawableById("alarm") as Bitmap;
			if (System.getDeviceSettings().alarmCount > 0) {
				alarmIcon.setVisible(true);
			} else {
				alarmIcon.setVisible(false);
			}
		} catch (ex) {
			// Sys.println("Error getting alarm icon: " + ex);
			var alarmIcon = View.findDrawableById("alarm") as Bitmap;
			alarmIcon.setVisible(false);
		}

		// sunset
		View.onUpdate(dc);
	}

	// Called when this View is removed from the screen. Save the
	// state of this View here. This includes freeing resources from
	// memory.
	function onHide() as Void {}

	// The user has just looked at their watch. Timers and animations may be started here.
	function onExitSleep() as Void {}

	// Terminate any active timers and prepare for slow updates.
	function onEnterSleep() as Void {}
}
class Battery extends WatchUi.Drawable {
	hidden var batteryColor as Graphics.ColorType;
	hidden var batteryLevel as Number;

	function initialize(params) {
		Drawable.initialize(params);
		batteryColor = Graphics.COLOR_WHITE;
		batteryLevel = 0;
		refresh();
	}

	public function refresh() as Void {
		if (System.getSystemStats().battery < 25) {
			batteryColor = Graphics.COLOR_RED;
		} else if (System.getSystemStats().battery < 50) {
			batteryColor = Graphics.COLOR_ORANGE;
		} else {
			batteryColor = Graphics.COLOR_GREEN;
		}
		var a = System.getSystemStats().battery;

		batteryLevel = Math.floor(
			360 * ((100 - System.getSystemStats().battery) / 100)
		);

		if (batteryLevel < 0) {
			batteryLevel = 0;
		} else if (batteryLevel > 360) {
			batteryLevel = 360;
		}
	}

	function draw(dc as Dc) as Void {
		dc.setPenWidth(38);
		// 90 et mindig hozzá kell adni és akkor jó :)

		dc.setColor(batteryColor, Graphics.COLOR_TRANSPARENT);
		dc.drawArc(227, 227, 227, Graphics.ARC_CLOCKWISE, 0, 360);

		dc.setPenWidth(40);

		dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
		dc.drawArc(
			227,
			227,
			227,
			Graphics.ARC_COUNTER_CLOCKWISE,
			90,
			batteryLevel + 90
		);

		dc.clear();
	}
}

class Lines extends WatchUi.Drawable {
	function initialize(params) {
		Drawable.initialize(params);
	}

	function draw(dc as Dc) as Void {
		dc.setPenWidth(3);
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawLine(0, 70, 500, 70);
		dc.drawLine(0, 105, 500, 105);

		dc.drawLine(0, 140, 500, 140);
		dc.drawLine(0, 314, 500, 314);
		dc.drawLine(0, 384, 500, 384);
		dc.drawLine(227, 70, 227, 105);
		dc.drawLine(227, 314, 227, 384);

		dc.clear();
	}
}
