import 'package:city_pickers/city_pickers.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _selectStr = "",_selectListStr = "";

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
            FlatButton(
              child: Text(
                "TabPicker",
                style: TextStyle(color: Colors.white),
              ),
              color: Colors.blue,
              onPressed: () {
                List<CityPoint> cityList = [];
                List<CityPoint> childrenList = [];
                for (int i = 0; i < 10; i++) {
                  for (int i = 0; i < 10; i++) {
                    childrenList.add(CityPoint.fromParams(
                      label: "Label--$i",
                      value: "Value--$i",
                      children: [],
                    ));
                  }
                  cityList.add(CityPoint.fromParams(
                    label: "Label--$i",
                    value: "Value--$i",
                    children: childrenList,
                  ));
                }
                CityPickers.showCityPicker2List(
                        context: context,
                        height: 400,
                        provinceCityAreaList: cityList,
                        initDataResult: Result(
                            provinceId: "Value--1",
                            provinceName: "Label--1",
                            cityId: "Value--6",
                            cityName: "Label--6"),
                        showType: ShowType.pc)
                    .then((value) {
                  setState(() {
                    _selectListStr = "$value";
                  });
                });
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10,horizontal: 15),
              child: Text(
                '$_selectListStr',
                style: TextStyle(fontSize: 16),
              ),
            ),
            FlatButton(
              child: Text(
                "CityPicker",
                style: TextStyle(color: Colors.white),
              ),
              color: Colors.blue,
              onPressed: () {
                List<CityPoint> cityList = [];
                List<CityPoint> childrenList = [];
                for (int i = 0; i < 10; i++) {
                  for (int i = 0; i < 10; i++) {
                    childrenList.add(CityPoint.fromParams(
                      label: "Label--$i",
                      value: "Value--$i",
                      children: [],
                    ));
                  }
                  cityList.add(CityPoint.fromParams(
                    label: "Label--$i",
                    value: "Value--$i",
                    children: childrenList,
                  ));
                }
                CityPickers.showCityPicker2(
                    context: context,
                    height: 400,
                    provinceCityAreaList: cityList,
                    initDataResult: Result(
                        provinceId: "Value--1",
                        provinceName: "Label--1",
                        cityId: "Value--6",
                        cityName: "Label--6"),
                    showType: ShowType.pc)
                    .then((value) {
                  setState(() {
                    _selectStr = "$value";
                  });
                });
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10,horizontal: 15),
              child: Text(
                '$_selectStr',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
