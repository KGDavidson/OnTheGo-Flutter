class Stop {
  final String stopLetter;
  final String commonName;
  final String naptanId;
  final double distance;
  final double lat;
  final double lon;
  final List lines;

  Stop({
    this.stopLetter,
    this.commonName,
    this.naptanId,
    this.distance,
    this.lat,
    this.lon,
    this.lines
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      stopLetter: json['indicator'],
      commonName: json['commonName'],
      naptanId: json["naptanId"],
      distance: json['distance'],
      lat: json['lat'],
      lon: json['lon'],
      lines: json['lines'].map((item) => item["name"]).toList(),
    );
  }

  factory Stop.fromPrefs(String naptanId, String stopLetter, String commonName, double distance, double lat, double lon, List<dynamic> lines) {
    return Stop(
      stopLetter: stopLetter,
      commonName: commonName,
      naptanId: naptanId,
      distance: distance,
      lat: lat,
      lon: lon,
      lines: lines,
    );
  }
}

class ArrivalTime {
  final String vehicleId;
  final String lineName;
  final String destinationName;
  final int timeToStation;

  ArrivalTime(
      {this.vehicleId,
        this.lineName,
        this.timeToStation,
        this.destinationName});

  factory ArrivalTime.fromJson(Map<String, dynamic> json) {
    return ArrivalTime(
      vehicleId: json['vehicleId'],
      lineName: json['lineName'],
      destinationName: json["destinationName"],
      timeToStation: json['timeToStation'],
    );
  }
}