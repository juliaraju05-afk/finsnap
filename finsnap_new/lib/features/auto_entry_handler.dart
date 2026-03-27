import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/sms_parser.dart';

class AutoEntryHandler {
  static const platform = MethodChannel('com.finsnap/sms');
  final SmsParser parser = SmsParser();

  Function(Map<String, dynamic>)? onAutoAdd;
  Function(Map<String, dynamic>)? onAskUser;

  Future<void> init({
    required Function(Map<String, dynamic>) onAutoAdd,
    required Function(Map<String, dynamic>) onAskUser,
  }) async {
    this.onAutoAdd = onAutoAdd;
    this.onAskUser = onAskUser;

    // ✅ REQUEST SMS PERMISSION
    final status = await Permission.sms.request();
    print("📱 SMS Permission status: $status");

    if (!status.isGranted) {
      print("❌ SMS Permission denied");
      return;
    }

    print("✅ SMS Permission granted — listening...");

    platform.setMethodCallHandler((call) async {
      if (call.method == "onSmsReceived") {
        final sender = call.arguments["sender"] ?? "";
        final body = call.arguments["body"] ?? "";

        print("📩 SMS FROM: $sender");
        print("📩 BODY: $body");

        final score = parser.getConfidenceScore(sender, body);
        final amount = parser.extractAmount(body);
        final type = parser.getType(body);

        print("📊 SCORE: $score | AMOUNT: $amount | TYPE: $type");

        if (amount == null || amount <= 0 || type == "unknown") {
          print("⛔ Skipped");
          return;
        }

        final data = {
          "amount": amount,
          "type": type,
          "category": "Auto",
          "message": body,
        };

        if (score >= 60) {
          print("✅ Auto adding");
          onAutoAdd?.call(data);
        } else if (score >= 40) {
          print("🤔 Asking user");
          onAskUser?.call(data);
        } else {
          print("⛔ Low confidence ($score)");
        }
      }
    });
  }
}