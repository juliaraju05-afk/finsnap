class SmsParser {

  // ✅ FIXED — handles Rs, Rs., INR, ₹ with proper number capture
  final RegExp amountRegex = RegExp(
    r'(?:Rs\.?|INR|₹)\s?([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // ✅ FIXED — real Indian bank sender IDs
  final Set<String> knownBanks = {
    'HDFCBK', 'HDFCBN', 'SBIINB', 'SBISMS',
    'ICICIB', 'AXISBK', 'UTIBOP', 'KOTAKB',
    'PAYTMB', 'IDFCBK', 'INDBNK', 'YESBNK',
    'SCBANK', 'PNBSMS', 'BOIIND', 'CANBNK',
  };

  int getConfidenceScore(String sender, String msg) {
    int score = 0;

    // Strip prefix like "AM-", "BW-", "JD-"
    final cleanSender = sender.contains('-')
        ? sender.split('-').last.toUpperCase()
        : sender.toUpperCase();

    if (knownBanks.contains(cleanSender)) score += 40;

    final lower = msg.toLowerCase();

    if (lower.contains("debited") || lower.contains("credited")) score += 20;

    if (msg.contains("A/c") || msg.contains("XXXX") ||
        msg.contains("a/c") || msg.contains("xxxx")) score += 20;

    if (amountRegex.hasMatch(msg)) score += 10;

    if (lower.contains("upi") || lower.contains("txn") ||
        lower.contains("imps") || lower.contains("neft")) score += 10;

    return score;
  }

  // ✅ FIXED — captures only the number, not "Rs"
  double? extractAmount(String msg) {
    final match = amountRegex.firstMatch(msg);
    if (match == null) return null;
    final amt = match.group(1)!.replaceAll(',', '');
    return double.tryParse(amt);
  }

  String getType(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains("debited")) return "expense";
    if (lower.contains("credited")) return "income";
    return "unknown";
  }
}