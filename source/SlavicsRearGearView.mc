import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

class SpeedFieldView extends WatchUi.DataField {

    function initialize() {
        DataField.initialize();
    }

    function onLayout(dc as Dc) as Void {
        System.println("SpeedFieldView.onLayout()");
    }

    function compute(info as Activity.Info) as Void {
        System.println("SpeedFieldView.compute()");
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        System.println("SpeedFieldView.onUpdate()");
    }

}
