import Toybox.AntPlus;
import Toybox.Graphics;
import Toybox.Lang;

class RearShifting {

    typedef BatteryData as {
            :identifier as Number,
            :name as String,
            :batteryStatus as Number,
            :color as Graphics.ColorType,
        };

    public static const BATTERY_STATUS_COLOR = [0,Graphics.COLOR_DK_GREEN,Graphics.COLOR_DK_GREEN,Graphics.COLOR_DK_GREEN,Graphics.COLOR_ORANGE,Graphics.COLOR_RED,0,Graphics.COLOR_DK_RED,Graphics.COLOR_LT_GRAY] as Array<ColorType>;
    public static const BATTERY_STATUS_TEXT = ["0","New","Good","Ok","Low","Crit.","Unkn.","Inv.","Cnt"];
    public static const BATTERY_NAME={0x01=>"FD",0x02=>"RD",0x03=>"LS",0x04=>"RS"} as Dictionary<Number,String>;
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
    private const DEBUG_TEETHS = [51, 45, 39, 33, 28, 24, 21, 18, 16, 14, 12, 10] as Array<Number>;
    private var bikeShift=new AntPlus.Shifting(new AntPlus.ShiftingListener()) as AntPlus.Shifting;
        
    (:release)
    public function getDeviceState() as AntPlus.DeviceState {
        return bikeShift.getDeviceState() as AntPlus.DeviceState;
    }
    (:debug)
    public function getDeviceState() as AntPlus.DeviceState {
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
    public function getRearDerailleurStatus() as AntPlus.DerailleurStatus {
        return bikeShift;
    }
    (:debug)
    public function getRearDerailleurStatus() as AntPlus.DerailleurStatus {
        var ss=bikeShift.getShiftingStatus() as AntPlus.ShiftingStatus;
        if(ss==null||ss.rearDerailleur.gearIndex==AntPlus.REAR_GEAR_INVALID){
            
            var rearDerailleur=new DerailleurStatus();
            if(System.getClockTime().sec==13){
                rearDerailleur.gearIndex=AntPlus.FRONT_GEAR_INVALID;
                rearDerailleur.gearMax=AntPlus.MAX_GEARS_INVALID;
                rearDerailleur.gearSize=0;
                rearDerailleur.invalidInboardShiftCount=0;
                rearDerailleur.invalidOutboardShiftCount=0;
                rearDerailleur.shiftFailureCount=0;
            } else {
                rearDerailleur.gearIndex=System.getClockTime().sec/3%DEBUG_TEETHS.size();
                rearDerailleur.gearMax=DEBUG_TEETHS.size();
                rearDerailleur.gearSize=DEBUG_TEETHS[rearDerailleur.gearIndex];
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
    public function getBatteries() as Array<BatteryData> {
        var ids=bikeShift.getComponentIdentifiers() as Array<Number> or Null;
        var batteries=[] as Array<BatteryData>;
        if(ids!=null){
            for(var i=0;i<ids.size();i++){
                var id=ids[i];
                var bs=bikeShift.getBatteryStatus(id);
                bs.batteryStatus=bs.batteryStatus==null?AntPlus.BATT_STATUS_INVALID:bs.batteryStatus;
                var b={
                    :identifier=>id,
                    :name=>RearShifting.BATTERY_NAME.hasKey(id)?RearShifting.BATTERY_NAME.get(id):id.format("%X"),
                    :batteryStatus=>bs.batteryStatus==null?6:RearShifting.BATTERY_STATUSES.indexOf(bs.batteryStatus),
                    :color=>RearShifting.BATTERY_STATUS_COLOR[bs.batteryStatus]
                } as BatteryData;
                batteries.add(b);
            }
        }
        return batteries;
    }
    
}