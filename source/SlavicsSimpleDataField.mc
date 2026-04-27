import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

class SlavicsSimpleDataField extends WatchUi.DataField {
    private const LABELHEIGHT=0.25f as Numeric;
    public const FONTS=[
            Graphics.FONT_NUMBER_THAI_HOT,
            Graphics.FONT_NUMBER_HOT,
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD,
            Graphics.FONT_LARGE,
            Graphics.FONT_MEDIUM,
            Graphics.FONT_SMALL,
            Graphics.FONT_TINY,
            Graphics.FONT_XTINY,
        ] as Array<Graphics.FontType>;

    protected var labelArea = new WatchUi.TextArea({
            :text=>"",
            :color=>Graphics.COLOR_DK_GRAY,
            :font=>FONTS.slice(4,null),
            :justification => Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER,
        }) as TextArea;
    protected var valueArea=new WatchUi.TextArea({
            :text=>"",
            :color=>Graphics.COLOR_DK_BLUE,
            :font=>FONTS,
            :justification => Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER,
        }) as TextArea;
    public var rim=0 as Number;
    public var labelLine=0 as Number;
    //protected var textLabel="Label" as String;
    //protected var textValue="Value" as String;

    function initialize() {
        System.println("SlavicsSimpleDataField.initialize()");
        DataField.initialize();
    }

    function onLayout(dc as Dc) as Void {
        System.println("SlavicsSimpleDataField.onLayout() "+dc.getWidth()+"x"+dc.getHeight());
        rim=dc.getHeight()*0.02f;
        labelLine=dc.getHeight()*LABELHEIGHT;

        labelArea.locX=rim;
        labelArea.locY=rim;
        labelArea.width=dc.getWidth()-2*rim;
        labelArea.height=labelLine-rim;

        valueArea.locX=rim;
        valueArea.locY=labelLine;
        valueArea.width=dc.getWidth()-2*rim;
        valueArea.height=dc.getHeight()-labelLine;

    }

    public function setTextLabel(text as String or Null){
        System.println("SlavicsSimpleDataField.setTextLabel('"+text+"')");
        labelArea.setText(text!=null?text:"--");
    }

    public function setTextValue(text as String or Null){
        System.println("SlavicsSimpleDataField.setTextValue('"+text+"')");
        valueArea.setText(text!=null?text:"--");
    }
    
    public function compute(info as Activity.Info) as Void {
        valueArea.setColor(System.getDeviceSettings().isNightModeEnabled?Graphics.COLOR_WHITE:Graphics.COLOR_BLACK);
        labelArea.setColor(System.getDeviceSettings().isNightModeEnabled?Graphics.COLOR_LT_GRAY:Graphics.COLOR_DK_GRAY);
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    
    public function onUpdate(dc as Dc) as Void {
        System.println("SlavicsSimpleDataField.onUpdate()");
        dc.setColor(Graphics.COLOR_TRANSPARENT, System.getDeviceSettings().isNightModeEnabled?Graphics.COLOR_BLACK:Graphics.COLOR_WHITE);
        dc.clear();
        valueArea.draw(dc);
        labelArea.draw(dc);
        onUpdateAfter(dc);
    }
    (:release)
    private function onUpdateAfter(dc as Dc) as Void {
    }
    (:debug)
    private function onUpdateAfter(dc as Dc) as Void {
        //dc.setColor(Graphics.COLOR_TRANSPARENT, System.getDeviceSettings().isNightModeEnabled?Graphics.COLOR_BLACK:Graphics.COLOR_WHITE);
        //dc.clear();
        //valueArea.draw(dc);
        //labelArea.draw(dc);

        dc.setColor(Graphics.COLOR_LT_GRAY,Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(rim,rim,dc.getWidth()-2*rim,dc.getHeight()*LABELHEIGHT-rim);
        dc.drawRectangle(rim,dc.getHeight()*LABELHEIGHT,dc.getWidth()-2*rim,dc.getHeight()*(1-LABELHEIGHT)-rim);
    }

}
