class Pedido {
  String id;
  String cliente;
  String direccion;
  String prioridad;
  String estado;
  int numeroCajas;
  String? zona;
  String? telefono;
  String? detalle;

  Pedido({
    required this.id,
    required this.cliente,
    required this.direccion,
    required this.prioridad,
    required this.estado,
    required this.numeroCajas,
    this.zona,
    this.telefono,
    this.detalle,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente': cliente,
      'direccion': direccion,
      'prioridad': prioridad,
      'estado': estado,
      'numeroCajas': numeroCajas,
      'zona': zona,
      'telefono': telefono,
      'detalle': detalle,
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
      zona: map['zona'],
      telefono: map['telefono'],
      detalle: map['detalle'],
    );
  }
}
