import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';

import '../core/network/api_client.dart';

/// A server-created payment order. The amount is computed by the server and the slots are held
/// for the player until [holdExpiresAt] while they pay.
class CashfreeOrder {
  final String orderId;
  final String paymentSessionId;
  final double amount;
  final bool isTestMode;
  final bool isProduction;
  final String? bookingCode;
  final DateTime? holdExpiresAt;
  final List<Map<String, dynamic>> priceBreakdown;

  const CashfreeOrder({
    required this.orderId,
    required this.paymentSessionId,
    required this.amount,
    required this.isTestMode,
    required this.isProduction,
    this.bookingCode,
    this.holdExpiresAt,
    this.priceBreakdown = const [],
  });

  factory CashfreeOrder.fromJson(Map<String, dynamic> json) => CashfreeOrder(
        orderId: json['orderId'].toString(),
        paymentSessionId: (json['paymentSessionId'] ?? '').toString(),
        amount: (json['orderAmount'] as num?)?.toDouble() ?? 0,
        isTestMode: json['isMock'] == true,
        isProduction: json['environment'] == 'production',
        bookingCode: json['bookingCode']?.toString(),
        holdExpiresAt: DateTime.tryParse(json['holdExpiresAt']?.toString() ?? '')?.toLocal(),
        priceBreakdown: (json['priceBreakdown'] is List)
            ? (json['priceBreakdown'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : const [],
      );
}

class CashfreePaymentResult {
  final bool success;
  final String status;
  final String orderId;
  final String? cfPaymentId;
  final Map<String, dynamic>? booking;
  final String message;

  const CashfreePaymentResult({
    required this.success,
    required this.status,
    required this.orderId,
    this.cfPaymentId,
    this.booking,
    required this.message,
  });

  /// Payment went through but the server is still processing it.
  bool get isPending => status == 'PENDING' || status == 'PROCESSING';
}

/// Player payments through Cashfree:
///   createOrder -> openCheckout (Cashfree SDK) -> verifyPayment, or cancelOrder if abandoned.
/// A booking only exists once the server has verified the payment with Cashfree.
class CashfreeService {
  CashfreeService._();

  static Future<({CashfreeOrder? order, String? error})> createOrder({
    required int turfId,
    required String date,
    required List<String> timeSlots,
    required String sport,
    required String courtName,
    required String customerName,
    required String customerPhone,
    bool isOpenMatch = false,
    String? teamName,
    String? teamSize,
  }) async {
    final res = await ApiClient.post('/cashfree/create-order', body: {
      'turfId': turfId,
      'date': date,
      'timeSlots': timeSlots,
      'sport': sport,
      'courtName': courtName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'isOpenMatch': isOpenMatch,
      'teamName': teamName,
      'teamSize': teamSize,
    });
    if (!res.ok || res.map['orderId'] == null) {
      return (order: null, error: res.message);
    }
    return (order: CashfreeOrder.fromJson(res.map), error: null);
  }

  static Future<CashfreePaymentResult> verifyPayment(String orderId) async {
    final res = await ApiClient.post('/cashfree/verify-payment', body: {'orderId': orderId});
    final data = res.map;
    return CashfreePaymentResult(
      success: res.ok && data['success'] == true,
      status: (data['status'] ?? (res.ok ? 'UNKNOWN' : 'ERROR')).toString(),
      orderId: orderId,
      cfPaymentId: data['cfPaymentId']?.toString(),
      booking: data['booking'] is Map ? Map<String, dynamic>.from(data['booking'] as Map) : null,
      message: res.message,
    );
  }

  /// Releases the held slots when the player abandons payment. If Cashfree reports the order as
  /// paid after all, the server confirms the booking instead.
  static Future<CashfreePaymentResult?> cancelOrder(String orderId) async {
    final res = await ApiClient.post('/cashfree/cancel-order', body: {'orderId': orderId});
    if (res.map['status'] == 'PAID') {
      return CashfreePaymentResult(
        success: true,
        status: 'PAID',
        orderId: orderId,
        booking: res.map['booking'] is Map ? Map<String, dynamic>.from(res.map['booking'] as Map) : null,
        message: res.message,
      );
    }
    return null;
  }

  /// Opens the Cashfree hosted checkout. Completes with null when Cashfree reports the payment
  /// flow finished (the result must still be verified on the server), or an error message when
  /// the player cancelled or the payment failed.
  static Future<String?> openCheckout(CashfreeOrder order) async {
    final completer = Completer<String?>();
    try {
      final session = CFSessionBuilder()
          .setEnvironment(order.isProduction ? CFEnvironment.PRODUCTION : CFEnvironment.SANDBOX)
          .setOrderId(order.orderId)
          .setPaymentSessionId(order.paymentSessionId)
          .build();
      final payment = CFWebCheckoutPaymentBuilder().setSession(session).build();

      final gateway = CFPaymentGatewayService();
      gateway.setCallback(
        (String orderId) {
          if (!completer.isCompleted) completer.complete(null);
        },
        (CFErrorResponse error, String orderId) {
          if (!completer.isCompleted) {
            completer.complete(error.getMessage() ?? 'Payment was not completed.');
          }
        },
      );
      gateway.doPayment(payment);
    } catch (e) {
      debugPrint('Cashfree checkout error: $e');
      if (!completer.isCompleted) completer.complete('Could not open the payment page. Please try again.');
    }
    return completer.future;
  }
}
