

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

import 'package:vector_math/vector_math_64.dart' hide Colors;


///爆炸持续时间
const explosionDuration = Duration(milliseconds: 1500);
///抖动持续时间
const shakingDuration = Duration(milliseconds: 3000);
///碎裂粒子数
const noOfParticles = 64;



class ExplodeWidget extends StatelessWidget{

  final String  imagePath;

  final double imagePosFromLeft;

  final double imagePosFromTop;


  ExplodeWidget(this.imagePath, this.imagePosFromLeft, this.imagePosFromTop);

  @override
  Widget build(BuildContext context) {

    final screenSize = MediaQuery.of(context).size;
    return Container(
      child: ExplodeWidgetBody(
        screenSize,imagePath,imagePosFromLeft,imagePosFromTop
      ),
    );
  }

}



class ExplodeWidgetBody extends StatefulWidget{

  Size screenSize;

  String imagePath;

  double imagePosFromLeft,imagePosFromTop;


  ExplodeWidgetBody(this.screenSize, this.imagePath, this.imagePosFromLeft,
      this.imagePosFromTop);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return ExplodeWidgetBodyState();
  }

}



///动画 需要 混入TickerProviderStateMixin  告知同步刷新此widget
class ExplodeWidgetBodyState extends State<ExplodeWidgetBody> with TickerProviderStateMixin {

  //key is unique across the entire app
  GlobalKey currentKey;
  GlobalKey imageKey = GlobalKey();
  GlobalKey paintKey = GlobalKey();

  bool useSnapshot = true;
  bool isImage = true;
  math.Random random;

  ///分裂的粒子
  final List<Particle> particles = [];


  ///for shaking
  AnimationController imageAnimationController;

  double imageSize = 50.0;

  img.Image photo;

  double distFromLeft =10.0,distFromTop = 10.0;

  /// Controller that allows sending events on stream on change of the colors of the pixels
  final StreamController<Color> _stateController = StreamController<Color>.broadcast();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    currentKey = useSnapshot ? paintKey : imageKey;
    random = new math.Random();

    imageAnimationController = AnimationController(
      vsync: this,duration: Duration(milliseconds: 3000)
    );

  }

  ///横向 抖动 图片
  Vector3 _shakeImage(){
    return Vector3(
        (math.sin(imageAnimationController.value) * math.pi * 20.0)*8,
      0.0,0.0
    );
  }

  //加载图片字节数据
  Future<void> loadImageBundleBytes()async{
    ByteData imageBytes = await rootBundle.load(widget.imagePath);
    setImageBytes(imageBytes);
  }

  Future<void> loadSnapshotBytes()async{
    //配合RenderBoundary 可以用来截屏
    RenderRepaintBoundary boxPaint = paintKey.currentContext.findRenderObject();
    ui.Image capture = await boxPaint.toImage();

    ByteData imageByteData = await capture.toByteData(format: ui.ImageByteFormat.png);
    setImageBytes(imageByteData);
    capture.dispose();

  }

  //根据 图片字节数据 通过img 转成 Image给photo
  void setImageBytes(ByteData imageBytes){
    List<int> values = imageBytes.buffer.asUint8List();
    photo = img.decodeImage(values);
  }

  Future<Color> getPixel(Offset globalPosition,Offset position,double size)async{
    if(photo == null){
      /// 初始化 photo
      await(useSnapshot ? loadSnapshotBytes() : loadImageBundleBytes());
    }

    Color newColor = calculatePixel(globalPosition,position,size);

    return newColor;

  }
  ///得到一个可以给粒子使用的颜色
  Color calculatePixel(Offset globalPosition,Offset position,double size){
    double px = position.dx;
    double py = position.dy;

    if(!useSnapshot){
      double widgetScale = size / photo.width;
      px = (px / widgetScale);
      py = (py / widgetScale);
    }

    int pixel32 = photo.getPixelSafe(px.toInt() +1, py.toInt());

    int hex = abgrToArgb(pixel32);

    _stateController.add(Color(hex));

    Color returnColor = Color(hex);
    return returnColor;

  }

  // As image.dart library uses KML format i.e. #AABBGGRR, this method converts it to normal #AARRGGBB format
  int abgrToArgb(int argbColor) {
    int r = (argbColor >> 16) & 0xFF;
    int b = argbColor & 0xFF;
    return (argbColor & 0xFF00FF00) | (b << 16) | r;
  }



  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return null;
  }
}



class Particle extends ExplodeWidgetBodyState{

  int id;
  Size screenSize;
  Offset position;
  Paint singleParticle;

  double offsetX = 0.0,offsetY = 0.0;
  double newOffsetX = 0.0,newOffsetY = 0.0;

  static final randomValue = math.Random();

  AnimationController animationController;


  Animation translateXAnimation,negateTranslateXAnimation;
  Animation translateYAnimation,negateTranslateYAnimation;

  Animation fadingAnimation;

  Animation particleSize;

  double lastXOffset,lastYOffset;

  Color colors;


  Particle({
    @required this.id,@required this.screenSize,this.colors,this.offsetX,this.offsetY
    ,this.newOffsetX,this.newOffsetY}){
    position = new Offset(this.offsetX, this.offsetY);

    math.Random random = new math.Random();
    //粒子最终消失的位置
    this.lastXOffset = random.nextDouble() * 100;
    this.lastYOffset = random.nextDouble() * 100;

    animationController = new AnimationController(vsync: this,duration: Duration(milliseconds: 1500));

    //define Tween
    translateXAnimation = Tween(begin: position.dx,end: lastXOffset).animate(animationController);
    translateYAnimation = Tween(begin: position.dy,end: lastYOffset).animate(animationController);
    negateTranslateXAnimation =
        Tween(begin: -1 * position.dx, end: -1 * lastXOffset)
            .animate(animationController);
    negateTranslateYAnimation =
        Tween(begin: -1 * position.dy, end: -1 * lastYOffset)
            .animate(animationController);

    //渐隐
    fadingAnimation = Tween<double>(
      begin: 1.0,end: 0.0
    ).animate(animationController);


    particleSize = Tween(begin: 5.0,end: random.nextDouble() * 20).animate(animationController);

  }


  ///start animation of the particle
  ///FractionalOffset 权重， 子widget 相对于父widget 的定位
  ///
  startParticleAnimation(){
    animationController.forward();
    ///向四个方向扩散 并消失
    return Container(
      alignment: FractionalOffset(newOffsetX / screenSize.width,newOffsetY / screenSize.height),
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context,widget){
          if(id % 4 == 0){
            return Transform.translate(offset: Offset(translateXAnimation.value,translateYAnimation.value)
                ,child: FadeTransition(
                  opacity: fadingAnimation,
                child: Container(
                  width: particleSize.value > 5 ?  particleSize.value :5,
                  height: particleSize.value > 5 ? particleSize.value:5,
                  decoration: BoxDecoration(color: colors,shape: BoxShape.circle),
                ),
              ),);
          }else if(id % 4 == 1){
            return Transform.translate(
                offset: Offset(
                    negateTranslateXAnimation.value, translateYAnimation.value),
                child: FadeTransition(
                  opacity: fadingAnimation,
                  child: Container(
                    width: particleSize.value > 5 ? particleSize.value : 5,
                    height: particleSize.value > 5 ? particleSize.value : 5,
                    decoration:
                    BoxDecoration(color: colors, shape: BoxShape.circle),
                  ),
                ));
          }else if(id % 4 == 2){
            return Transform.translate(
                offset: Offset(
                    translateXAnimation.value, negateTranslateYAnimation.value),
                child: FadeTransition(
                  opacity: fadingAnimation,
                  child: Container(
                    width: particleSize.value > 5 ? particleSize.value : 5,
                    height: particleSize.value > 5 ? particleSize.value : 5,
                    decoration:
                    BoxDecoration(color: colors, shape: BoxShape.circle),
                  ),
                ));
          }else {
            return Transform.translate(
                offset: Offset(negateTranslateXAnimation.value,
                    negateTranslateYAnimation.value),
                child: FadeTransition(
                  opacity: fadingAnimation,
                  child: Container(
                    width: particleSize.value > 5 ? particleSize.value : 5,
                    height: particleSize.value > 5 ? particleSize.value : 5,
                    decoration:
                    BoxDecoration(color: colors, shape: BoxShape.circle),
                  ),
                ));
          }
        },
      ),
    );
  }




}






















