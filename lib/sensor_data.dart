class SensorData {
  String airQuality = '';
  String temperature = '';
  String id = '';
  String normals = ''; //設備是否正常
  String locations = '';
  String updatetime = '';
  String events = ''; //事件種類
  String levels = ''; //事件等級
  String isAlert = ''; //是否有警報
  SensorData(this.airQuality, this.temperature, this.id, this.normals,
      this.locations, this.events, this.isAlert, this.levels, this.updatetime);
  void modify(SensorData buffer) {
    airQuality = buffer.airQuality;
    temperature = buffer.temperature;
    normals = buffer.normals;
    locations = buffer.locations;
    updatetime = buffer.updatetime;
    events = buffer.events;
    levels = buffer.levels;
    isAlert = buffer.levels;
  }
}

class SensorData_list {
  List<SensorData> sensordata = [];

  void add(SensorData buffer) {
    int count = 0;
    for (var i in sensordata) {
      if (i.id == buffer.id) {
        i.modify(buffer);
        count = 1;
        break;
      }
    }
    if (count == 0) {
      sensordata.add(buffer);
    }
  }

  List<SensorData> getSensorData() {
    return sensordata;
  }
}
