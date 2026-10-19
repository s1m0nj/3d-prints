ObjC.import('AppKit'); ObjC.import('CoreGraphics');
function run(argv){
  var f=$.NSScreen.mainScreen.frame; 
  var x=parseFloat(argv[0]), y=parseFloat(argv[1]);
  var p=$.CGPointMake(x,y);
  var d=$.CGEventCreateMouseEvent(null,$.kCGEventLeftMouseDown,p,0);
  var u=$.CGEventCreateMouseEvent(null,$.kCGEventLeftMouseUp,p,0);
  $.CGEventPost($.kCGHIDEventTap,d); $.CGEventPost($.kCGHIDEventTap,u);
  return f.size.width+"x"+f.size.height;
}
