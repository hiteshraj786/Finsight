import '../../data/models/parsed_transaction.dart';
import '../../data/models/raw_sms_message.dart';
import '../../data/repositories/transaction_repository.dart';
import 'sms_pipeline.dart';

/// Turns one incoming SMS into a stored transaction. Used both while the app
/// is open and by the background handler.
class IncomingSmsImporter {
  final TransactionRepository repository;
  final SmsPipeline _pipeline;

  IncomingSmsImporter(this.repository, {SmsPipeline? pipeline})
    : _pipeline = pipeline ?? SmsPipeline();

  /// Returns the newly stored transaction, or null when the SMS is not a
  /// completed transaction or was already imported.
  Future<ParsedTransaction?> import(RawSmsMessage sms) async {
    final filtered = _pipeline.filter.evaluate(sms.body, sender: sms.sender);
    if (!filtered.isAccepted) return null;
    final tx = _pipeline.parser.parse(
      sms,
      matchedPhrase: filtered.matchedPhrase,
      isLowConfidence: filtered.isLowConfidence,
    );
    if (tx == null) return null;

    final key = TransactionRepository.computeDedupeKey(tx);
    if (await repository.findByDedupeKey(key) != null) return null;
    await repository.insertNewFromScan([tx]);
    return repository.findByDedupeKey(key);
  }
}
