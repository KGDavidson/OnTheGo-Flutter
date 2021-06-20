import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onthego/ScreenFavourites.dart';
import 'ScreenNearby.dart';
import 'ScreenFavourites.dart';
import 'ScreenRoutePlanner.dart';

final double bottomNavigationBarHeight = 60;
bool run = false;

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return MaterialApp(
      title: 'OnTheGo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Main(),
    );
  }
}

class Main extends StatefulWidget {
  @override
  _Main createState() => _Main();
}

class _Main extends State<Main> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child:  Scaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: Container(
            color: Color(0xff2b2e4a),
            child: TabBar(
              labelColor: Color(0xffe84545),
              unselectedLabelColor: Colors.white,
              indicator: BoxDecoration(
              ),
              labelPadding: EdgeInsets.all(5),
              tabs: [
                Tab(
                  icon: Icon(
                    Icons.near_me,
                    size: 25,
                  ),
                ),
                Tab(
                  icon: Icon(
                    Icons.favorite,
                    size: 25,
                  ),
                ),
                /*Tab(
                  icon: Icon(Icons.alt_route),
                  text: 'Route Planner',
                ),*/
              ],
            ),
          ),
          body: TabBarView(
            children: [
              ScreenNearby(),
              ScreenFavourites(),
            ],
          ),
        ),
      ),
    );
  }
}
