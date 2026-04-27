import Toybox.Activity;
import Toybox.AntPlus;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

class SlavicsGearRearView extends SlavicsSimpleDataField {
    private static const BATTERY_STATUS_COLOR = [0,Graphics.COLOR_DK_GREEN,Graphics.COLOR_DK_GREEN,Graphics.COLOR_DK_GREEN,Graphics.COLOR_ORANGE,Graphics.COLOR_RED,0,Graphics.COLOR_DK_RED,Graphics.COLOR_LT_GRAY] as Array<ColorType>;
    private static const BATTERY_STATUS_TEXT = ["0","New","Good","Ok","Low","Crit.","Unkn.","Inv.","Cnt"];
    private static const BATTERY_NAME={0x01=>"FD",0x02=>"RD",0x03=>"LS",0x04=>"RS"} as Dictionary<Number,String>;
    private var bikeShift=new AntPlus.Shifting(new AntPlus.ShiftingListener()) as AntPlus.Shifting;
    private var batteries=[] as Array<BatteryData>;
    typedef BatteryData as {
            :identifier as Number,
            :name as String,
            :batteryStatus as Number,
            :color as Graphics.ColorType,
        };

    private var teethsLabel=new Text({
            :color=>Graphics.COLOR_DK_GRAY,
            :font=>Graphics.FONT_SMALL,
            :justification=>Graphics.TEXT_JUSTIFY_LEFT,
        });
    private var unitTeeths as String;
    private var label as String;

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
    /***/
    function onShow() {
        System.println("SlavicsGearRearView.onShow()");
        SlavicsSimpleDataField.onShow();
        self.setTextLabel(label);
    }
    /***/
    private var lastIndex=-1 as Number;
    function compute(info as Activity.Info) as Void {
        SlavicsSimpleDataField.compute(info);
        var bsds=getDeviceState() as AntPlus.DeviceState;
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
            
            // TODO Debug
            var ids=bikeShift.getComponentIdentifiers() as Array<Number> or Null;
            batteries=[] as Array<BatteryData>;
            if(ids!=null){
                for(var i=0;i<ids.size();i++){
                    var id=ids[i];
                    var bs=bikeShift.getBatteryStatus(id);
                    bs.batteryStatus=bs.batteryStatus==null?AntPlus.BATT_STATUS_INVALID:bs.batteryStatus;
                    var b={
                        :identifier=>id,
                        :name=>BATTERY_NAME.hasKey(id)?BATTERY_NAME.get(id):id.format("%X"),
                        :batteryStatus=>bs.batteryStatus==null?6:BATTERY_STATUSES.indexOf(bs.batteryStatus),
                        :color=>BATTERY_STATUS_COLOR[bs.batteryStatus]
                        //:statusString=>BATTERY_STATUS_COLOR[];
                    } as BatteryData;
                    batteries.add(b);
                }
            }
        }

        var rds=getRearDerailleurStatus() as AntPlus.DerailleurStatus;
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
                    //teethsLabel.setText("--"+unitTeeths);
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
    public static const STATUSES =[null,
                AntPlus.BATT_STATUS_NEW,
                AntPlus.BATT_STATUS_GOOD,
                AntPlus.BATT_STATUS_OK,
                AntPlus.BATT_STATUS_LOW,
                AntPlus.BATT_STATUS_CRITICAL,
                null,
                AntPlus.BATT_STATUS_INVALID,
                AntPlus.BATT_STATUS_CNT,

            ] as Array<BatteryStatusValue>;
    (:release)
    function getDeviceState() as AntPlus.DeviceState {
        return bikeShift.getDeviceState() as AntPlus.DeviceState;
    }
    (:debug)
    function getDeviceState() as AntPlus.DeviceState {
        var ds=new AntPlus.DeviceState() as AntPlus.DeviceState;
        ds.deviceNumber=999999;
        ds.state=AntPlus.DEVICE_STATE_TRACKING;
        if(System.getClockTime().sec<6){
            ds.state=AntPlus.DEVICE_STATE_SEARCHING;
        } else if(System.getClockTime().sec>54){
            ds.state=AntPlus.DEVICE_STATE_CLOSED;
        } else if(System.getClockTime().sec>58){
            ds.state=AntPlus.DEVICE_STATE_DEAD;
        }
        System.println("SlavicsGearRearView DEBUG DeviceSate="+ds.state.toString());
        return ds;
    }
    (:release)
    function getRearDerailleurStatus() as AntPlus.DerailleurStatus {
        return bikeShift;
    }
    (:debug)
    function getRearDerailleurStatus() as AntPlus.DerailleurStatus {
        var ss=bikeShift.getShiftingStatus() as AntPlus.ShiftingStatus;
        if(ss==null||ss.rearDerailleur.gearIndex==AntPlus.REAR_GEAR_INVALID){
            var myTeeths = [51, 45, 39, 33, 28, 24, 21, 18, 16, 14, 12, 10] as Array<Number>;
            var rearDerailleur=new DerailleurStatus();
            if(System.getClockTime().sec==13){
                rearDerailleur.gearIndex=AntPlus.FRONT_GEAR_INVALID;
                rearDerailleur.gearMax=AntPlus.MAX_GEARS_INVALID;
                rearDerailleur.gearSize=0;
                rearDerailleur.invalidInboardShiftCount=0;
                rearDerailleur.invalidOutboardShiftCount=0;
                rearDerailleur.shiftFailureCount=0;
            } else {
                rearDerailleur.gearIndex=System.getClockTime().sec/3%myTeeths.size();
                rearDerailleur.gearMax=myTeeths.size();
                rearDerailleur.gearSize=myTeeths[rearDerailleur.gearIndex];
                rearDerailleur.invalidInboardShiftCount=Math.rand()%255;
                rearDerailleur.invalidOutboardShiftCount=Math.rand()%255;
                rearDerailleur.shiftFailureCount=Math.rand()%255;
            }
            System.println("SlavicsGearRearView DEBUG gearIndex="+rearDerailleur.gearIndex);
            return rearDerailleur;
        }
        return ss.rearDerailleur;
        /***
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
        var ids=[0x01,0x03] as Array<Number> or Null;
        batteries=[] as Array<BatteryData>;
        if(ids!=null){
            for(var i=0;i<ids.size();i++){
                var bs=new BatteryStatus();
                bs.batteryStatus=System.getClockTime().sec==13?null:(1+Math.rand()%7);
                bs.batteryVoltage=System.getClockTime().sec/7f;
                bs.operatingTime=System.getClockTime().min*60+System.getClockTime().sec;
                
                var b={
                        :identifier=>ids[i],
                        :name=>BATTERY_NAME.hasKey(ids[i])?BATTERY_NAME.get(ids[i]):ids[i].format("%X"),
                        :batteryStatus=>bs.batteryStatus==null?AntPlus.BATT_STATUS_INVALID:bs.batteryStatus,
                        :color=>BATTERY_STATUS_COLOR[bs.batteryStatus==null?0:bs.batteryStatus]
                    } as BatteryData;
                batteries.add(b);
            }
        }
        /***/
    }
    
    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    
    public function onUpdate(dc as Dc) as Void {
        System.println("SlavicsGearRearView.onUpdate()");
        SlavicsSimpleDataField.onUpdate(dc);
        teethsLabel.draw(dc);
        if(batteries.size()>0){
            var bLocX=dc.getWidth()-rim;
            var bLocY=dc.getHeight()-rim-Graphics.getFontAscent(Graphics.FONT_XTINY);
            for(var i=0;i<batteries.size();i++){
                var bd=(batteries as Array<BatteryData>)[i] as BatteryData;
                System.println("sec="+System.getClockTime().sec);
                System.println("bd.get(:batteryStatus)="+bd.get(:batteryStatus));
                System.println("BATTERY_STATUS_TEXT="+BATTERY_STATUS_TEXT.toString());

                dc.setColor(bd.get(:color),Graphics.COLOR_TRANSPARENT);                
                dc.drawText(bLocX,bLocY,Graphics.FONT_XTINY,BATTERY_STATUS_TEXT[bd.get(:batteryStatus)],Graphics.TEXT_JUSTIFY_RIGHT);
                bLocX-=dc.getTextWidthInPixels("."+BATTERY_STATUS_TEXT[bd.get(:batteryStatus)],Graphics.FONT_XTINY);
                //dc.setColor(System.getDeviceSettings().isNightModeEnabled?Graphics.COLOR_LT_GRAY:Graphics.COLOR_DK_GRAY,Graphics.COLOR_TRANSPARENT);
                dc.drawText(bLocX,bLocY,Graphics.FONT_XTINY,bd.get(:name),Graphics.TEXT_JUSTIFY_RIGHT);
                bLocX-=dc.getTextWidthInPixels(bd.get(:name)+" ",Graphics.FONT_XTINY);
                
            }
        }

    }
    public static const BATTERY_STATUSES =[null,
                AntPlus.BATT_STATUS_NEW,
                AntPlus.BATT_STATUS_GOOD,
                AntPlus.BATT_STATUS_OK,
                AntPlus.BATT_STATUS_LOW,
                AntPlus.BATT_STATUS_CRITICAL,
                null,
                AntPlus.BATT_STATUS_INVALID,
                AntPlus.BATT_STATUS_CNT,

            ] as Array<BatteryStatusValue>;
}
