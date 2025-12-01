

class UploadImageFailure implements Exception{

  UploadImageFailure([
    this.message = 'An unknown exception occurred.'
  ]){
    //log.e(message);
  }
  final String message;
}