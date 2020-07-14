/// @desc: 选择label bean
/// @Date: 2020/7/9 17:15
/// @Author: lizubing
class LabelSelectBean {
  ///是否选中
  bool select = false;

  ///展示label
  String label = "";

  LabelSelectBean({
    this.select = false,
    this.label = "",
  });

  @override
  String toString() {
    return "select：$select----label:$label";
  }
}
