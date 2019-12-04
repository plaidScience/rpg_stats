import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPG Stat App',
      theme: ThemeData (
        primarySwatch: Colors.lime,
      ),
      initialRoute: '/character',
      routes: {
        '/character' : (BuildContext context) => MyScreen(title: "Characters", type: "chars"),
        //'/character/viewer' : (BuildContext context) => Viewer(),
        '/character/editor' : (BuildContext context) => Editor(),
        '/stat' : (BuildContext context) => MyScreen(title: "Stats", type: "stats"),
        //'/stat/viewer' : (BuildContext context) => Viewer(),
        '/stat/editor' : (BuildContext context) => Editor()
      }
    );
  }
}

/*class Viewer extends StatelessWidget{
  final String title;
  Viewer({Key key, this.title}) : super(key: key);

}*/

class Editor extends StatelessWidget {
  final String title;
  Editor({Key key, this.title}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
    );
  }
}

class MyScreen extends StatelessWidget {
  final String title;
  final String type;
  MyScreen({Key key, this.title, this.type}) : super(key: key);
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('My Page!')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('RPG Stat App', style: TextStyle(color: Colors.black, fontSize: 25.0)),
              decoration: BoxDecoration(
                color: Colors.lime,
              ),
            ),
            ListTile(
              title: Text('Characters'),
              onTap: () {
                //navigate to the item
                Navigator.pushReplacementNamed(context, '/character');
              },
            ),
            Divider(
              indent: 5.0,
              endIndent: 5.0,
              color: Colors.black26
            ),
            ListTile(
              title: Text('Stats'),
              onTap: () {
                //navigate to the item
                Navigator.pushReplacementNamed(context, '/stat');
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){Navigator.pushNamed(context, "/editor");},
        tooltip: "New "+title,
        child: Icon(Icons.add)
      ),
    );
  }
}