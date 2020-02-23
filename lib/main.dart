import 'package:flutter/material.dart';
import 'package:flutter_explode_widget/explode_widget.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);


  final String title;

  @override
  //_MyHomePageState createState() => _MyHomePageState();
  _ExplodeWidgetState createState() => _ExplodeWidgetState();
}


class _ExplodeWidgetState extends State<MyHomePage>{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return  Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity,50),
        child: AppBar(
          title: Text("explode widget"),
          automaticallyImplyLeading: false,
        ),
      ),
      body: Container(
        child: Stack(
          children: <Widget>[
            ExplodeWidget(
                imagePath: 'assets/images/swiggy.png',
                imagePosFromLeft: 50.0,
                imagePosFromTop: 200.0),
            ExplodeWidget(
                imagePath: 'assets/images/chrome.png',
                imagePosFromLeft: 200.0,
                imagePosFromTop: 400.0),
            ExplodeWidget(
                imagePath: 'assets/images/firefox.png',
                imagePosFromLeft: 350.0,
                imagePosFromTop: 600.0)
          ],
        ),
      ),
    );
  }

}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {

      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        title: Text(widget.title),
      ),
      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
