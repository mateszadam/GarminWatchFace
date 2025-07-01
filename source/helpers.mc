import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Time;
import Toybox.ActivityMonitor;
import Toybox.Position;
import Toybox.Math;
import Toybox.Activity;

class CostumeHelpers extends WatchUi.WatchFace {
	function initialize() {
		WatchFace.initialize();
	}
	function getSunTimes() {
		var value = "";

		// Then in your function:
		var location = null;
		try {
			if (Toybox has :Activity && Activity has :getActivityInfo) {
				var info = Activity.getActivityInfo();
				if (info != null) {
					location = info.currentLocation;
				}
			}

			// Fallback to Position if activity location is unavailable
			if (location == null && Toybox has :Position) {
				var posInfo = Position.getInfo();
				if (posInfo != null && posInfo.position != null) {
					location = posInfo.position;
				}
			}
		} catch (ex) {
			// Sys.println("Error getting location: " + ex);
			// If we can't get the location, we will return "gps?".
			// Sys.println("Using fallback location.");
			location = null; // Reset to null if an error occurs.
		}
		var gLocationLat = null;
		var gLocationLng = null;

		if (location != null) {
			// Sys.println("Saving location");
			location = location.toDegrees(); // Array of Doubles.
			gLocationLat = location[0].toFloat();
			gLocationLng = location[1].toFloat();
		}
		var sunTimes = [null, null]; // [sunrise, sunset]
		var result = {};
		if (gLocationLat != null) {
			var nextSunEvent = 0;
			var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

			// Convert to same format as sunTimes, for easier comparison. Add a minute, so that e.g. if sun rises at
			// 07:38:17, then 07:38 is already consided daytime (seconds not shown to user).
			now = now.hour + (now.min + 1) / 60.0;

			// Get today's sunrise/sunset times in current time zone.
			sunTimes = getSunTimes2(
				gLocationLat,
				gLocationLng,
				null,
				/* tomorrow */ false
			);
			//Sys.println(sunTimes);

			// If sunrise/sunset happens today.
			var sunriseSunsetToday = sunTimes[0] != null && sunTimes[1] != null;
			if (sunriseSunsetToday) {
				// Before sunrise today: today's sunrise is next.
				if (now < sunTimes[0]) {
					nextSunEvent = sunTimes[0];
					result["isSunriseNext"] = true;

					// After sunrise today, before sunset today: today's sunset is next.
				} else if (now < sunTimes[1]) {
					nextSunEvent = sunTimes[1];

					// After sunset today: tomorrow's sunrise (if any) is next.
				} else {
					sunTimes = getSunTimes2(
						gLocationLat,
						gLocationLng,
						null,
						/* tomorrow */ true
					);
					nextSunEvent = sunTimes[0];
					result["isSunriseNext"] = true;
				}
			}

			// Sun never rises/sets today.
			if (!sunriseSunsetToday) {
				value = "---";

				// Sun never rises: sunrise is next, but more than a day from now.
				if (sunTimes[0] == null) {
					result["isSunriseNext"] = true;
				}

				// We have a sunrise/sunset time.
			} else {
				var hour = Math.floor(nextSunEvent).toLong() % 24;
				var min = Math.floor((nextSunEvent - Math.floor(nextSunEvent)) * 60); // Math.floor(fractional_part * 60)
				if (min < 10) {
					min = "0" + min.toString().substring(0, 1); // Add leading zero if minutes are less than 10.
				} else {
					min = min.toString().substring(0, 2); // Convert to string for concatenation.
				}
				value = hour + ":" + min;
			}

			// Waiting for location.
		} else {
			value = "gps?";
		}
		return value;
	}

	private function getSunTimes2(lat, lng, tz, tomorrow) as Array<Number?> {
		// Use double precision where possible, as floating point errors can affect result by minutes.
		lat = lat.toDouble();
		lng = lng.toDouble();

		var now = Time.now();
		if (tomorrow) {
			now = now.add(new Time.Duration(24 * 60 * 60));
		}
		var d = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		var rad = Math.PI / 180.0d;
		var deg = 180.0d / Math.PI;

		// Calculate Julian date from Gregorian.
		var a = Math.floor((14 - d.month) / 12);
		var y = d.year + 4800 - a;
		var m = d.month + 12 * a - 3;
		var jDate =
			d.day +
			Math.floor((153 * m + 2) / 5) +
			365 * y +
			Math.floor(y / 4) -
			Math.floor(y / 100) +
			Math.floor(y / 400) -
			32045;

		// Number of days since Jan 1st, 2000 12:00.
		var n = jDate - 2451545.0d + 0.0008d;
		//Sys.println("n " + n);

		// Mean solar noon.
		var jStar = n - lng / 360.0d;
		//Sys.println("jStar " + jStar);

		// Solar mean anomaly.
		var M = 357.5291d + 0.98560028d * jStar;
		var MFloor = Math.floor(M);
		var MFrac = M - MFloor;
		M = MFloor.toLong() % 360;
		M += MFrac;
		//Sys.println("M " + M);

		// Equation of the centre.
		var C =
			1.9148d * Math.sin(M * rad) +
			0.02d * Math.sin(2 * M * rad) +
			0.0003d * Math.sin(3 * M * rad);
		//Sys.println("C " + C);

		// Ecliptic longitude.
		var lambda = M + C + 180 + 102.9372d;
		var lambdaFloor = Math.floor(lambda);
		var lambdaFrac = lambda - lambdaFloor;
		lambda = lambdaFloor.toLong() % 360;
		lambda += lambdaFrac;
		//Sys.println("lambda " + lambda);

		// Solar transit.
		var jTransit =
			2451545.5d +
			jStar +
			0.0053d * Math.sin(M * rad) -
			0.0069d * Math.sin(2 * lambda * rad);
		//Sys.println("jTransit " + jTransit);

		// Declination of the sun.
		var delta = Math.asin(Math.sin(lambda * rad) * Math.sin(23.44d * rad));
		//Sys.println("delta " + delta);

		// Hour angle.
		var cosOmega =
			(Math.sin(-0.83d * rad) - Math.sin(lat * rad) * Math.sin(delta)) /
			(Math.cos(lat * rad) * Math.cos(delta));
		//Sys.println("cosOmega " + cosOmega);

		// Sun never rises.
		if (cosOmega > 1) {
			return [null, -1];
		}

		// Sun never sets.
		if (cosOmega < -1) {
			return [-1, null];
		}

		// Calculate times from omega.
		var omega = Math.acos(cosOmega) * deg;
		var jSet = jTransit + omega / 360.0;
		var jRise = jTransit - omega / 360.0;
		var deltaJSet = jSet - jDate;
		var deltaJRise = jRise - jDate;

		var tzOffset =
			tz == null ? System.getClockTime().timeZoneOffset / 3600 : tz;
		return [
			/* localRise */ deltaJRise * 24 + tzOffset,
			/* localSet */ deltaJSet * 24 + tzOffset,
		];
	}

	function getPressure() {
		var pressure = 0.0;
		var sample = null;

		if (
			Toybox has :SensorHistory &&
			Toybox.SensorHistory has :getPressureHistory
		) {
			sample = SensorHistory.getPressureHistory(null).next();
			if (sample != null && sample.data != null) {
				pressure = sample.data;
			}
		}
		return pressure;
	}
	function getHR() {
		var value = 0;
		var activityInfo = Activity.getActivityInfo();
		var sample = activityInfo.currentHeartRate;
		if (sample != null) {
			value = sample;
		} else if (ActivityMonitor has :getHeartRateHistory) {
			sample = ActivityMonitor.getHeartRateHistory(1, true).next();
			if (
				sample != null &&
				sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE
			) {
				value = sample.heartRate;
			}
		}
		return value;
	}
}
