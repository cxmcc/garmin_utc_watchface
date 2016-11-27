using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;

class InsaneTime {
    var year;
    var month;
    var day;
    var hour;
    var minute;
    var second;

    function initialize() {
        year = 9999;
        month = 99;
        day = 99;
        hour = 99;
        minute = 99;
        second = 99;
    }
}

class InsaneClock {
    hidden var offset;
    hidden var localTime;
    hidden var utcTime;

    function initialize() {
        localTime = new InsaneTime();
        utcTime = new InsaneTime();
        offset = 0;
        refresh();
    }

    function refresh() {
        var localTimeNow = Time.now();
        var localClock = Sys.getClockTime();

        var offsetSec = localClock.timeZoneOffset;
        offset = offsetSec / 3600;

        var localCalInfo = Calendar.info(localTimeNow, Time.FORMAT_SHORT);
        var utcTimeNow = localTimeNow.add(new Time.Duration(-offsetSec));
        var utcCalInfo = Calendar.info(utcTimeNow, Time.FORMAT_SHORT);
        
        // Local
        localTime.year = localCalInfo.year;
        localTime.month = localCalInfo.month;
        localTime.day = localCalInfo.day;
        localTime.hour = localClock.hour;
        localTime.minute = localClock.min;
        localTime.second = localClock.sec;
        
        // UTC
        utcTime.year = utcCalInfo.year;
        utcTime.month = utcCalInfo.month;
        utcTime.day = utcCalInfo.day;
        utcTime.hour = (localClock.hour - offset + 24) % 24;
        utcTime.minute = localClock.min;
        utcTime.second = localClock.sec;   
    }

    function second() {
        return utcTime.second;
    }

    function generateTimeStr(time) {
        return Lang.format(
            "$1$:$2$",
            [time.hour.format("%02d"),
             time.minute.format("%02d")]
        );
    }

    function localTimeStr() {
        return generateTimeStr(localTime);
    }

    function utcTimeStr() {
        return generateTimeStr(utcTime);
    }

    function generateDateStr(offset, time) {
        var offsetStr = "";
        if (offset >= 0) {
            offsetStr = Lang.format("+$1$", [offset]);
        } else {
            offsetStr = Lang.format("$1$", [offset]);
        }
        var dateFormat = App.getApp().getProperty("PropertyDateFormat");
        var choices = {
            0=>"$2$/$3$/$4$",
            1=>"$3$/$2$/$4$",
            2=>"$4$/$2$/$3$"
        };
        return Lang.format(
            "UTC$1$\n" + choices[dateFormat],
            [offsetStr,
             time.month.format("%02d"),
             time.day.format("%02d"),
             time.year.format("%02d")]
        );
    }

    function localDateStr() {
        return generateDateStr(offset, localTime);
    }

    function utcDateStr() {
        return generateDateStr(0, utcTime);
    }
}

class UTCWatchfaceView extends Ui.WatchFace {

    const rightCenter = Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER;
    const leftCenter = Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER;
    const centerCenter = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;
    var lowPower;
    var ic;

    function initialize() {
        WatchFace.initialize();
        ic = new InsaneClock();
        lowPower = false;
    }

    //! Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
        lowPower = false;
        requestUpdate();
    }

    function clearScreen(dc) {
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
    }

    function drawBattery(dc, x, y) {
        var stats = Sys.getSystemStats();
        if (stats.battery > 15) {
            dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
        }
        var batteryStr = Lang.format("$1$%", [stats.battery.format("%d")]);
        dc.drawText(x, y, Gfx.FONT_MEDIUM, batteryStr, centerCenter);
    }

    //! Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        ic.refresh();

        // Get and show the current time
        var width = dc.getWidth();
        var height = dc.getHeight();
        var w = width/100.0;
        var h = height/100.0;

        clearScreen(dc);

        // Battery
        drawBattery(dc, w*50, h*11);

        // White
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w*56, h*34, Gfx.FONT_NUMBER_HOT, ic.localTimeStr(), rightCenter);
        dc.drawText(w*56, h*64, Gfx.FONT_NUMBER_HOT, ic.utcTimeStr(), rightCenter);
        if (!lowPower) {
            var secondStr = ic.second().format("%02d");
            dc.drawText(w*50, h*89, Gfx.FONT_MEDIUM, secondStr, centerCenter);
        }

        // Gray
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w*59, h*35, Gfx.FONT_XTINY, ic.localDateStr(), leftCenter);
        dc.drawText(w*59, h*65, Gfx.FONT_XTINY, ic.utcDateStr(), leftCenter);
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
        lowPower = false;
        requestUpdate();
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
        lowPower = true;
        requestUpdate();
    }

}
