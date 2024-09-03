class Usersensor {
  String name;
  String group;
  String start;
  String smoke_limit;
  String smoke_sensitive;
  String tem_limit;
  String hot_sensitive;
  String video_length;

  Usersensor({
    this.name = "",
    this.group = "",
    this.start = "true",
    this.smoke_limit = "1",
    this.smoke_sensitive = "1",
    this.tem_limit = "1000",
    this.hot_sensitive = "1",
    this.video_length = "1",
  });
  String modifyName(int num, String Name) {
    if (num == 10) {
      name = Name;
      return name;
    } else {
      group = Name;
      return group;
    }
  }

  // String modifyGroup(String Group) {
  //   group = Group;
  //   return group;
  // }

  String modifystart(bool Start) {
    start = Start.toString();
    return start;
  }

  void modiy(String buffer, int num) {
    if (num == 13) {
      smoke_limit = buffer;
    } else if (num == 14) {
      smoke_sensitive = buffer;
    } else if (num == 15) {
      tem_limit = buffer;
    } else if (num == 16) {
      hot_sensitive = buffer;
    } else if (num == 17) {
      video_length = buffer;
    }
  }
}
