import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onthego/ScreenFavourites.dart';
import 'ScreenNearby.dart';
import 'ScreenFavourites.dart';
import 'ScreenRoutePlanner.dart';

final double bottomNavigationBarHeight = 60;

void main() {
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

  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static List<Widget> _widgetOptions = <Widget>[
    ScreenNearby(),
    ScreenFavourites(),
    //ScreenRoutePlanner(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffe8e8e8),
      body: SafeArea(
        child:  _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: SizedBox(
        height: bottomNavigationBarHeight,
        child: BottomNavigationBar(
          backgroundColor: Color(0xff2b2e4a),
          selectedItemColor: Color(0xffe84545),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          unselectedItemColor: Color(0xffffffff),
          showUnselectedLabels: false,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.near_me),
              label: 'Nearby',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favourites',
            ),
            /*BottomNavigationBarItem(
            icon: Icon(Icons.alt_route),
            label: 'Route Planner',
          ),*/
          ],
        ),
      )
    );
  }
}
