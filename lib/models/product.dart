import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductStatus { in_dispensa, in_lista_settimanale, in_lista_straordinaria }

class Product {
  final String id;
  final String barcode;
  final String categoria; // Es: 'Frigo', 'Freezer', 'Dispensa', 'Altro'
  String nome;
  DateTime? dataScadenza;
  ProductStatus stato;
  int quantita;
  bool isChecked;
  String userId;

  Product({
    required this.id,
    required this.barcode,
    required this.nome,
    required this.categoria,
    required this.userId,
    this.dataScadenza,
    this.stato = ProductStatus.in_dispensa,
    this.quantita = 1,
    this.isChecked = false,
  });

  // Da Firestore all'App (Lettura)
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> map = doc.data() as Map<String, dynamic>;

    // --- NUOVO SISTEMA AUTOMATICO SALVA-CRASH PER LA DATA ---
    DateTime? scadenza;
    var dataDalDb = map['dataScadenza'];

    if (dataDalDb != null) {
      if (dataDalDb is String) {
        // Se trova il vecchio errore (testo), lo converte da solo in automatico!
        scadenza = DateTime.tryParse(dataDalDb);
      } else if (dataDalDb is Timestamp) {
        // Se è il formato corretto di Firebase, usa il suo metodo nativo
        scadenza = dataDalDb.toDate();
      } else {
        // Ultimo tentativo di salvataggio per casistiche strane
        try {
          scadenza = (dataDalDb as Timestamp).toDate();
        } catch (e) {
          scadenza = null; // Non crasha, al massimo mette "Senza scadenza"
        }
      }
    }

    return Product(
      id: doc.id, // L'ID del documento assegnato da Firebase
      barcode: map['barcode'] ?? '',
      nome: map['nome'] ?? '',
      categoria: map['categoria'] ?? 'Altro', // 'Altro' come default più sicuro
      dataScadenza: scadenza,
      stato: ProductStatus.values.firstWhere(
              (e) => e.toString() == map['stato'],
          orElse: () => ProductStatus.in_dispensa
      ),
      quantita: map['quantita'] ?? 1,
      isChecked: map['isChecked'] ?? false,
      userId: map['userId'] ?? '', // <-- Leggiamo il proprietario
    );
  }

  // Dall'App a Firestore (Scrittura)
  Map<String, dynamic> toFirestore() {
    return {
      'barcode': barcode,
      'nome': nome,
      'categoria': categoria,
      'dataScadenza': dataScadenza != null ? Timestamp.fromDate(dataScadenza!) : null,
      'stato': stato.toString(),
      'quantita': quantita,
      'isChecked': isChecked,
      'userId': userId, // <-- Salviamo il proprietario
    };
  }

  Color get colorCode {
    if (dataScadenza == null) return Colors.grey;

    final now = DateTime.now();
    // Normalizziamo le date a mezzanotte per evitare errori di calcolo dovuti alle ore
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(dataScadenza!.year, dataScadenza!.month, dataScadenza!.day);
    final difference = expiry.difference(today).inDays;

    if (difference <= 1) return Colors.red;
    if (difference <= 3) return Colors.orange;
    return Colors.green;
  }
}