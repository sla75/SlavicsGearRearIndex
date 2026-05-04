import Toybox.Activity;
import Toybox.AntPlus;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class SlavicsGearIndexSimpleView extends WatchUi.SimpleDataField {
    private var bikeShift=new AntPlus.Shifting(new AntPlus.ShiftingListener()) as AntPlus.Shifting;
    private var name;
    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        name = Application.loadResource(Rez.Strings.label);
        label=name;
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Numeric or Duration or String or Null {
        var bsds=bikeShift.getDeviceState() as AntPlus.DeviceState;
        if(bsds!=null&&bsds.state!=null){
            switch(bsds.state){
                case AntPlus.DEVICE_STATE_SEARCHING:
                    label=System.getClockTime().sec%2==0?"."+name+".":".."+name+"..";
                    break;
                case AntPlus.DEVICE_STATE_TRACKING:
                    label=name;
                    break;
                default:
                    label="?"+name+"?";
            }
        }

        var ss=bikeShift.getShiftingStatus() as AntPlus.ShiftingStatus;
        if(ss!=null){
                if(ss.rearDerailleur.gearIndex!=AntPlus.REAR_GEAR_INVALID){    
                    return (ss.rearDerailleur.gearIndex+1).toString();
                } else {
                    return "--";
                }
                //return System.getClockTime().sec.toString()+Application.loadResource(Rez.Strings.unitTeeth);
        } else {
            return "xx";
        }
    }

}