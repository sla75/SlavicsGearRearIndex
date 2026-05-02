import Toybox.AntPlus;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BatteryIcon extends Drawable {
    private var fontBattery=null as Graphics.FontType;
    private var charge=false as Boolean;
    private var justify as Graphics.TextJustification;
    private var status=AntPlus.BATT_STATUS_CNT as AntPlus.BatteryStatusValue;
    public function initialize(params as Dictionary){
        self.fontBattery=params[:font]!=null?params[:font]:Graphics.FONT_TINY;
        justify=params[:justification]!=null?params[:justification]:Graphics.TEXT_JUSTIFY_LEFT;
        Drawable.initialize(params);
    }

    public static const BATTERY_STATUS_COLOR = [0,Graphics.COLOR_DK_GREEN,Graphics.COLOR_DK_GREEN,Graphics.COLOR_DK_GREEN,Graphics.COLOR_ORANGE,Graphics.COLOR_RED,0,Graphics.COLOR_DK_GRAY,Graphics.COLOR_LT_GRAY] as Array<ColorType>;
    public static const BATTERY_STATUSES =[null,
                AntPlus.BATT_STATUS_NEW,
                AntPlus.BATT_STATUS_GOOD,
                AntPlus.BATT_STATUS_OK,
                AntPlus.BATT_STATUS_LOW,
                AntPlus.BATT_STATUS_CRITICAL,
                AntPlus.BATT_STATUS_INVALID,
                AntPlus.BATT_STATUS_INVALID,
                AntPlus.BATT_STATUS_CNT,

            ] as Array<BatteryStatusValue>;
    private static const BATCHAR={
            0=>"0",
            AntPlus.BATT_STATUS_NEW=>"0",
            AntPlus.BATT_STATUS_GOOD=>"1",
            AntPlus.BATT_STATUS_OK=>"2",
            AntPlus.BATT_STATUS_LOW=>"3",
            AntPlus.BATT_STATUS_CRITICAL=>"4",
            6=>"0",
            AntPlus.BATT_STATUS_INVALID=>"5",
            AntPlus.BATT_STATUS_CNT=>"5",
        };

    public function setFont(font as Graphics.FontType) as Void{
        self.fontBattery=font;
    }
    public function getFont() as Graphics.FontType{
        return self.fontBattery;
    }
    public function getWidth(dc as Dc) as Number{
        return dc.getTextWidthInPixels(BATCHAR.get(status),fontBattery);
    }
    public function compute(status as AntPlus.BatteryStatusValue,charge as Boolean) {
        self.charge=charge;
        self.status=status;
    }
    public function draw(dc as Dc) {
        //dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_TRANSPARENT);
        //dc.drawText(50,50,font,"0123456",Graphics.TEXT_JUSTIFY_RIGHT);
        //System.println("BatteryIcon.draw() status="+status.toString());
        //System.println("BatteryIcon.draw() char="+BATCHAR.get(status));
        dc.setColor(BATTERY_STATUS_COLOR[status],Graphics.COLOR_WHITE);
        dc.drawText(self.locX,self.locY,fontBattery,BATCHAR.get(status),self.justify);
        if(charge){
            dc.setColor(Graphics.COLOR_RED,Graphics.COLOR_TRANSPARENT);
            dc.drawText(self.locX,self.locY,fontBattery,"6",self.justify);
        }
    }
    
}