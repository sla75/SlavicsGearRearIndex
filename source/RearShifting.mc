import Toybox.AntPlus;
import Toybox.Graphics;
import Toybox.Lang;

class RearShifting {

    typedef BatteryData as {
            :identifier as Number,
            :name as String,
            :batteryStatus as Number,
            :batteryVoltage as Float,
            :operatingTime as Number,
            :color as Graphics.ColorType,
            :percentage as String,
        };

    public static const BATTERY_STATUS_COLOR = [0,Graphics.COLOR_DK_GREEN,Graphics.COLOR_DK_GREEN,Graphics.COLOR_DK_GREEN,Graphics.COLOR_ORANGE,Graphics.COLOR_RED,0,Graphics.COLOR_DK_RED,Graphics.COLOR_LT_GRAY] as Array<ColorType>;
    public static const BATTERY_NAME={0x01=>"FD",0x02=>"RD",0x03=>"LS",0x04=>"RS"} as Dictionary<Number,String>;
    public static const BATTERY_STATUSES =[AntPlus.BATT_STATUS_CNT,
                AntPlus.BATT_STATUS_NEW,
                AntPlus.BATT_STATUS_GOOD,
                AntPlus.BATT_STATUS_OK,
                AntPlus.BATT_STATUS_LOW,
                AntPlus.BATT_STATUS_CRITICAL,
                AntPlus.BATT_STATUS_CNT,
                AntPlus.BATT_STATUS_INVALID,
                AntPlus.BATT_STATUS_CNT,

            ] as Array<BatteryStatusValue>;
    (:debug)
    private const DEBUG_TEETHS = [51, 45, 39, 33, 28, 24, 21, 18, 16, 14, 12, 10] as Array<Number>;

    private var shiftDevice=new AntPlus.Shifting(new AntPlus.ShiftingListener()) as AntPlus.Shifting;
        
    (:release)
    public function getDeviceState() as AntPlus.DeviceState {
        return shiftDevice.getDeviceState() as AntPlus.DeviceState;
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
        //System.println("SlavicsGearRearView DEBUG DeviceSate="+ds.state.toString());
        return ds;
    }
    (:release)
    public function getRearDerailleurStatus() as AntPlus.DerailleurStatus {
        return shiftDevice.getShiftingStatus().rearDerailleur;
    }
    (:debug)
    public function getRearDerailleurStatus() as AntPlus.DerailleurStatus {
        var ss=shiftDevice.getShiftingStatus() as AntPlus.ShiftingStatus;
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
            //System.println("SlavicsGearRearView DEBUG gearIndex="+rearDerailleur.gearIndex);
            return rearDerailleur;
        }
        return ss.rearDerailleur;
    }

    (:debug)
    public function getBatteries() as Array<BatteryData> {
        var ids=[0x01,0x03] as Array<Number>;
        var batteries=[] as Array<BatteryData>;
        for(var i=0;i<ids.size();i++){
            var id=ids[i];
            var bs=new BatteryStatus();
            bs.batteryStatus=BATTERY_STATUSES[(1+Math.rand()%7)];
            bs.batteryVoltage=System.getClockTime().sec/7f;
            bs.operatingTime=System.getClockTime().min*60+System.getClockTime().sec;
            if(bs has :batteryStatus && bs!=null){
                var b={:identifier=>id} as BatteryData;
                b.put(:name,BATTERY_NAME.hasKey(id)?BATTERY_NAME.get(id):id.format("%X"));
                b.put(:batteryStatus,bs.batteryStatus==null?AntPlus.BATT_STATUS_INVALID:bs.batteryStatus);
                //b.put(:batteryVoltage,(bs has :batteryVoltage && bs.batteryVoltage!=null)?bs.batteryVoltage:0f);
                //b.put(:operatingTime,(bs has :operatingTime && bs.operatingTime!=null)?bs.batteryVoltage:0);
                b.put(:color,BATTERY_STATUS_COLOR[bs.batteryStatus]);
                switch (b.get(:batteryStatus)) {
                    case AntPlus.BATT_STATUS_NEW:
                        b.put(:percentage,"100%");
                        break;
                    case AntPlus.BATT_STATUS_GOOD:
                        b.put(:percentage,"80%");
                        break;
                    case AntPlus.BATT_STATUS_OK:
                        b.put(:percentage,"50%");
                        break;
                    case AntPlus.BATT_STATUS_LOW:
                        b.put(:percentage,"30%");
                        break;
                    case AntPlus.BATT_STATUS_CRITICAL:
                        b.put(:percentage,"15%");
                        break;
                    case AntPlus.BATT_STATUS_CNT:
                        b.put(:percentage,"X");
                        break;
                    default:
                        b.put(:percentage,"--%");
                        break;
                }
                batteries.add(b);
                /***
                batteries.add({
                    :identifier=>id,
                    :name=>BATTERY_NAME.hasKey(id)?BATTERY_NAME.get(id):id.format("%X"),
                    :batteryStatus=>bs.batteryStatus==null?AntPlus.BATT_STATUS_INVALID:bs.batteryStatus,
                    :batteryVoltage=>(bs has :batteryVoltage && bs.batteryVoltage!=null)?bs.batteryVoltage:0f,
                    :operatingTime=>(bs has :operatingTime && bs.operatingTime!=null)?bs.batteryVoltage:0,
                    :color=>BATTERY_STATUS_COLOR[bs.batteryStatus]
                } as BatteryData);
                /***/
            }
        }
        return batteries;
    }

    (:release)
    public function getBatteries() as Array<BatteryData> {
        var ids=shiftDevice.getComponentIdentifiers() as Array<Number> or Null;
        var batteries=[] as Array<BatteryData>;
        if(ids!=null){
            for(var i=0;i<ids.size();i++){
                var id=ids[i];
                var bs=shiftDevice.getBatteryStatus(id) as BatteryStatus;
                if(bs!=null){
                    var b={:identifier=>id} as BatteryData;
                    b.put(:name,BATTERY_NAME.hasKey(id)?BATTERY_NAME.get(id):id.format("%X"));
                    b.put(:batteryStatus,bs.batteryStatus==null?AntPlus.BATT_STATUS_INVALID:bs.batteryStatus);
                    //b.put(:batteryVoltage,bs.batteryVoltage!=null?bs.batteryVoltage:0f);
                    //b.put(:operatingTime,bs.operatingTime!=null?bs.batteryVoltage:0);
                    b.put(:color,BATTERY_STATUS_COLOR[bs.batteryStatus==null?AntPlus.BATT_STATUS_INVALID:bs.batteryStatus]);
                    /***
                    switch (b.get(:batteryStatus)) {
                        case AntPlus.BATT_STATUS_NEW:
                            b.put(:percentage,"100%");
                            break;
                        case AntPlus.BATT_STATUS_GOOD:
                            b.put(:percentage,"80%");
                            break;
                        case AntPlus.BATT_STATUS_OK:
                            b.put(:percentage,"50%");
                            break;
                        case AntPlus.BATT_STATUS_LOW:
                            b.put(:percentage,"30%");
                            break;
                        case AntPlus.BATT_STATUS_CRITICAL:
                            b.put(:percentage,"15%");
                            break;
                        case AntPlus.BATT_STATUS_CNT:
                            b.put(:percentage,"X");
                            break;
                        default:
                            b.put(:percentage,"--%");
                            break;
                    }
                    /***/
                    batteries.add(b);
                }
            }
        }
        return batteries;
    }
}