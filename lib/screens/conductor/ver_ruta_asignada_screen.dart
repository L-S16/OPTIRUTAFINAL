import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:signature/signature.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

class VerRutaAsignadaScreen extends StatefulWidget {
  final String routeId;
  final Map<String, dynamic> routeData;

  const VerRutaAsignadaScreen({
    super.key,
    required this.routeId,
    required this.routeData,
  });

  @override
  State<VerRutaAsignadaScreen> createState() => _VerRutaAsignadaScreenState();
}

class _VerRutaAsignadaScreenState extends State<VerRutaAsignadaScreen> {
  late String _estadoEntrega;
  late TextEditingController _observacionesController;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();
  String? _fotoBase64;

  @override
  void initState() {
    super.initState();
    _estadoEntrega = widget.routeData['estado'] ?? 'Pendiente';
    _observacionesController =
        TextEditingController(text: widget.routeData['observaciones'] ?? '');
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Color _getColorForState(String state) {
    switch (state) {
      case 'Entregado':
        return Colors.green;
      case 'No entregado':
        return Colors.red;
      case 'Reprogramado':
        return Colors.orange;
      case 'Pendiente':
      default:
        return Colors.orange.shade400;
    }
  }

  Future<void> _abrirGoogleMaps() async {
    // Coordenadas simuladas para Latacunga (podrían venir de widget.routeData)
    const double lat = -0.932222;
    const double lng = -78.615833;
    final Uri url = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    
    if (!await launchUrl(url)) {
      // Intento web si falla la app nativa
      final Uri webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
      if (!await launchUrl(webUrl)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir Google Maps')),
          );
        }
      }
    }
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50, // Reducir calidad para no saturar Base64
        maxWidth: 800,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _fotoBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al tomar foto: $e')),
        );
      }
    }
  }

  Future<void> _guardarCambios() async {
    setState(() => _isSaving = true);
    try {
      String? firmaBase64 = widget.routeData['firmaBase64'];

      // Si el estado es "Entregado", intentamos guardar la firma si se dibujó
      if (_estadoEntrega == 'Entregado' && _signatureController.isNotEmpty) {
        final Uint8List? data = await _signatureController.toPngBytes();
        if (data != null) {
          firmaBase64 = base64Encode(data);
        }
      }

      await FirebaseFirestore.instance
          .collection('entregas')
          .doc(widget.routeId)
          .update({
        'estado': _estadoEntrega,
        'observaciones': _observacionesController.text,
        if (firmaBase64 != null) 'firmaBase64': firmaBase64,
        if (_fotoBase64 != null) 'fotoBase64': _fotoBase64,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados correctamente')),
        );
        if (_estadoEntrega == 'Entregado') {
          Navigator.pop(context); // Vuelve al dashboard
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final numRuta = widget.routeData['numeroRuta'] ?? 'Desconocida';
    final destino = widget.routeData['destino'] ?? 'Desconocido';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Ruta'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Guardar',
              onPressed: _guardarCambios,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ruta #$numRuta', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                    Chip(
                      label: Text(_estadoEntrega, style: const TextStyle(color: Colors.white)),
                      backgroundColor: _getColorForState(_estadoEntrega),
                    ),
                  ],
                ),
                const Divider(height: 32, thickness: 1),
                const ListTile(
                  leading: Icon(Icons.location_on, color: Colors.blue),
                  title: Text('Origen'),
                  subtitle: Text('Ubicación Actual', style: TextStyle(fontSize: 16)),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.red),
                  title: const Text('Destino'),
                  subtitle: Text(destino, style: const TextStyle(fontSize: 16)),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                
                const Text('Estado de Entrega', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _estadoEntrega,
                      icon: const Icon(Icons.arrow_drop_down),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _estadoEntrega = newValue);
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                        DropdownMenuItem(value: 'Entregado', child: Text('Entregado', style: TextStyle(color: Colors.green))),
                        DropdownMenuItem(value: 'No entregado', child: Text('No entregado', style: TextStyle(color: Colors.red))),
                        DropdownMenuItem(value: 'Reprogramado', child: Text('Reprogramado', style: TextStyle(color: Colors.orange))),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text('Observaciones', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _observacionesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Escriba cualquier detalle relevante...',
                    border: OutlineInputBorder(),
                  ),
                ),

                if (_estadoEntrega == 'Entregado') ...[
                  const SizedBox(height: 24),
                  const Text('Evidencia Fotográfica', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_fotoBase64 != null) ...[
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(_fotoBase64!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _tomarFoto,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(_fotoBase64 == null ? 'Tomar Foto' : 'Tomar Otra Foto'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Firma del Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Signature(
                      controller: _signatureController,
                      height: 150,
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _signatureController.clear(),
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Limpiar Firma'),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _abrirGoogleMaps,
                    icon: const Icon(Icons.map),
                    label: const Text('Navegar en Google Maps', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _guardarCambios,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
