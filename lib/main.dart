import 'statClasses.dart';
import "dart:convert";
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';


void main() => runApp(MyApp());

class _LocalStorage {

  static Map<String, Map<String, Stat>> statMap = {"Attribute" : {}, "Skill": {}, "Pool" : {}};
  static Map<String, Character> charMap = {};
  
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
  static Future<File> get _statFile async {
    final path = await _localPath;
    return File('$path/stat.json');
  }
  static Future<File> get _charFile async {
    final path = await _localPath;
    return File('$path/char.json');
  }

   static Future<File> writeStats() async {
    final file = await _statFile;
    return file.writeAsString(_scanOutStats());
  }

  static Future<File> writeChars() async {
    final file = await _charFile;
    return file.writeAsString(_scanOutChars());
  }

  static String _scanOutStats() {
    Map<String, Map<String, dynamic>> json = {};
    statMap.forEach((stat, statVal){
      statVal.forEach((key, value){
        if (json[stat] == null) {json[stat] = {};}
        json[stat][key]=value.toJson();
      });
    });
    return jsonEncode(json);
  }

  static String _scanOutChars() {
    Map<String, dynamic> json = {};
    charMap.forEach((key, value){
      json[key]=value.toJson();
    });
    return jsonEncode(json);
  }

  static Future<void> readStats() async {
    try {
      final file= await _statFile;
      _scanInStats(await file.readAsString());
    } catch(e) {
    }
  }

  static Future<void> readChars() async {
    try {
      final file= await _charFile;
      _scanInChars(await file.readAsString());
    } catch(e) {
    }
  }

  static void _scanInStats(String json) {
    var jsonMap = jsonDecode(json);
    jsonMap["Attribute"].forEach((key, value){
      statMap["Attribute"][key] = Attribute.fromJson(value, key);
    });
    jsonMap["Skill"].forEach((key, value){
      statMap["Skill"][key] = Skill.fromJson(value, key);
    });
    jsonMap["Pool"].forEach((key, value){
      statMap["Pool"][key] = Pool.fromJson(value, key);
    });
  }

  static void _scanInChars(String json) {
    var jsonMap = jsonDecode(json);
    jsonMap.forEach((key, value){
      charMap[key] = Character.fromJson(value, key);
    });
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScopeNode currentFocus = FocusScope.of(context);

        if(!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: MaterialApp(
          title: 'RPG Stat App',
          theme: ThemeData (
            primarySwatch: Colors.lime,
          ),
          initialRoute: '/character',
          routes: {
            '/character' : (BuildContext context) => MyScreen<Character>(),
            '/stat' : (BuildContext context) => MyScreen<Stat>(),
          }
      ),
    );
  }
}

class Viewer extends StatefulWidget {
  final String title;
  final Character character;
  Viewer({Key key, this.title, this.character}) : super(key: key);
  @override
  _ViewerState createState() => _ViewerState(character: this.character, title: this.title);
}

class _ViewerState extends State<Viewer>{
  final String title;
  final Character character;
  int _lastRoll;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _dNum = 20;

  _ViewerState({this.title, this.character}) : super();

  displayRoll([String key]) {
    _scaffoldKey.currentState.hideCurrentSnackBar();
    if (key!=null && character.attrs.containsKey(key)){
      _lastRoll = character.makeAttrRoll(key, _dNum);
    }
    else if (key!=null && character.skills.containsKey(key)) {
      _lastRoll = character.makeSkillRoll(key, _dNum);
    }
    else {
      _lastRoll = character.makeRoll(_dNum);
    }
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text("Last "+((key!=null)?(key+ " "):"") + "Roll was: " + _lastRoll.toString() + " on a $_dNum-sided Dice"),
    ));
  }

  Widget buildBody() {
    List<Widget> widgetList = [];
    widgetList.add(Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(child: TextFormField(
            initialValue: "20",
            keyboardType: TextInputType.number,
            onChanged: (value){
              setState(() {
                _dNum = int.parse(value);
              });
            },
          ), padding: EdgeInsets.all(10.0),),
          Container(child: Text("Sides on the Dice You Roll", style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15)), padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0))
        ],
      ),),
    IconButton(
      icon: Icon(Icons.casino),
      onPressed: () {displayRoll();},
    )
    ],));
    character.attrs.forEach((stat, statVal) {
      widgetList.add(Row(children: [
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [Container(
          child: Text(stat + ": " + statVal.base.toString() + (statVal.halfRounded?(((statVal.mod>0)?" (+":" (") + statVal.mod.toString() + ")"):""), textAlign: TextAlign.left,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
          padding: EdgeInsets.all(10.0),
        ), Container(
          child: Text(statVal.halfRounded
              ? "Uses D&D Style Modifier"
              : "Modifier is Stat Itself", textAlign: TextAlign.left,
            style: TextStyle(fontSize: 18),),
          padding: EdgeInsets.all(10.0),
        )
        ])),
        IconButton(
          icon: Icon(Icons.casino),
          onPressed: () {displayRoll(stat);},
        )
      ]));
    });
    character.skills.forEach((stat, statVal)
    {
      widgetList.add(Row(children: [
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [Container(
          child: Text(stat + ((statVal.mod > 0)?": +":": ") + statVal.mod.toString(), textAlign: TextAlign.left,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
          padding: EdgeInsets.all(10.0),
        ), Container(
          child: Text("Related Attribute: " + statVal.relatedAttribute,
            textAlign: TextAlign.left, style: TextStyle(fontSize: 18),),
          padding: EdgeInsets.all(10.0),
        )
        ])),
        IconButton(
          icon: Icon(Icons.casino),
          onPressed: () {displayRoll(stat);},
        )
      ]));
    });
    character.pools.forEach((stat, statVal) {
      widgetList.add(Row(children: [Expanded( child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          child: Text(stat, textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
          padding: EdgeInsets.all(10.0),
        ), Container(
          child: Text(statVal.pointer.toString() + "/" + statVal.max.toString(),
            textAlign: TextAlign.left, style: TextStyle(fontSize: 18),),
          padding: EdgeInsets.all(10.0),
        )
      ])),
        GestureDetector(
          child: IconButton(icon: Icon(Icons.add), onPressed: (){
            setState(() {
              statVal.increasePointer();
            });
            },),
          onLongPress: (){
            setState(() {
              statVal.resetPointer();
            });
          },
        ),
        GestureDetector(
          child: IconButton(icon: Icon(Icons.remove), onPressed: (){
            setState(() {
              statVal.decreasePointer();
            });
            },),
          onLongPress: (){
            setState(() {
              statVal.zeroPointer();
            });
          },
        ),
      ]));
    });
    return ListView(children: widgetList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text(title)),
      body: buildBody()
    );
  }

}

class Editor<T> extends StatefulWidget {
  final Character passedInValue;
  Editor({Key key, this.passedInValue}) : super(key: key);
  @override
  _EditorState<T> createState() => _EditorState(passedInValue);
}
class _EditorState<T> extends State<Editor<T>> {
  _EditorState([this.passedInValue]) : super();
  final _formKey = GlobalKey<FormState>();
  Character passedInValue;
  String _dropDownValue;
  String _secondaryDropDownValue;
  Stat _statDropDownValue;
  List<DropdownMenuItem<Stat>> _statDropDownList;
  bool _halfRounded;
  String _name;
  Map<String, Stat> _statList = Map();
  Map<String, Stat> _usedStatList = Map();
  @override
  void initState() {
    super.initState();
    _halfRounded = true;
    _LocalStorage.statMap.forEach((stat, statVal){
      _statList.addAll(statVal);
    });
    _statDropDownList = List();
    _statList.forEach((key, stat){
      _statDropDownList.add(DropdownMenuItem(value: stat, child: Text(stat.name)));
    });
    if (passedInValue != null) {
      passedInValue.attrs.forEach((key, value) {
        _usedStatList[key] = value;
        _statList.remove(key);
        _statDropDownList = List();
        _statList.forEach((key, stat) {
          _statDropDownList.add(
              DropdownMenuItem(value: stat, child: Text(stat.name)));
        });
      });
      passedInValue.skills.forEach((key, value) {
        _usedStatList[key] = value;
        _statList.remove(key);
        _statDropDownList = List();
        _statList.forEach((key, stat) {
          _statDropDownList.add(
              DropdownMenuItem(value: stat, child: Text(stat.name)));
        });
      });
      passedInValue.pools.forEach((key, value) {
        _usedStatList[key] = value;
        _statList.remove(key);
        _statDropDownList = List();
        _statList.forEach((key, stat) {
          _statDropDownList.add(
              DropdownMenuItem(value: stat, child: Text(stat.name)));
        });
      });
    }
  }
  List<Widget> getContent() {
    List<Widget> list = new List();
    if (T == Character) {
      list.addAll(getCharContent(passedInValue));
    }
    else if (T == Stat) {
      list.addAll(getStatContent());
    }
    return list;
  }

  List<Widget> getStatContent() {
    List<Widget> list = List();
    list.addAll([
      DropdownButton<String> (
        value: null,hint: Text("Stat"),
        onChanged: (String newValue) {
          setState(() {_dropDownValue = newValue;});
          },
        items: <String>["Attribute", "Skill", "Pool"].map<DropdownMenuItem<String>>((String value) {return DropdownMenuItem<String>(value: value, child: Text(value));}).toList(),
      )
    ]);
    if (_dropDownValue == "Attribute") {
      list.addAll([
        TextFormField(
          decoration: InputDecoration(labelText: "Attribute Name", hintText: "Name"),
          validator: (value) {
            if(value.isEmpty){
              return 'Please Enter a Name for the Attribute';
            }
            else if (_LocalStorage.statMap["Attribute"].keys.contains(value)) {
              return 'Enter a name you haven\'t used yet';
            }
            else {
              return null;
            }
          },
          onSaved: (value) {setState((){_name = value;});},
        ),
        CheckboxListTile(
            value: _halfRounded,
            onChanged: ((value) {
              setState(() {
                _halfRounded = value;
              });
            }),
            title: Text("Use D&D Attribute Mod Calculation")
        ),
        RaisedButton(child: Text("Enter"),
          onPressed: () {
          if(_formKey.currentState.validate()){
            _formKey.currentState.save();
            Navigator.pop(context, new Attribute(_name, null, _halfRounded));
          }
          },
        )
      ]);
    }
    else if (_dropDownValue == "Skill") {
      List<DropdownMenuItem<String>> attrList = [];
      _LocalStorage.statMap["Attribute"].forEach((key, value){
        attrList.add(DropdownMenuItem(child: Text(key), value: key));
      });
      list.addAll([
        TextFormField(
          decoration: InputDecoration(labelText: "Skill Name", hintText: "Name"),
          validator: (value) {
            if(value.isEmpty){
              return 'Please Enter a Name for the Skill';
            }
            else if (_LocalStorage.statMap["Skill"].keys.contains(value)) {
              return 'Enter a name you haven\'t used yet';
            }
            else {return null;}
          },
          onSaved: (value) {setState((){_name = value;});},
        ),
        DropdownButtonFormField<String>(
          value: _secondaryDropDownValue,
          hint: Text("Select an Attribute"),
          disabledHint: Text("Create an Attribute first!"),
          onChanged: (String newValue) {setState(() {_secondaryDropDownValue = newValue;});},
          items: attrList,
          validator: (value){
            if(value == null) {
              return "Select an Attribute";
            }
            else if (attrList.length == 0) {
              return "Create an Attribute first!";
            }
            else {return null;}
          },
        ),
        RaisedButton(child: Text("Enter"),
          onPressed: () {
            if((_formKey.currentState.validate())){
              _formKey.currentState.save();
              Navigator.pop(context, new Skill(_name, _secondaryDropDownValue, null));
            }
          },
        )
      ]);
    }
    else if (_dropDownValue == "Pool") {
      list.addAll([
        TextFormField(
          decoration: InputDecoration(labelText: "Pool Name", hintText: "Name"),
          validator: (value) {
            if(value.isEmpty){
              return 'Please Enter a Name for the Pool';
            }
            else if (_LocalStorage.statMap["Pool"].keys.contains(value)) {
              return 'Enter a name you haven\'t used yet';
            }
            else {return null;}
          },
          onSaved: (value) {
            setState((){_name = value;});
          },
        ),
        RaisedButton(child: Text("Enter"),
          onPressed: () {
            if(_formKey.currentState.validate()){
              _formKey.currentState.save();
              Navigator.pop(context, new Pool(_name, null));
            }
          },
        )
      ]);
    }
    return list;
  }

  List<Widget> getCharContent([Character passedInValue]) {
    List<Widget> list = List();
    list.addAll(<Widget>[
      TextFormField(
        decoration: InputDecoration(labelText: "Character Name", hintText: "Name"),
        initialValue: passedInValue?.name,
        validator: (value) {
          if(value.isEmpty){
            return 'Please Enter a Name for the Character';
          }
          else if (_LocalStorage.charMap.keys.contains(value) && passedInValue == null) {
            return 'Enter a name you haven\'t used yet';
          }
          else {
            return null;
          }
        },
        onSaved: (value) {setState((){_name = value;});},
      ),
      Row(
        children: <Widget>[
          Expanded(
            child: DropdownButton<Stat>(
                value: _statDropDownValue,
                hint: Text("Select a Stat"),
                disabledHint: Text("No Values Found"),
                onChanged: (Stat newStat){
                  setState(() {
                    _statDropDownValue = newStat;
                  });
                },
                items: _statDropDownList,
            ),
          ),
          IconButton(
            icon: Icon(Icons.add_circle),
            onPressed: (){
              if (_statDropDownValue != null){
                setState(() {
                  _usedStatList[_statDropDownValue.name] = _statList[_statDropDownValue.name];
                  _statList.remove(_statDropDownValue.name);
                  _statDropDownValue=null;
                  _statDropDownList = List();
                  _statList.forEach((key, stat){
                    _statDropDownList.add(DropdownMenuItem(value: stat, child: Text(stat.name)));
                  });
                });
              }
            },
          )
        ],
      )
    ]);
    if (_usedStatList.length > 0){
      _usedStatList.forEach((key, value){
        if (value is Attribute) {
          list.add(Row(
            children: <Widget>[
              Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(key + " (Attribute)"),
                  TextFormField(
                    initialValue: value.base?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Attribute Value", hintText: "Value"),
                    validator: (value2) {
                      if(value2.isEmpty){
                        return 'Please Enter a number';
                      }
                      else return null;
                    },
                    onSaved: (value2) {
                      setState((){
                        value.base=int.parse(value2);
                      });
                    },
                  )
                ],
              ),),
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: (){
                  setState(() {
                    _statList[key] = _usedStatList[key];
                    _usedStatList.remove(key);
                    _statDropDownList = List();
                    _statList.forEach((key, stat){
                      _statDropDownList.add(DropdownMenuItem(value: stat, child: Text(stat.name)));
                    });
                  });
                },
              )
            ],
          ));
        }
        else if (value is Skill) {
          list.add(Row(
            children: <Widget>[
              Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(key + " (Skill)"),
                  TextFormField(
                    initialValue: value.mod?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Skill Modifier", hintText: "Modifier"),
                    validator: (value2) {
                      if(value2.isEmpty){
                        return 'Please Enter a number';
                      }
                      else return null;
                    },
                    onSaved: (value2) {
                      setState((){
                        value.mod=int.parse(value2);
                      });
                    },
                  )
                ],
              ),),
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: (){
                  setState(() {
                    _statList[key] = _usedStatList[key];
                    _usedStatList.remove(key);
                    _statDropDownList = List();
                    _statList.forEach((key, stat){
                      _statDropDownList.add(DropdownMenuItem(value: stat, child: Text(stat.name)));
                    });
                  });
                },
              )
            ],
          ));
        }
        else if (value is Pool) {
          list.add(Row(
            children: <Widget>[
              Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(key + " (Pool)"),
                  TextFormField(
                    initialValue: value.max?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Pool Maximum", hintText: "Maximum"),
                    validator: (value2) {
                      if(value2.isEmpty){
                        return 'Please Enter a number';
                      }
                      else return null;
                    },
                    onSaved: (value2) {
                      setState((){
                        value.max=int.parse(value2);
                        value.resetPointer();
                      });
                    },
                  )
                ],
              ),),
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: (){
                  setState(() {
                    _statList[key] = _usedStatList[key];
                    _usedStatList.remove(key);
                    _statDropDownList = List();
                    _statList.forEach((key, stat){
                      _statDropDownList.add(DropdownMenuItem(value: stat, child: Text(stat.name)));
                    });
                  });
                },
              )
            ],
          ));
        }
      });

    }
    list.add(RaisedButton(child: Text("Enter"),
      onPressed: () {
        if(_formKey.currentState.validate()){
          _formKey.currentState.save();
          Navigator.pop(context, new Character(_name, _usedStatList));
        }
      },
    ));
    return list;
  }

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text( T.toString() + " Editor"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(key: _formKey, child: new ListView(children: getContent())),
      ),
    );
  }
}

class MyScreen<T> extends StatefulWidget{
  MyScreen({Key key}) : super(key: key);
  @override
  _ScreenState<T> createState() => _ScreenState();
}

class _ScreenState<T> extends State<MyScreen<T>> {
  @override
  void initState() {
    _LocalStorage.readChars();
    _LocalStorage.readStats();
    super.initState();
  }
  Drawer getMyDrawer(BuildContext context) => Drawer(
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
  );

  _awaitEditedCharacter(BuildContext context, Character charEdit, String oldKey) async {
    Character result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Editor<Character>(passedInValue: charEdit,))
    );
    if (result !=null) {
      _LocalStorage.charMap.remove(oldKey);
      _LocalStorage.charMap[result.name] = result;
      setState(() {
        _LocalStorage.writeChars();
      });
    }
  }

  _awaitValueFromEditor(BuildContext context) async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Editor<T>())
    );
    if (result != null) {
      if (T == Stat) {
        if (result is Attribute) {
          _LocalStorage.statMap["Attribute"][result.name] = result;
        }
        else if (result is Skill) {
          _LocalStorage.statMap["Skill"][result.name] = result;
        }
        else if (result is Pool) {
          _LocalStorage.statMap["Pool"][result.name] = result;
        }
        setState(() {
          _LocalStorage.writeStats();
        });
      }
      else if (T == Character) {
        _LocalStorage.charMap[result.name] = result;
        setState(() {
          _LocalStorage.writeChars();
        });
      }
    }
  }
  Widget getBody() {
    if (T == Stat){
      return getStatBody();
    }
    else if (T == Character) {
      return getCharBody();
    }
    else {
      return Text("Improper Type!");
    }
  }

  Widget getStatBody() {
    List<Widget> widgetList = [];
    if ((_LocalStorage.statMap["Attribute"].length + _LocalStorage.statMap["Skill"].length + _LocalStorage.statMap["Pool"].length) == 0) {
      widgetList.add(Padding(child: Center( child: Text("Create Stats with the + Below!")), padding: EdgeInsets.all(16.0),));
    }
    else {
      _LocalStorage.statMap.forEach((stat, statVal) {
        if (statVal.length != 0) {
          widgetList.add(Container(
            child: Text(stat, textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),),
            padding: EdgeInsets.all(10.0),
          ));
          statVal.forEach((key, value){
            widgetList.add(Divider(
                indent: 5.0,
                endIndent: 5.0,
                color: Colors.black26
            ));
            if (value is Attribute) {
              widgetList.add(Row(children: [Expanded( child: Column (crossAxisAlignment: CrossAxisAlignment.start, children: [Container(
                child: Text(key, textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
                padding: EdgeInsets.all(10.0),
              ), Container(
                child: Text(value.halfRounded ? "Uses D&D Style Modifier" : "Modifier is Stat Itself", textAlign: TextAlign.left, style: TextStyle(fontSize: 18),),
                padding: EdgeInsets.all(10.0),
              )])),
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: (){

                    _LocalStorage.statMap["Attribute"].remove(key);
                    setState(() {_LocalStorage.writeStats();});
                  },
                )
              ]));
            }
            else if (value is Skill) {
              widgetList.add(Row(children: [Expanded( child: Column (crossAxisAlignment: CrossAxisAlignment.start,  children: [Container(
                child: Text(key, textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
                padding: EdgeInsets.all(10.0),
              ), Container(
                child: Text("Related Attribute: " + value.relatedAttribute, textAlign: TextAlign.left, style: TextStyle(fontSize: 18),),
                padding: EdgeInsets.all(10.0),
              )])),
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: (){

                    _LocalStorage.statMap["Skill"].remove(key);
                    setState(() {_LocalStorage.writeStats();});
                  },
                )
              ]));
            }
            else if (value is Pool){
              widgetList.add(Row(children: [Expanded( child: Container(
                child: Text(key, textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
                padding: EdgeInsets.all(10.0),
              )),
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: (){
                    _LocalStorage.statMap["Pool"].remove(key);
                    setState(() {_LocalStorage.writeStats();});
                  },
                )
              ]));
            }
          });
          widgetList.add(Divider(
              indent: 5.0,
              endIndent: 5.0,
              color: Colors.black54
          ));
        }
      });
    }
    return ListView(children: widgetList);
  }

  Widget getCharBody() {
    List<Widget> widgetList = List();
    if (_LocalStorage.charMap.length == 0) {
      widgetList.add(Padding(child: Center( child: Text("Create Characters with the + Below!")), padding: EdgeInsets.all(16.0),));
    }
    else{
      widgetList.add(Container(
        child: Text("Characters", textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),),
        padding: EdgeInsets.all(10.0),
      ));
      _LocalStorage.charMap.forEach((key, value) {
        widgetList.add(Divider(
            indent: 5.0,
            endIndent: 5.0,
            color: Colors.black26
        ));
        widgetList.add(
            Row(
                children: [
                  Expanded(child: GestureDetector(
                    child: Padding(child: Text(key, textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.normal, fontSize: 25),), padding:EdgeInsets.all(16.0)),
                    onTap: (){
                      Navigator.push(context,  MaterialPageRoute(builder: (context) => Viewer(title: key, character: value)));
                      },
                    onDoubleTap: (){
                      _awaitEditedCharacter(context, value, key);
                    },
                  )),
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: (){
                      _LocalStorage.charMap.remove(key);
                      setState(() {_LocalStorage.writeChars();});
                    },
                  )
                ]
            )
        );
      });
    }
    return ListView(children: widgetList);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text(T.toString() + "s")),
      body: getBody(),
      drawer:getMyDrawer(context),
     floatingActionButton: FloatingActionButton(
        onPressed: (){_awaitValueFromEditor(context);},
        tooltip: "New "+T.toString(),
        child: Icon(Icons.add)
      ),
    );
  }
}
