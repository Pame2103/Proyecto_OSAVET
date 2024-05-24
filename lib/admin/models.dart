// models.dart

class Mascota {
  final String id;
  final String name;

  Mascota({
    required this.id,
    required this.name,
  });

  factory Mascota.fromJson(Map<String, dynamic> json) {
    return Mascota(
      id: json['id'],
      name: json['name'],
    );
  }
}
class Event {
  final DateTime date;
  final String title;
  final String mascotaId;

  Event({
    required this.date,
    required this.title,
    required this.mascotaId,
  });

  get toDynamic => null;
}


class Cita {
  final String id;
  final DateTime fecha;
  
  final String? descripcion;
  final String mascotaId;

  Cita({
    required this.id,
    required this.fecha,
    required this.descripcion,
    required this.mascotaId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'descripcion': descripcion,
      'mascotaId': mascotaId,
    };
  }

  static Cita fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      descripcion: json['descripcion'],
      mascotaId: json['mascotaId'],
    );
  }
}
