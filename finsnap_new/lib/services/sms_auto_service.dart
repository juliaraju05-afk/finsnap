import 'package:telephony/telephony.dart';
import '../utils/sms_parser.dart';

class SmsAutoService {
  final Telephony telephony = Telephony.instance;
  final SmsParser parser = SmsParser();

  final Set<String> processedMessages = {};

  void start(Function(Map<String, dynamic>) onHighConfidence,
      Function(Map<String, dynamic>) onMediumConfidence) {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        print("SMS RECEIVED: ${message.body}");
        print("SENDER: ${message.address}");
        final body = message.body ?? "";
        final sender = message.address ?? "";

        if (processedMessages.contains(body)) return;
        processedMessages.add(body);

        final score = parser.getConfidenceScore(sender, body);

        final amount = parser.extractAmount(body);
        final type = parser.getType(body);

        if (amount == null || type == "unknown") return;

        final data = {
          "amount": amount,
          "type": type,
          "message": body,
          "category": "Auto",
        };

        if (score >= 80) {
          onHighConfidence(data);
        } else if (score >= 50) {
          onMediumConfidence(data);
        }
      },
      listenInBackground: false,
    );
  }
}