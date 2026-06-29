class Pedido {
  String id;
  String cliente;
  String direccion;
  String prioridad;
  String estado;
  int numeroCajas;

  Pedido({
    required this.id,
    required this.cliente,
    required this.direccion,
    required this.prioridad,
    required this.estado,
    required this.numeroCajas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente': cliente,
      'direccion': direccion,
      'prioridad': prioridad,
      'estado': estado,
      'numeroCajas': numeroCajas,
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> map) {
    return Pedido(
      id: map['id'] ?? '',
      cliente: map['cliente'] ?? '',
      direccion: map['direccion'] ?? '',
      prioridad: map['prioridad'] ?? '',
      estado: map['estado'] ?? '',
      numeroCajas: map['numeroCajas'] ?? 0,
    );
  }
}

