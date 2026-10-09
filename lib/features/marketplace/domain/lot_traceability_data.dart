import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

@immutable
class LotTraceabilityData {
  final String listingId;
  final String lotNumber;
  final String cropItem;
  final String category;
  final String farmerOrigin;
  final String clusterVillage;
  final String harvestTime;
  final DateTime? harvestAt;
  final String farmingMethod;
  final String organicCertification;
  final String qualityNotes;
  final int pricePaise;
  final String unit;
  final double ratingAvg;
  final List<String> images;

  const LotTraceabilityData({
    required this.listingId,
    required this.lotNumber,
    required this.cropItem,
    this.category = 'vegetable',
    required this.farmerOrigin,
    this.clusterVillage = 'Mandya Cluster',
    required this.harvestTime,
    this.harvestAt,
    this.farmingMethod = 'Zero-Pesticide Organic',
    this.organicCertification = 'Pesticide-Free ✓',
    this.qualityNotes = 'Naturally ripened, sorted A-grade quality.',
    this.pricePaise = 3400,
    this.unit = 'kg',
    this.ratingAvg = 4.9,
    this.images = const [],
  });

  factory LotTraceabilityData.fromJson(Map<String, dynamic> json) {
    final imgsRaw = json['images'];
    List<String> imgList = [];
    if (imgsRaw is List) {
      imgList = imgsRaw.map((e) => e.toString()).toList();
    }

    return LotTraceabilityData(
      listingId: json['listing_id']?.toString() ?? '',
      lotNumber: json['lot_number']?.toString() ?? json['lot_id']?.toString() ?? 'LOT-001',
      cropItem: json['crop_item']?.toString() ?? json['name']?.toString() ?? 'Farm Crop',
      category: json['category']?.toString() ?? 'vegetable',
      farmerOrigin: json['farmer_origin']?.toString() ?? 'Cauvery Bio Farm • Mandya Cluster',
      clusterVillage: json['cluster_village']?.toString() ?? 'Mandya Cluster',
      harvestTime: json['harvest_time']?.toString() ?? 'Yesterday, 5:30 AM',
      harvestAt: DateTime.tryParse(json['harvest_at']?.toString() ?? ''),
      farmingMethod: json['farming_method']?.toString() ?? 'Zero-Pesticide Organic',
      organicCertification: json['organic_certification']?.toString() ?? 'Pesticide-Free ✓',
      qualityNotes: json['quality_notes']?.toString() ?? 'Sorted A-grade quality.',
      pricePaise: (json['price_paise'] as num?)?.toInt() ?? 3400,
      unit: json['unit']?.toString() ?? 'kg',
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 4.9,
      images: imgList,
    );
  }

  Map<String, dynamic> toJson() => {
    'listing_id': listingId,
    'lot_number': lotNumber,
    'crop_item': cropItem,
    'category': category,
    'farmer_origin': farmerOrigin,
    'cluster_village': clusterVillage,
    'harvest_time': harvestTime,
    'harvest_at': harvestAt?.toIso8601String(),
    'farming_method': farmingMethod,
    'organic_certification': organicCertification,
    'quality_notes': qualityNotes,
    'price_paise': pricePaise,
    'unit': unit,
    'rating_avg': ratingAvg,
    'images': images,
  };

  /// Generate a client-verifiable HMAC-SHA256 signed QR token for this lot
  /// Uses base64Url encoding matching P3.7 standards
  static String createSignedLotToken({
    required String lotNumber,
    required String listingId,
    String signingSecret = 'udyoga_setu_secure_lot_signing_secret_2026',
    int expiryDays = 30,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final exp = now + (expiryDays * 86400);

    final payload = {
      'jti': 'lot-token-${lotNumber.toLowerCase()}',
      'tid': 'lot-token-${lotNumber.toLowerCase()}',
      'pur': 'produce_lot',
      'lot_id': lotNumber,
      'listing_id': listingId,
      'iat': now,
      'exp': exp,
    };

    final payloadJson = jsonEncode(payload);
    final encodedPayload = base64Url.encode(utf8.encode(payloadJson)).replaceAll('=', '');

    final hmac = Hmac(sha256, utf8.encode(signingSecret));
    final digest = hmac.convert(utf8.encode(encodedPayload));
    final encodedSig = base64Url.encode(digest.bytes).replaceAll('=', '');

    return '$encodedPayload.$encodedSig';
  }

  /// Verifies HMAC signature and parses a signed lot token
  static Map<String, dynamic>? parseSignedLotToken(
    String token, {
    String signingSecret = 'udyoga_setu_secure_lot_signing_secret_2026',
  }) {
    try {
      final parts = token.split('.');
      if (parts.length != 2) return null;
      final encodedPayload = parts[0];
      final encodedSig = parts[1];

      final hmac = Hmac(sha256, utf8.encode(signingSecret));
      final digest = hmac.convert(utf8.encode(encodedPayload));
      final expectedSig = base64Url.encode(digest.bytes).replaceAll('=', '');

      if (encodedSig != expectedSig) return null;

      var normalized = encodedPayload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decodedStr = utf8.decode(base64.decode(normalized));
      return jsonDecode(decodedStr) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Parses a token payload without enforcing signature check
  static Map<String, dynamic>? parseTokenPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.isEmpty) return null;
      var normalized = parts.first.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decodedStr = utf8.decode(base64.decode(normalized));
      return jsonDecode(decodedStr) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
