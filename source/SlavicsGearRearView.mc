import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

class SlavicsGearRearView extends SlavicsSimpleDataField {
    private static const BATTSTATUSCOLOR = [0,Graphics.COLOR_DK_GREEN,Graphics.COLOR_DK_GREEN,Graphics.COLOR_DK_GREEN,Graphics.COLOR_ORANGE,Graphics.COLOR_RED,0,Graphics.COLOR_DK_RED,Graphics.COLOR_LT_GRAY] as Array<ColorType>;
    private static const BATTERY_STATUS = ["0","NEW","GOOD","OK","LOW","CRITICAL","Unknown","INVALID","CNT"];

    private var teethsLabel=new Text({
            :color=>Graphics.COLOR_DK_GRAY,
            :font=>Graphics.FONT_SMALL,
            :justification=>Graphics.TEXT_JUSTIFY_LEFT,
        });
    private var batteryLabel=new Text({
            :color=>Graphics.COLOR_DK_GRAY,
            :font=>Graphics.FONT_TINY,
            :justification=>Graphics.TEXT_JUSTIFY_RIGHT,
        });
        private var unitTeeths as String;

    function initialize() {
        System.println("SlavicsGearRearView.initialize()");
        SlavicsSimpleDataField.initialize();
        unitTeeths=Application.loadResource(Rez.Strings.unitTeeths);
    }

    function onLayout(dc as Dc) as Void {
        System.println("SlavicsGearRearView.onLayout() "+dc.getWidth()+"x"+dc.getHeight());
        SlavicsSimpleDataField.onLayout(dc);
        teethsLabel.locX=self.rim;
        teethsLabel.locY=self.labelLine;
        batteryLabel.locX=dc.getWidth()-rim;
        batteryLabel.locY=dc.getHeight()-rim-Graphics.getFontAscent(Graphics.FONT_TINY);
    }
    /***/
    function onShow() {
        System.println("SlavicsGearRearView.onShow()");
        SlavicsSimpleDataField.onShow();
        self.setTextLabel(Application.loadResource(Rez.Strings.label));
    }
    /***/
    (:release)
    function compute(info as Activity.Info) as Void {
        SlavicsSimpleDataField.compute(info);
        var bsds=bikeShift.getDeviceState() as AntPlus.DeviceState;
        if(bsds!=null&&bsds.state!=null){
            switch(bsds.state){
                case AntPlus.DEVICE_STATE_SEARCHING:
                    self.setTextLabel(System.getClockTime().sec%2==0?"."+self.textLabel+".":".."+self.textLabel+"..");
                    break;
                case AntPlus.DEVICE_STATE_TRACKING:
                    self.setTextLabel(self.textLabel);
                    break;
                default:
                    self.setTextLabel("?"+self.textLabel+"?");
            }
            batteryLabel.setColor(System.getDeviceSettings().isNightModeEnabled?Graphics.COLOR_DK_GRAY:Graphics.COLOR_LT_GRAY);
            var ids=bikeShift.getComponentIdentifiers() as Array<Number> or Null;
            var bt="";
            if(ids!=null){
                for(var i=0;i<ids.size();i++){
                    var id=ids[i];
                    var bs=bikeShift.getBatteryStatus(id);
                    if(bs!=null){
                        bt+=" "+BATTERY_STATUS[bs];
                    }
                }
            }
            batteryLabel.setText(bt);
        } else {
            batteryLabel.setText("Battery?");
        }

        var ss=bikeShift.getShiftingStatus() as AntPlus.ShiftingStatus;
        teethsLabel.setColor(System.getDeviceSettings().isNightModeEnabled?Graphics.COLOR_WHITE:Graphics.COLOR_BLACK);
        if(ss!=null){
                if(ss.rearDerailleur.gearIndex!=AntPlus.REAR_GEAR_INVALID){    
                    setTextValue((ss.rearDerailleur.gearIndex+1).toString());
                    teethsLabel.setText(ss.rearDerailleur.gearSize+unitTeeths);
                } else {
                    setTextValue("Inv.");
                    teethsLabel.setText("--"+unitTeeths);
                }
        } else {
            teethsLabel.setText("--");
            setTextValue("--");
        }
    }

    (:debug)
    function compute(info as Activity.Info) as Void {
        SlavicsSimpleDataField.compute(info);
        teethsLabel.setColor(System.getDeviceSettings().isNightModeEnabled?Graphics.COLOR_WHITE:Graphics.COLOR_BLACK);
        if(System.getClockTime().sec/15%2==0){
            System.println("SlavicsGearRearView.compute(info)");
            self.setTextValue(info.currentSpeed!=null?(info.currentSpeed*3.6f).format("%0.1f")+"km/h":"--km/h");
            teethsLabel.setText("--");
        } else {
            System.println("SlavicsGearRearView.compute(debug)");
            self.setTextValue((System.getClockTime().sec/3f).format("%0.1f")+"d");
            teethsLabel.setText(Math.rand()%51+unitTeeths);
        }
        batteryLabel.setColor(System.getDeviceSettings().isNightModeEnabled?Graphics.COLOR_DK_GRAY:Graphics.COLOR_LT_GRAY);
        var ids=[0x01,0x03] as Array<Number> or Null;
        var bt="";
        if(ids!=null){
            for(var i=0;i<ids.size();i++){
                bt+=" "+BATTERY_STATUS[Math.rand()%8];
            }
        }
        batteryLabel.setText(bt);
    }
    

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    
    public function onUpdate(dc as Dc) as Void {
        System.println("SlavicsGearRearView.onUpdate()");
        SlavicsSimpleDataField.onUpdate(dc);
        teethsLabel.draw(dc);
        batteryLabel.draw(dc);
    }
}
