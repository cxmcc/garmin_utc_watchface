using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;

class UTCWatchfaceView extends Ui.WatchFace {
    var lowPower;

    function initialize() {
        WatchFace.initialize();
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
        dc.fillRectangle(0,0,dc.getWidth(), dc.getHeight());
    }

    function drawBattery(dc, x, y) {
        var stats = Sys.getSystemStats();
        if (stats.battery > 15) {
            dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
        }
        var batteryStr = Lang.format("$1$%", [stats.battery.format("%d")]);
        dc.drawText(
            x, y, Gfx.FONT_MEDIUM, batteryStr,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    }

    //! Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        // Get and show the current time
        var localTime = Time.now();
        var localClock = Sys.getClockTime();

        var offsetSec = Sys.getClockTime().timeZoneOffset;
        var offset = offsetSec/3600;

        var utcTime = localTime.add(new Time.Duration(-offsetSec));
        var utcHour = (localClock.hour - offset) % 24;

        var width = dc.getWidth();
        var height = dc.getHeight();
        var w = width/100.0;
        var h = height/100.0;

        clearScreen(dc);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);

        var localTimeStr = Lang.format(
            "$1$:$2$",
            [localClock.hour.format("%02d"), localClock.min.format("%02d")]
        );
        var info = Calendar.info(localTime, Time.FORMAT_SHORT);
        var offsetStr = Lang.format("$1$", [offset]);
        if (offset == 0) {
            offsetStr = "+0";
        }
        var localDateStr = Lang.format(
            "UTC$1$\n$2$/$3$/$4$",
            [offset, info.month.format("%02d"), info.day.format("%02d"), info.year.format("%02d")]
        );

        var utcTimeStr = Lang.format(
            "$1$:$2$",
            [utcHour.format("%02d"), localClock.min.format("%02d")]
        );
        info = Calendar.info(utcTime, Time.FORMAT_SHORT);
        var utcDateStr = Lang.format(
            "UTC+0\n$1$/$2$/$3$",
            [info.month.format("%02d"), info.day.format("%02d"), info.year.format("%02d")]
        );

        if (!lowPower) {
            dc.drawText(
                w*50, h*89, Gfx.FONT_MEDIUM, localClock.sec.format("%02d"),
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
            );
        }
        drawBattery(dc, w*50, h*11);

        dc.drawText(
            w*56, h*34, Gfx.FONT_NUMBER_HOT, localTimeStr,
            Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
            w*56, h*64, Gfx.FONT_NUMBER_HOT, utcTimeStr,
            Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER
        );

        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            w*59, h*35, Gfx.FONT_XTINY, localDateStr,
            Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
            w*59, h*65, Gfx.FONT_XTINY, utcDateStr,
            Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER
        );
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
