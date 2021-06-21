class Stop {
  final String stopLetter;
  final String commonName;
  final String naptanId;
  final double distance;
  final double lat;
  final double lon;
  final List lines;

  Stop(this.stopLetter, this.commonName, this.naptanId, this.distance, this.lat, this.lon, this.lines);
}

class ArrivalTime {
  final String vehicleId;
  final String lineName;
  final String destinationName;
  final int timeToStation;

  ArrivalTime(this.vehicleId, this.lineName, this.timeToStation, this.destinationName);
}
