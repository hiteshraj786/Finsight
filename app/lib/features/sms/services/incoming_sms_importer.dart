import '../data/transaction_repository.dart';
import '../models/parsed_transaction.dart';
import '../models/raw_sms_message.dart';
import 'sms_pipeline.dart';

class IncomingSmsImporter {
  final TransactionRepository repository;
  final SmsPipeline pipeline;

  IncomingSmsImporter(this.repository, {SmsPipeline? pipeline})
    : pipeline = pipeline ?? SmsPipeline();

  Future<ParsedTransaction?> import(RawSmsMessage sms) async {
    final filtered = pipeline.filter.evaluate(sms.body, sender: sms.sender);
    if (!filtered.isAccepted) return null;
    final tx = pipeline.parser.parse(
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
