import 'dart:async';

import 'package:city_pickers/modal/city_point.dart';
import 'package:city_pickers/modal/label_select_bean.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../modal/result.dart';
import '../mod/inherit_process.dart';
import '../show_types.dart';

/// @desc 列表形式展示地址选择框
/// @time 2020-07-09 15:40
/// @author lizubing1992
class BaseSheetListView extends StatefulWidget {
  final double progress;
  final String locationCode;
  final ShowType showType;
  final List<CityPoint> provinceCityAreaList;

  final Result initDataResult;

  // 容器高度
  final double height;

  BaseSheetListView({
    this.progress,
    this.showType,
    this.height,
    this.locationCode,
    this.provinceCityAreaList,
    this.initDataResult,
  });

  _BaseSheetListView createState() => _BaseSheetListView();
}

class _BaseSheetListView extends State<BaseSheetListView>
    with TickerProviderStateMixin {
  Timer _changeTimer;
  bool _resetControllerOnce = false;
  FixedExtentScrollController provinceController;
  FixedExtentScrollController cityController;
  FixedExtentScrollController areaController;

  List<CityPoint> provinceCityAreaList;

  CityPoint targetProvince;
  CityPoint targetCity;
  CityPoint targetArea;

  TabController _tabController;

  List<String> _tabLabels = [];

  String _provinceName, _cityName, _areaName;

  @override
  void initState() {
    super.initState();
    provinceCityAreaList = widget.provinceCityAreaList;
    initData();
    if (widget.initDataResult != null) {
      _tabLabels = [_provinceName ?? "请选择", _cityName ?? "请选择"];
    } else {
      _tabLabels = [
        _provinceName ?? "请选择",
      ];
    }
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _initController();
    _tabController.animateTo(_tabLabels.length - 1);
  }

  void initData() {
    try {
      _initLocation(widget.locationCode);
    } catch (e) {
      print('Exception details:\n 初始化地理位置信息失败, 请检查省分城市数据 \n $e');
    }
  }

  void dispose() {
    provinceController.dispose();
    cityController.dispose();
    areaController.dispose();
    if (_changeTimer != null && _changeTimer.isActive) {
      _changeTimer.cancel();
    }
    super.dispose();
  }

  // 初始化controller, 为了使给定的默认值, 在选框的中心位置
  void _initController() {
    provinceController = FixedExtentScrollController(
        initialItem: provinceCityAreaList
            .indexWhere((CityPoint p) => p.value == targetProvince.value));

    cityController = FixedExtentScrollController(
        initialItem: targetProvince.children
            .indexWhere((CityPoint p) => p.value == targetCity.value));

    areaController = FixedExtentScrollController(
        initialItem: targetCity.children
            .indexWhere((CityPoint p) => p.value == targetArea.value));
  }

  // 重置Controller的原因在于, 无法手动去更改initialItem, 也无法通过
  // jumpTo or animateTo去更改, 强行更改, 会触发 _onProvinceChange  _onCityChange 与 _onAreacChange
  // 只为覆盖初始化化的参数initialItem
  void _resetController() {
    if (_resetControllerOnce) return;
    provinceController = FixedExtentScrollController(initialItem: 0);

    cityController = FixedExtentScrollController(initialItem: 0);
    areaController = FixedExtentScrollController(initialItem: 0);
    _resetControllerOnce = true;
  }

  ///初始化数据的以及回显数据
  void _initLocation(String locationCode) {
    Result dataResult = widget.initDataResult;

    if (dataResult != null && dataResult.provinceName != null) {
      {
        CityPoint point = provinceCityAreaList.firstWhere(
            (province) => dataResult.provinceName == province.label,
            orElse: () => null);

        if (point != null) {
          targetProvince = point;
          targetProvince.select = true;
          _provinceName = targetProvince.label;
        } else {
          targetProvince = provinceCityAreaList[0];
        }
      }

      {
        CityPoint point = targetProvince.children.firstWhere(
            (city) => dataResult.cityName == city.label,
            orElse: () => null);

        if (point != null) {
          targetCity = point;
          targetCity.select = true;
          _cityName = targetCity.label;
        } else {
          targetCity = targetProvince.children[0];
        }
      }
      {
        CityPoint point = targetCity.children.firstWhere(
            (area) => dataResult.areaName == area.label,
            orElse: () => null);

        if (point != null) {
          targetArea = point;
          targetArea.select = true;
          _areaName = targetArea.label;
        } else {
          targetArea = targetCity.children[0];
        }
      }
    } else {
      targetProvince = provinceCityAreaList[0];
      targetCity = targetProvince.children[0];
      targetArea = targetCity.children[0];
    }
  }

  /// 通过选中的省份, 构建以省份为根节点的树型结构
  List<LabelSelectBean> getCityItemList() {
    List<LabelSelectBean> result = [];
    if (targetProvince != null) {
      result.addAll(targetProvince.children
          .map((p) => LabelSelectBean(
              label: p.label, select: p.select == null ? false : p.select))
          .toList());
    }
    return result;
  }

  ///构建区级数据
  List<LabelSelectBean> getAreaItemList() {
    List<LabelSelectBean> result = [];
    if (targetCity != null) {
      result.addAll(targetCity.children
          .map((p) => LabelSelectBean(
              label: p.label, select: p.select == null ? false : p.select))
          .toList());
    }
    return result;
  }

  /// 加入延时处理, 减少构建树的消耗
  _onProvinceChange(int index) {
    if (_changeTimer != null && _changeTimer.isActive) {
      _changeTimer.cancel();
    }
    ShowType showType = widget.showType;
    targetProvince = provinceCityAreaList[index];
    for (int i = 0; i < provinceCityAreaList.length; i++) {
      if (index == i) {
        provinceCityAreaList[i].select = true;
      } else {
        provinceCityAreaList[i].select = false;
      }
    }
    targetCity = targetProvince.children[0];
    targetProvince.children.forEach((element) {
      element.select = false;
    });
    if (showType == ShowType.a ||
        showType == ShowType.p ||
        showType == ShowType.c) {
      //只有一列数据，直接返回
      Navigator.pop(context, _buildResult());
    } else {
      _changeTimer = Timer(Duration(milliseconds: 200), () {
        setState(() {
          _tabLabels = [targetProvince.label, "请选择"];
          _provinceName = targetProvince.label;
          _tabController =
              TabController(length: _tabLabels.length, vsync: this);
        });
      });
    }
  }

  ///城市选择变化回调
  _onCityChange(int index) {
    if (_changeTimer != null && _changeTimer.isActive) {
      _changeTimer.cancel();
    }
    ShowType showType = widget.showType;
    targetCity = targetProvince.children[index];
    for (int i = 0; i < targetProvince.children.length; i++) {
      if (index == i) {
        targetProvince.children[i].select = true;
      } else {
        targetProvince.children[i].select = false;
      }
    }
    if (showType == ShowType.ca || showType == ShowType.pc) {
      //只有一列数据，直接返回
      Navigator.pop(context, _buildResult());
    } else {
      _changeTimer = Timer(Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() {
          _cityName = targetCity.label;
          targetArea = targetCity.children[0];
          _tabLabels = [targetProvince.label, targetCity.label, "请选择"];
          _tabController =
              TabController(length: _tabLabels.length, vsync: this);
        });
      });
      _tabController.animateTo(2);
    }
  }

  ///区级选中的回调
  _onAreaChange(int index) {
    if (_changeTimer != null && _changeTimer.isActive) {
      _changeTimer.cancel();
    }
    ShowType showType = widget.showType;
    if (showType == ShowType.pca) {
      //只有一列数据，直接返回
      Navigator.pop(context, _buildResult());
    } else {
      _changeTimer = Timer(Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() {
          targetArea = targetCity.children[index];
        });
      });
    }
  }

  ///构建返回数据
  Result _buildResult() {
    Result result = Result();
    ShowType showType = widget.showType;
    if (showType.contain(ShowType.p)) {
      result.provinceId = targetProvince.value.toString();
      result.provinceName = targetProvince.label;
    }
    if (showType.contain(ShowType.c)) {
      result.provinceId = targetProvince.value.toString();
      result.provinceName = targetProvince.label;
      result.cityId = targetCity != null ? targetCity.value.toString() : null;
      result.cityName = targetCity != null ? targetCity.label : null;
    }
    if (showType.contain(ShowType.a)) {
      result.provinceId = targetProvince.value.toString();
      result.provinceName = targetProvince.label;
      result.cityId = targetCity != null ? targetCity.value.toString() : null;
      result.cityName = targetCity != null ? targetCity.label : null;
      result.areaId = targetArea != null ? targetArea.value.toString() : null;
      result.areaName = targetArea != null ? targetArea.label : null;
    }
    return result;
  }

  ///构建底部弹出框
  Widget _bottomBuild() {
    if (provinceCityAreaList == null) {
      return Container();
    }
    return Scaffold(
      appBar: PreferredSize(
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _buildHeaderTitle(),
                _buildHeaderTabBar(),
                Container(
                  height: 0.5,
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  color: Color(0xFFEBEBEB),
                )
              ],
            ),
          ),
          preferredSize: Size.fromHeight(84)),
      body: TabBarView(
        controller: _tabController,
        children: _buildTabBarView(),
      ),
    );
  }

  ///构建HeaderTabBar
  Widget _buildHeaderTabBar() {
    return Row(
      children: <Widget>[
        Container(
          alignment: Alignment.topLeft,
          height: 30,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelStyle: TextStyle(color: Colors.black, fontSize: 16),
            labelColor: Colors.black,
            unselectedLabelColor: Color(0xFF999999),
            unselectedLabelStyle:
                TextStyle(color: Color(0xFF999999), fontSize: 16),
            indicatorColor: Color(0xFFD71718),
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 2.5,
            tabs: _tabLabels.map((f) {
              return Tab(
                text: f,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  ///构建标题
  Widget _buildHeaderTitle() {
    return Stack(
      alignment: AlignmentDirectional.topEnd,
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 15, bottom: 15),
          child: Text(
            '请选择代理机构',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
          width: double.infinity,
        ),
        Material(
          color: Colors.white,
          child: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                padding:
                    EdgeInsets.only(top: 8, right: 10, left: 10, bottom: 5),
                child: Icon(
                  Icons.clear,
                  size: 25,
                  color: Color(0xFFCCCCCC),
                ),
              )),
        ),
      ],
    );
  }

  ///构建Header tabBar
  List<Widget> _buildTabBarView() {
    List<Widget> tabList = [];
    tabList.add(_MyCityPicker(
      key: Key('province'),
      isShow: widget.showType.contain(ShowType.p),
      height: widget.height,
      controller: provinceController,
      value: targetProvince.label,
      itemList: provinceCityAreaList.map((v) {
        return LabelSelectBean(
            label: v.label, select: v.select == null ? false : v.select);
      }).toList(),
      changed: (index) {
        _onProvinceChange(index);
        Future.delayed(Duration(milliseconds: 200))
            .then((value) => _tabController.animateTo(1));
      },
    ));
    if (_provinceName != null) {
      tabList.add(_MyCityPicker(
        key: Key('citys $targetProvince'),
        // 这个属性是为了强制刷新
        isShow: widget.showType.contain(ShowType.c),
        controller: cityController,
        height: widget.height,
        value: targetCity == null ? null : targetCity.label,
        itemList: getCityItemList(),
        changed: (index) {
          _onCityChange(index);
        },
      ));
    }

    if (_cityName != null && widget.showType == ShowType.pca) {
      tabList.add(_MyCityPicker(
        key: Key('towns $targetCity'),
        isShow: widget.showType.contain(ShowType.a),
        controller: areaController,
        value: targetArea == null ? null : targetArea.label,
        height: widget.height,
        itemList: getAreaItemList(),
        changed: (index) {
          _areaName = targetCity.children[index].label;
          _onAreaChange(index);
        },
      ));
    }
    return tabList;
  }

  Widget build(BuildContext context) {
    final route = InheritRouteWidget.of(context).router;
    return AnimatedBuilder(
      animation: route.animation,
      builder: (BuildContext context, Widget child) {
        return CustomSingleChildLayout(
          delegate: _WrapLayout(
              progress: route.animation.value, height: widget.height),
          child: GestureDetector(
            child: Material(
              color: Colors.transparent,
              child: Container(width: double.infinity, child: _bottomBuild()),
            ),
          ),
        );
      },
    );
  }
}

class _MyCityPicker extends StatefulWidget {
  final List<LabelSelectBean> itemList;
  final Key key;
  final String value;
  final bool isShow;
  final FixedExtentScrollController controller;
  final ValueChanged<int> changed;
  final double height;

  _MyCityPicker(
      {this.key,
      this.controller,
      this.isShow = false,
      this.changed,
      this.height,
      this.itemList,
      this.value});

  @override
  State createState() {
    return _MyCityPickerState();
  }
}

class _MyCityPickerState extends State<_MyCityPicker> {
  List<Widget> children;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isShow) {
      return Container();
    }
    if (widget.itemList == null || widget.itemList.isEmpty) {
      return Container();
    }
    return Container(
      color: Colors.white,
      child: ListView.builder(
          itemBuilder: (context, index) {
            return Material(
                color: Colors.white,
                child: InkWell(
                  child: Container(
                      padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                      child: Row(
                        children: <Widget>[
                          Text(
                            '${widget.itemList[index].label}  ',
                            maxLines: 1,
                            style: TextStyle(color: Colors.black, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          widget.itemList[index].select
                              ? Icon(
                                  Icons.check,
                                  size: 20,
                                  color: Color(0xFFD71718),
                                )
                              : Container()
                        ],
                      )),
                  onTap: () {
                    widget.changed(index);
                  },
                ));
          },
          itemCount: widget.itemList.length),
    );
  }
}

class _WrapLayout extends SingleChildLayoutDelegate {
  _WrapLayout({
    this.progress,
    this.height,
  });

  final double progress;
  final double height;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    double maxHeight = height;

    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      maxHeight: maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double height = size.height - childSize.height * progress;
    return Offset(0.0, height);
  }

  @override
  bool shouldRelayout(_WrapLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
