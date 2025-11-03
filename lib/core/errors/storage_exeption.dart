
import '../../data/services/logging_service.dart';

final log = LoggerRepo('StorageExceptions');

class UploadImageFailure implements Exception{

  UploadImageFailure([
    this.message = 'An unknown exception occurred.'
  ]){
    log.e(message);
  }
  final String message;
}