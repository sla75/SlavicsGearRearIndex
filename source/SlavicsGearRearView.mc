import Toybox.Activity;
import Toybox.AntPlus;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

class SlavicsGearRearView extends SlavicsSimpleDataField {
    private var rearShift=new RearShifting() as RearShifting;
    private var batteries=[] as Array<RearShifting.BatteryData>;

    private var teethsLabel=new Text({
            :color=>Graphics.COLOR_DK_GRAY,
            :font=>Graphics.FONT_SMALL,
            :justification=>Graphics.TEXT_JUSTIFY_LEFT,
        });
    private var unitTeeths as String;
    private var label as String;
    private var lastIndex=-1 as Number;

    function initialize() {
        System.println("SlavicsGearRearView.initialize()");
        SlavicsSimpleDataField.initialize();
        unitTeeths=Application.loadResource(Rez.Strings.unitTeeths);
        label=Application.loadResource(Rez.Strings.label);
    }

    function onLayout(dc as Dc) as Void {
        System.println("SlavicsGearRearView.onLayout() "+dc.getWidth()+"x"+dc.getHeight());
        SlavicsSimpleDataField.onLayout(dc);
        teethsLabel.locX=self.rim;
        teethsLabel.locY=self.labelLine;
    }
    
    function onShow() {
        System.println("SlavicsGearRearView.onShow()");
        SlavicsSimpleDataField.onShow();
        self.setTextLabel(label);
    }

    function compute(info as Activity.Info) as Void {
        SlavicsSimpleDataField.compute(info);
        var bsds=rearShift.getDeviceState() as AntPlus.DeviceState;
        if(bsds!=null&&bsds.state!=null){
            switch(bsds.state){
                case AntPlus.DEVICE_STATE_SEARCHING:
                    self.setTextLabel(System.getClockTime().sec%2==0?" ."+label+". ":".."+label+"..");
                    break;
                case AntPlus.DEVICE_STATE_TRACKING:
                    self.setTextLabel(label);
                    break;
                default:
                    self.setTextLabel("?"+label+"?");
            }
            
            batteries=rearShift.getBatteries();

        }

        var rds=rearShift.getRearDerailleurStatus() as AntPlus.DerailleurStatus;
        teethsLabel.setColor(System.getDeviceSettings().isNightModeEnabled?Graphics.COLOR_LT_GRAY:Graphics.COLOR_DK_GRAY);
        if(rds!=null){
                if(rds.gearIndex!=AntPlus.REAR_GEAR_INVALID){
                    if(rds.gearIndex!=lastIndex){
                        valueArea.setColor(System.getDeviceSettings().isNightModeEnabled?Graphics.COLOR_DK_GRAY:Graphics.COLOR_LT_GRAY);
                    } else if(rds.gearIndex==0||rds.gearIndex==rds.gearMax-1){
                        valueArea.setColor(System.getDeviceSettings().isNightModeEnabled?Graphics.COLOR_RED:Graphics.COLOR_DK_RED);
                    }else{
                        valueArea.setColor(System.getDeviceSettings().isNightModeEnabled?Graphics.COLOR_WHITE:Graphics.COLOR_BLACK);
                    }
                    setTextValue((rds.gearIndex+1).toString());
                    teethsLabel.setText(rds.gearSize+unitTeeths);
                    lastIndex=rds.gearIndex;
                } else {
                    valueArea.setColor(Graphics.COLOR_LT_GRAY);
                    setTextValue("Inv.");
                    teethsLabel.setText("");
                    lastIndex=-1;
                }
        } else {
            teethsLabel.setText(".");
            valueArea.setColor(Graphics.COLOR_LT_GRAY);
            setTextValue("..");
            lastIndex=-2;
        }
    }

    public function onUpdate(dc as Dc) as Void {
        System.println("SlavicsGearRearView.onUpdate()");
        SlavicsSimpleDataField.onUpdate(dc);
        teethsLabel.draw(dc);
        if(batteries.size()>0){
            var bLocX=dc.getWidth()-rim;
            var bLocY=dc.getHeight()-rim-Graphics.getFontAscent(Graphics.FONT_XTINY);
            for(var i=0;i<batteries.size();i++){
                var bd=(batteries as Array<RearShifting.BatteryData>)[i] as RearShifting.BatteryData;
                System.println("sec="+System.getClockTime().sec);
                System.println("bd.get(:batteryStatus)="+bd.get(:batteryStatus));
                System.println("BATTERY_STATUS_TEXT="+RearShifting.BATTERY_STATUS_TEXT.toString());
                dc.setColor(bd.get(:color),Graphics.COLOR_TRANSPARENT);                
                dc.drawText(bLocX,bLocY,Graphics.FONT_XTINY,RearShifting.BATTERY_STATUS_TEXT[bd.get(:batteryStatus)],Graphics.TEXT_JUSTIFY_RIGHT);
                bLocX-=dc.getTextWidthInPixels("."+RearShifting.BATTERY_STATUS_TEXT[bd.get(:batteryStatus)],Graphics.FONT_XTINY);
                dc.drawText(bLocX,bLocY,Graphics.FONT_XTINY,bd.get(:name),Graphics.TEXT_JUSTIFY_RIGHT);
                bLocX-=dc.getTextWidthInPixels(bd.get(:name)+" ",Graphics.FONT_XTINY);
                
            }
        }
    }
}
