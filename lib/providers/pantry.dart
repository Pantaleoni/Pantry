import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class PantryProvider with ChangeNotifier {
  // Usiamo UNA SOLA collezione principale per tutti i prodotti
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'products';

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // --- STREAMS (I tuoi "tubi" per i dati in tempo reale) ---

  // 1. Stream solo per i prodotti IN DISPENSA
  Stream<List<Product>> get prodottiInDispensa {
    return _db.collection(_collection)
        .where('userId', isEqualTo: _userId)
        .where('stato', isEqualTo: ProductStatus.in_dispensa.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // 2. Stream solo per la LISTA SETTIMANALE
  Stream<List<Product>> get listaSettimanale {
    return _db.collection(_collection)
        .where('userId', isEqualTo: _userId)
        .where('stato', isEqualTo: ProductStatus.in_lista_settimanale.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // 3. Stream solo per la LISTA STRAORDINARIA
  Stream<List<Product>> get listaStraordinaria {
    return _db.collection(_collection)
        .where('userId', isEqualTo: _userId)
        .where('stato', isEqualTo: ProductStatus.in_lista_straordinaria.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // --- AZIONI ---

  // Aggiunge un nuovo prodotto (di base va in dispensa, ma puoi specificare lo stato)
  Future<void> addProduct({
    required String nome,
    String barcode = '',
    String categoria = 'Altro',
    int quantita = 1,
    DateTime? scadenza,
    ProductStatus stato = ProductStatus.in_dispensa,
  }) async {
    if (_userId.isEmpty) return;

    final newProduct = Product(
      id: '', // Lasciamo vuoto, ci pensa Firebase
      barcode: barcode,
      nome: nome,
      categoria: categoria,
      dataScadenza: scadenza,
      stato: stato,
      quantita: quantita,
      userId: _userId,
    );

    await _db.collection(_collection).add(newProduct.toFirestore());
  }

  // Aggiorna un prodotto (es. sposti da lista spesa a dispensa)
  Future<void> updateProductStatus(String id, ProductStatus nuovoStato) async {
    await _db.collection(_collection).doc(id).update({
      'stato': nuovoStato.toString(),
      'isChecked': false, // Resetta il check se lo sposti
    });
  }

  // Cambia la quantità
  Future<void> updateQuantity(String id, int nuovaQuantita) async {
    if (nuovaQuantita <= 0) {
      await deleteProduct(id);
    } else {
      await _db.collection(_collection).doc(id).update({'quantita': nuovaQuantita});
    }
  }

  // Toggle per il check della lista della spesa
  Future<void> toggleCheck(String id, bool currentState) async {
    await _db.collection(_collection).doc(id).update({'isChecked': !currentState});
  }

  // Elimina prodotto
  Future<void> deleteProduct(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }
}