import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart' as inbox;
import 'package:permission_handler/permission_handler.dart';

import 'models/sms_message.dart';
import 'services/threat_analyzer.dart';

class SmsService {
  final inbox.SmsQuery _query = inbox.SmsQuery();

  /// Function to request permission and fetch the latest text messages from device Messages app
  Future<List<SmsMessage>> fetchInboxMessages({int count = 20}) async {
    if (kIsWeb) return [];

    try {
      // 1. Check if the user has given permission to read SMS
      var status = await Permission.sms.status;

      // 2. If not granted, ask for permission on the phone screen
      if (!status.isGranted) {
        status = await Permission.sms.request();
      }

      // 3. If permission is allowed, grab the texts
      if (status.isGranted) {
        List<inbox.SmsMessage> rawMessages = await _query.querySms(
          kinds: [inbox.SmsQueryKind.inbox], // Only grab received texts
          count: count,
        );

        return rawMessages.map(_convertToAppModel).toList();
      } else {
        debugPrint("SMS Permission Denied by User.");
        return [];
      }
    } catch (e) {
      debugPrint("Error reading SMS database: $e");
      return [];
    }
  }

  SmsMessage _convertToAppModel(inbox.SmsMessage msg) {
    final sender = msg.address ?? 'Unknown';
    final body = msg.body ?? '';
    final receivedAt = msg.date ?? DateTime.now();
    final id = msg.id ?? body.hashCode;

    final result = ThreatAnalyzer.analyze(body);

    ThreatCategory category = ThreatCategory.safe;
    if (result.score >= 25) {
      final bodyLower = body.toLowerCase();
      if (bodyLower.contains('bank') ||
          bodyLower.contains('account') ||
          bodyLower.contains('credit card')) {
        category = ThreatCategory.banking;
      } else if (bodyLower.contains('delivery') ||
          bodyLower.contains('parcel') ||
          bodyLower.contains('courier') ||
          bodyLower.contains('track')) {
        category = ThreatCategory.delivery;
      } else if (bodyLower.contains('otp') ||
          bodyLower.contains('code') ||
          bodyLower.contains('password') ||
          bodyLower.contains('pin')) {
        category = ThreatCategory.otp;
      } else if (bodyLower.contains('crypto') ||
          bodyLower.contains('wallet') ||
          bodyLower.contains('seed')) {
        category = ThreatCategory.crypto;
      } else if (bodyLower.contains('tax') ||
          bodyLower.contains('gov') ||
          bodyLower.contains('notice')) {
        category = ThreatCategory.government;
      } else {
        category = ThreatCategory.impersonation;
      }
    }

    final linkMatch = RegExp(
      r'(https?:\/\/|www\.)\S+|\b(?:[a-z0-9-]+\.)+(com|net|org|io|ly|co)\b(\/\S*)?',
      caseSensitive: false,
    ).firstMatch(body);
    final url = linkMatch?.group(0);

    return SmsMessage(
      id: id,
      sender: sender,
      body: body,
      receivedAt: receivedAt,
      risk: result.score,
      category: category,
      confidence: result.score > 0 ? (85 + (result.score ~/ 10)).clamp(0, 100) : 99,
      url: url,
    );
  }
}

