class Node {
  final String id;
  final String name;
  final String country;
  final String city;
  final String flag;
  final int pingMs;
  final double speedMbps;
  final String protocol;

  const Node({
    required this.id,
    required this.name,
    required this.country,
    required this.city,
    required this.flag,
    required this.pingMs,
    required this.speedMbps,
    required this.protocol,
  });
}
