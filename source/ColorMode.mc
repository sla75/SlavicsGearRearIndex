import Toybox.AntPlus;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;

class ColorMode {

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
    
    private var isNight=false as Boolean;

    private const MODE_BLACKANDWHITE={:day=>{
                :background=>Graphics.COLOR_WHITE,
                :label=>Graphics.COLOR_DK_GRAY,
                :value=>Graphics.COLOR_BLACK,
                :valueEdge=>Graphics.COLOR_DK_RED,
                :valueChange=>Graphics.COLOR_DK_GRAY,
                :error=>Graphics.COLOR_LT_GRAY,
            },:night=>{
                :background=>Graphics.COLOR_BLACK,
                :label=>Graphics.COLOR_LT_GRAY,
                :value=>Graphics.COLOR_WHITE,
                :valueEdge=>Graphics.COLOR_RED,
                :valueChange=>Graphics.COLOR_LT_GRAY,
                :error=>Graphics.COLOR_DK_GRAY,
            }
        } as Dictionary<Dictionary<Symbol,Graphics.ColorValue>>;
    private const MODE_BLUE={:day=>{
                :background=>Graphics.COLOR_BLUE,
                :label=>Graphics.COLOR_DK_GRAY,
                :value=>Graphics.COLOR_WHITE,
                :valueEdge=>Graphics.COLOR_DK_RED,
                :valueChange=>Graphics.COLOR_LT_GRAY,
                :error=>Graphics.COLOR_LT_GRAY,
            }
        } as Dictionary<Dictionary<Symbol,Graphics.ColorValue>>;
    private const MODE_GREEN={:day=>{
                :background=>Graphics.COLOR_DK_GREEN,
                :label=>Graphics.COLOR_BLACK,
                :value=>Graphics.COLOR_WHITE,
                :valueEdge=>Graphics.COLOR_DK_RED,
                :valueChange=>Graphics.COLOR_LT_GRAY,
                :error=>Graphics.COLOR_DK_GRAY,
            }
        } as Dictionary<Dictionary<Symbol,Graphics.ColorValue>>;
    private const MODE_PINK={:day=>{
                :background=>Graphics.COLOR_PINK,
                :label=>Graphics.COLOR_DK_GRAY,
                :value=>Graphics.COLOR_BLACK,
                :valueEdge=>Graphics.COLOR_DK_RED,
                :valueChange=>Graphics.COLOR_DK_GRAY,
                :error=>Graphics.COLOR_LT_GRAY,
            },:night=>{
                :background=>Graphics.COLOR_PURPLE,
                :label=>Graphics.COLOR_LT_GRAY,
                :value=>Graphics.COLOR_WHITE,
                :valueEdge=>Graphics.COLOR_RED,
                :valueChange=>Graphics.COLOR_LT_GRAY,
                :error=>Graphics.COLOR_DK_GRAY,
            }
        } as Dictionary<Dictionary<Symbol,Graphics.ColorValue>>;
    private var colors=MODE_BLACKANDWHITE as Dictionary<Symbol,Graphics.ColorValue>;
    function initialize() {
        System.println("ColorMode.initialize()");
    }
    
    public function handleSettingUpdate() as Void {
        System.println("ColorMode.onSettingsChanged()="+Properties.getValue("property_colorMode").toString());
        switch (Properties.getValue("property_colorMode") as Number) {
            case 0:
                colors=MODE_BLACKANDWHITE as Dictionary<Symbol,Graphics.ColorValue>;
                break;
            case 1:
                colors=MODE_BLUE as Dictionary<Symbol,Graphics.ColorValue>;
                break;
            case 2:
                colors=MODE_GREEN as Dictionary<Symbol,Graphics.ColorValue>;
                break;
            case 3:
                colors=MODE_PINK as Dictionary<Symbol,Graphics.ColorValue>;
                break;
            default:
                colors=MODE_BLACKANDWHITE as Dictionary<Symbol,Graphics.ColorValue>;
                break;
        }
        if(!colors.hasKey(:night)){
            colors.put(:night,colors.get(:day));
        }
    }
    public function compute() as Void {
        isNight=(Properties.getValue("property_nightMode") as Boolean)?!System.getDeviceSettings().isNightModeEnabled:System.getDeviceSettings().isNightModeEnabled;
    }
    public function getFieldColor(field as Symbol) as Graphics.ColorValue {
        return colors.get(isNight?:night::day).get(field) as Graphics.ColorValue;
    }
    public function getColors() as Dictionary<Symbol,Graphics.ColorValue> {
        return colors.get(isNight?:night::day) as Dictionary<Symbol,Graphics.ColorValue>;
    }
}