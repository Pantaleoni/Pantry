import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Necessario per il Timestamp di Firebase

enum ProductStatus { in_dispensa, in_lista_settimanale, in_lista_straordinaria }

class Product {
  final String id;
  final String barcode;
  String nome;
  String categoria;
  DateTime? dataScadenza;
  ProductStatus stato;
  int quantita;
  bool isChecked;
  String userId; // <-- NUOVO: fondamentale per dividere le dispense!

  Product({
    required this.id,
    required this.barcode,
    required this.nome,
    required this.categoria,
    this.dataScadenza,
    this.stato = ProductStatus.in_dispensa,
    this.quantita = 1,
    this.isChecked = false,
    required this.userId, // <-- Obbligatorio ora
  });

  // Da Firestore all'App (Lettura)
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> map = doc.data() as Map<String, dynamic>;

    // Gestione sicura della data da Firestore (Timestamp -> DateTime)
    DateTime? scadenza;
    if (map['dataScadenza'] != null) {
      scadenza = (map['dataScadenza'] as Timestamp).toDate();
    }

    return Product(
      id: doc.id, // L'ID del documento assegnato da Firebase
      barcode: map['barcode'] ?? '',
      nome: map['nome'] ?? '',
      categoria: map['categoria'] ?? 'Dispensa',
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
      // Firestore gestisce meglio le date se usiamo il suo Timestamp
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