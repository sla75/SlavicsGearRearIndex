import Toybox.Activity;
import Toybox.AntPlus;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

class SlavicsGearIndexView extends SlavicsSimpleDataField {

    public static const BATTERY_STATUS_TEXT = ["0","New","Good","Ok","Low","Crit.","Unkn.","Inv.","Cnt"] as Array<String>;
    private var rearShift=new RearShifting() as RearShifting;
    private var batteries=[] as Array<RearShifting.BatteryData>;
    private const INVALID_SHIFTS=[:shiftFailureCount,:invalidInboardShiftCount,:invalidOutboardShiftCount] as Array<Symbol>;
    private var fails={
            INVALID_SHIFTS[0]=>{:count=>0,:change=>false},
            INVALID_SHIFTS[1]=>{:count=>0,:change=>false},
            INVALID_SHIFTS[2]=>{:count=>0,:change=>false},
        } as Dictionary<Symbol,Dictionary<Symbol,Object>>;
    
    
    private var teethsLabel=new Text({
            :color=>Graphics.COLOR_DK_GRAY,
            :font=>Graphics.FONT_SMALL,
            :justification=>Graphics.TEXT_JUSTIFY_LEFT,
        });
    private var failLabel=new Text({
            :text=>"fail",
            :color=>Graphics.COLOR_DK_RED,
            :font=>Graphics.FONT_SMALL,
            :justification=>Graphics.TEXT_JUSTIFY_LEFT,
        });
    private const FAIL_TIME_COUNTER=10 as Number;
    private var failTime=FAIL_TIME_COUNTER as Number;
    private var unitTeeths as String;
    private var versionTest=null as String;
    private var lastIndex=-1 as Number;
    private var colorMode as ColorMode;

    function initialize() {
        System.println("SlavicsGearRearView.initialize()");
        SlavicsSimpleDataField.initialize();
        unitTeeths=Application.loadResource(Rez.Strings.unitTeeths);
        var pos=Application.loadResource(Rez.Strings.version).find("Test") as Number or Null;
        if(pos!=null){
            versionTest=Application.loadResource(Rez.Strings.version).toString().substring(0, pos);
        }
        self.setTextLabel(Application.loadResource(Rez.Strings.label));
        Properties.setValue("property_version",Application.loadResource(Rez.Strings.version));
        Properties.setValue("property_showteeth",Properties.getValue("property_showteeth")==null?true:Properties.getValue("property_showteeth") as Boolean);
        colorMode=new ColorMode();
        handleSettingUpdate();
    }

    function onLayout(dc as Dc) as Void {
        System.println("SlavicsGearRearView.onLayout() "+dc.getWidth()+"x"+dc.getHeight());
        SlavicsSimpleDataField.onLayout(dc);
        teethsLabel.locX=self.rim;
        teethsLabel.locY=self.labelLine;
        failLabel.locY=dc.getHeight()-Graphics.getFontAscent(Graphics.FONT_SMALL)-rim;
        /***
        System.println("PartNumber: "+System.getDeviceSettings().partNumber);
        System.println("Screen: "+dc.getWidth()+"x"+dc.getHeight());
        System.println("|Font|Height|Ascent|Descent|");
        System.println("|---:|---:|---:|---:|");
        System.println("|FONT_XTINY|"+Graphics.getFontHeight(Graphics.FONT_XTINY)+"|"+Graphics.getFontAscent(Graphics.FONT_XTINY)+"|"+Graphics.getFontDescent(Graphics.FONT_XTINY)+"|");
        System.println("|FONT_TINY|"+Graphics.getFontHeight(Graphics.FONT_TINY)+"|"+Graphics.getFontAscent(Graphics.FONT_TINY)+"|"+Graphics.getFontDescent(Graphics.FONT_TINY)+"|");
        System.println("|FONT_SMALL|"+Graphics.getFontHeight(Graphics.FONT_SMALL)+"|"+Graphics.getFontAscent(Graphics.FONT_SMALL)+"|"+Graphics.getFontDescent(Graphics.FONT_SMALL)+"|");
        System.println("|FONT_MEDIUM|"+Graphics.getFontHeight(Graphics.FONT_MEDIUM)+"|"+Graphics.getFontAscent(Graphics.FONT_MEDIUM)+"|"+Graphics.getFontDescent(Graphics.FONT_MEDIUM)+"|");
        System.println("|FONT_LARGE|"+Graphics.getFontHeight(Graphics.FONT_LARGE)+"|"+Graphics.getFontAscent(Graphics.FONT_LARGE)+"|"+Graphics.getFontDescent(Graphics.FONT_LARGE)+"|");
        /***/
    }
    public function handleSettingUpdate() as Void {
        System.println("SlavicsGearRearView.onSettingsChanged()");
        teethsLabel.setVisible(Properties.getValue("property_showteeth") as Boolean);
        colorMode.handleSettingUpdate();
    }
    /***
    function onShow() {
        System.println("SlavicsGearRearView.onShow()");
        SlavicsSimpleDataField.onShow();
        self.setTextLabel(label);
    }
    /***/
    function compute(info as Activity.Info) as Void {
        SlavicsSimpleDataField.compute(info);
        colorMode.compute();
        SlavicsSimpleDataField.setColors(colorMode.getColors());
        /***
        var bsds=rearShift.getDeviceState() as AntPlus.DeviceState;
        if(bsds!=null&&bsds.state!=null){
            switch(bsds.state){
                case AntPlus.DEVICE_STATE_SEARCHING:
                    self.labelArea.setColor(System.getClockTime().sec%2==0?" ."+label+". ":".."+label+"..");
                    break;
                case AntPlus.DEVICE_STATE_TRACKING:
                    self.setTextLabel(label);
                    break;
                default:
                    self.setTextLabel("?"+label+"?");
            }
        }
        /***/
        batteries=rearShift.getBatteries() as Array<RearShifting.BatteryData>;

        var rds=rearShift.getRearDerailleurStatus() as AntPlus.DerailleurStatus;
        teethsLabel.setColor(colorMode.getFieldColor(:label));
        if(rds!=null){
                if(rds.gearIndex!=null&&rds.gearIndex!=AntPlus.REAR_GEAR_INVALID){
                    if(rds.gearIndex!=lastIndex){
                        valueArea.setColor(colorMode.getFieldColor(:valueChange));
                    } else if(rds.gearIndex==0||rds.gearIndex==rds.gearMax-1){
                        valueArea.setColor(colorMode.getFieldColor(:valueEdge));
                    }
                    setTextValue((rds.gearIndex+1).toString());
                    teethsLabel.setText(rds.gearSize+unitTeeths);
                    lastIndex=rds.gearIndex;
                } else {
                    setTextValue("--");
                    teethsLabel.setText("");
                    lastIndex=-1;
                }
        } else {
            teethsLabel.setText("");
            valueArea.setColor(colorMode.getFieldColor(:error));
            setTextValue("xx");
            lastIndex=-2;
        }
        for(var j=0;j<INVALID_SHIFTS.size();j++){
            var count=0;
            switch(j){
                case 0:
                    count=rds.shiftFailureCount;
                    break;
                case 1:
                    count=rds.invalidInboardShiftCount;
                    break;
                case 2:
                    count=rds.invalidOutboardShiftCount;
                    break;
            }
            if(fails.get(INVALID_SHIFTS[j]).get(:count)!=count){
                fails.get(INVALID_SHIFTS[j]).put(:count,count);
                fails.get(INVALID_SHIFTS[j]).put(:change,true);
                failTime=FAIL_TIME_COUNTER;
                failLabel.setVisible(true);
                System.println("FAIL start fail["+j+"]="+rds.shiftFailureCount);
            }
        }

        if(failTime>=0){
            if(failTime>0){
                System.println("FAIL countDown failTime="+failTime);
                failTime--;
            } else {
                failTime=-1;
                System.println("FAIL end");
                failLabel.setVisible(false);
                for(var j=0;j<INVALID_SHIFTS.size();j++){
                    fails.get(INVALID_SHIFTS[j]).put(:change,false);
                }
            }
        }

    }
    var battIcon=new BatteryIcon({:font=>WatchUi.loadResource(Rez.Fonts.BatteryMedium),:justification=>Graphics.TEXT_JUSTIFY_RIGHT});
    var battFont=Graphics.FONT_TINY;

    public function onUpdate(dc as Dc) as Void {
        System.println("SlavicsGearRearView.onUpdate()");
        SlavicsSimpleDataField.onUpdate(dc);
        if(versionTest!=null){
            dc.setColor(Graphics.COLOR_YELLOW,Graphics.COLOR_TRANSPARENT);
            dc.drawText(1,1,Graphics.FONT_XTINY,versionTest,Graphics.TEXT_JUSTIFY_LEFT);
        }
        teethsLabel.draw(dc);
        //var FBT=WatchUi.loadResource(Rez.Fonts.BatterySmall);
        //b.setFont(FBT);
        if(batteries.size()>0){
            // Draw batteries
            
            var bLocX=dc.getWidth()-rim;
            var bLocY=dc.getHeight()-rim-Graphics.getFontHeight(battIcon.getFont());
            battIcon.locY=dc.getHeight()-rim-Graphics.getFontAscent(battIcon.getFont());
            battIcon.setNightMode(System.getDeviceSettings().isNightModeEnabled);
            for(var i=0;i<batteries.size();i++){
                var bd=(batteries as Array<RearShifting.BatteryData>)[i] as RearShifting.BatteryData;
                // Vertically
                if(bd.get(:batteryStatus)>0) {

                    battIcon.locX=bLocX;
                    battIcon.locY=bLocY;
                    battIcon.compute(bd.get(:batteryStatus),System.getClockTime().min%2==0);
                    battIcon.draw(dc);

                    dc.setColor(colorMode.getFieldColor(:label),Graphics.COLOR_TRANSPARENT);
                    dc.drawText(
                        bLocX-battIcon.getWidth(dc)-3,
                        bLocY+(Graphics.getFontAscent(battIcon.getFont())-Graphics.getFontAscent(battFont))/2,
                        battFont,bd.get(:name),Graphics.TEXT_JUSTIFY_RIGHT);
                    
                    bLocY-=Graphics.getFontHeight(battIcon.getFont())+3;
                }
            }
            /***
            bLocX=rim+5;
            var tt="0123456";
            var bFont=WatchUi.loadResource(Rez.Fonts.BatteryMedium);
            var bM=dc.getTextDimensions(tt,bFont);

            dc.setColor(Graphics.COLOR_GREEN,Graphics.COLOR_TRANSPARENT);
            dc.drawLine(bLocX-3,bLocY,bLocX+bM[0]+3,bLocY);
            dc.drawLine(bLocX,bLocY-3,bLocX,bLocY+bM[1]+3);
            dc.drawLine(bLocX-3,bLocY+Graphics.getFontAscent(bFont),bLocX+bM[0]+3,bLocY+Graphics.getFontAscent(bFont));
            dc.drawLine(bLocX-3,bLocY+Graphics.getFontHeight(bFont),bLocX+bM[0]+3,bLocY+Graphics.getFontHeight(bFont));

            dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_LT_GRAY);
            dc.drawText(bLocX,bLocY,bFont,"BBBBBBB",Graphics.TEXT_JUSTIFY_LEFT);
            dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);
            dc.drawText(bLocX,bLocY,bFont,"FFFFFFF",Graphics.TEXT_JUSTIFY_LEFT);
            dc.setColor(Graphics.COLOR_DK_GREEN,Graphics.COLOR_TRANSPARENT);
            dc.drawText(bLocX,bLocY,bFont,tt,Graphics.TEXT_JUSTIFY_LEFT);

            bLocX+=bM[0]+20;
            battIcon.locX=bLocX;
            battIcon.locY=bLocY;
            battIcon.compute(AntPlus.BATT_STATUS_NEW,true);
            battIcon.draw(dc);

            bLocX+=dc.getTextDimensions("0",bFont)[0];
            battIcon.locX=bLocX;
            battIcon.compute(AntPlus.BATT_STATUS_NEW,false);
            battIcon.draw(dc);

            bLocX+=dc.getTextDimensions("0",bFont)[0];
            battIcon.locX=bLocX;
            battIcon.compute(AntPlus.BATT_STATUS_GOOD,false);
            battIcon.draw(dc);

            bLocX+=dc.getTextDimensions("0",bFont)[0];
            battIcon.locX=bLocX;
            battIcon.compute(AntPlus.BATT_STATUS_OK,false);
            battIcon.draw(dc);

            bLocX+=dc.getTextDimensions("0",bFont)[0];
            battIcon.locX=bLocX;
            battIcon.compute(AntPlus.BATT_STATUS_LOW,false);
            battIcon.draw(dc);

            bLocX+=dc.getTextDimensions("0",bFont)[0];
            battIcon.locX=bLocX;
            battIcon.compute(AntPlus.BATT_STATUS_CRITICAL,false);
            battIcon.draw(dc);

            bLocX+=dc.getTextDimensions("0",bFont)[0];
            battIcon.locX=bLocX;
            battIcon.compute(AntPlus.BATT_STATUS_INVALID,false);
            battIcon.draw(dc);

            bLocX+=dc.getTextDimensions("0",bFont)[0];
            battIcon.locX=bLocX;
            battIcon.compute(AntPlus.BATT_STATUS_CNT,false);
            battIcon.draw(dc);

            //bM=dc.getTextDimensions(tt,Graphics.FONT_MEDIUM);
            /***
            dc.setColor(Graphics.COLOR_RED,Graphics.COLOR_TRANSPARENT);
            dc.drawLine(bLocX-3,bLocY,bLocX+bM[0]+3,bLocY);
            dc.drawLine(bLocX,bLocY-3,bLocX,bLocY+bM[1]+3);
            dc.drawLine(bLocX-3,bLocY+Graphics.getFontAscent(Graphics.FONT_MEDIUM),bLocX+bM[0]+3,bLocY+Graphics.getFontAscent(Graphics.FONT_MEDIUM));
            dc.drawLine(bLocX-3,bLocY+Graphics.getFontHeight(Graphics.FONT_MEDIUM),bLocX+bM[0]+3,bLocY+Graphics.getFontHeight(Graphics.FONT_MEDIUM));

            dc.setColor(Graphics.COLOR_DK_RED,Graphics.COLOR_LT_GRAY);
            dc.drawText(bLocX,bLocY,Graphics.FONT_MEDIUM,tt,Graphics.TEXT_JUSTIFY_LEFT);

            
            /***
            battIcon.locX=bLocX;
            battIcon.compute(AntPlus.BATT_STATUS_NEW,true);
            battIcon.draw(dc);bLocX-=battIcon.getWidth(dc);battIcon.locX=bLocX;
            battIcon.compute(AntPlus.BATT_STATUS_GOOD,false);
            battIcon.draw(dc);bLocX-=battIcon.getWidth(dc);battIcon.locX=bLocX;
            battIcon.compute(AntPlus.BATT_STATUS_OK,false);
            battIcon.draw(dc);bLocX-=battIcon.getWidth(dc);battIcon.locX=bLocX;
            battIcon.compute(AntPlus.BATT_STATUS_LOW,false);
            battIcon.draw(dc);bLocX-=battIcon.getWidth(dc);battIcon.locX=bLocX;
            battIcon.compute(AntPlus.BATT_STATUS_INVALID,false);
            battIcon.draw(dc);bLocX-=battIcon.getWidth(dc);battIcon.locX=bLocX;
            battIcon.compute(AntPlus.BATT_STATUS_CRITICAL,false);
            battIcon.draw(dc);bLocX-=battIcon.getWidth(dc);battIcon.locX=bLocX;
            battIcon.compute(AntPlus.BATT_STATUS_CNT,false);
            battIcon.draw(dc);bLocX-=battIcon.getWidth(dc);battIcon.locX=bLocX;
            
            dc.setColor(Graphics.COLOR_LT_GRAY,Graphics.COLOR_TRANSPARENT);
            dc.drawLine(0,bLocY,dc.getWidth(),bLocY);

            var fa=Graphics.getFontAscent(battFont);
            dc.drawLine(bLocX,bLocY-fa,bLocX,bLocY+2*fa);
            dc.drawLine(0,bLocY+fa,dc.getWidth(),bLocY+fa);
            dc.drawLine(0,bLocY+fa+Graphics.getFontDescent(battFont),dc.getWidth(),bLocY+fa+Graphics.getFontDescent(battFont));
            
            dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_TRANSPARENT);
            dc.drawText(bLocX,bLocY,battFont,"TŤyq",Graphics.TEXT_JUSTIFY_RIGHT);
            bLocX-=dc.getTextWidthInPixels("TŤyq",battFont);
            dc.drawText(bLocX,bLocY,battIcon.getFont(),"01023456",Graphics.TEXT_JUSTIFY_RIGHT);
            //bLocX-=dc.getTextWidthInPixels(bd.get(:name)+" ",Graphics.FONT_XTINY);
            /***/
        }
        if(Properties.getValue("property_showfailure") as Boolean && failLabel.isVisible){
            for(var j=0;j<INVALID_SHIFTS.size();j++){
                if(j==0){
                    failLabel.locX=rim;
                } else {
                    failLabel.locX+=dc.getTextWidthInPixels("/",Graphics.FONT_SMALL);
                }
                failLabel.setColor(fails.get(INVALID_SHIFTS[j]).get(:change)?colorMode.getFieldColor(:error):colorMode.getFieldColor(:label));
                failLabel.setText(fails.get(INVALID_SHIFTS[j]).get(:count).toString());
                failLabel.draw(dc);
                if(j<2){
                    failLabel.locX+=dc.getTextWidthInPixels(fails.get(INVALID_SHIFTS[j]).get(:count).toString(),Graphics.FONT_SMALL);
                    failLabel.setColor(colorMode.getFieldColor(:label));
                    failLabel.setText("/");
                    failLabel.draw(dc);
                }
            }
        }
    }
}
/***
XTINY edge840  11  8 3
XTINY edge1050 21 15 6

TINY  edge840  14 10 4
TINY  edge1050 28 20 8

edge840
#   HH  AA DD Name
0.  11   8  3 FONT_XTINY
1.  14  10  4 FONT_TINY
2.  17  12  5 FONT_SMALL
3.  19  14  5 FONT_MEDIUM
4.  31  22  9 FONT_LARGE
5.  35  28  7 FONT_NUMBER_MILD
6.  42  33  9 FONT_NUMBER_MEDIUM
7.  55  43 12 FONT_NUMBER_HOT
8.  67  53 14 FONT_NUMBER_THAI_HOT

edge1050
#   HH  AA DD Name
0.  21  15  6 FONT_XTINY
1.  28  20  8 FONT_TINY
2.  33  24  9 FONT_SMALL
3.  38  27 11 FONT_MEDIUM
4.  61  44 17 FONT_LARGE
5.  71  56 15 FONT_NUMBER_MILD
6.  82  65 17 FONT_NUMBER_MEDIUM
7. 109  86 23 FONT_NUMBER_HOT
8. 136 108 28 FONT_NUMBER_THAI_HOT

1/5 FONT_MEDIUM,FONT_NUMBER_HOT



/***/