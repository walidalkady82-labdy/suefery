
enum DatabaseExceptionCode{
  generalError('general-error','An unknown exception occurred.'),
  userCreationFailed('user-creation-failed', 'Could not join user to workplace!'),
  notUserData('no-user-data', 'you are not logged in , please register first!'),
  noUserRole('no-user-role', 'User role is not set!'),
  wrongUserRole('wrong-user-role', 'unsuccessfull , problem in user role!'),
  noWorkplace('no-workplace', 'Cannot find workplaceId for user'),
  alreadyJoinedWorkplace('already-joined-workplace', 'unsuccessfull , you already have joined an workplace!'),
  workplaceCreationFailed('workplace-creation-failed', 'unsuccessfull , workplace could not be created!'),
  workplaceNameMissing('workplace-name-missing', 'unsuccessfull , workplace name is missing!'),
  workplaceNotFound('workplace-not-found', 'Invitaion expired!'),
  collectionPathNotFound('collection-path-not-found', 'Could not find the collection path!'),

  invitationCode('invitation-code', 'Invitaion code error!'),
  invitationData('invitation-data', 'Invitaion data error!'),
  invitationExpired('invitation-expired', 'Invitaion expired!'),

  ;
  const DatabaseExceptionCode(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => '$code: $message';
}

class DatabaseFailure implements Exception{

  DatabaseFailure(this.message,[this.code=DatabaseExceptionCode.generalError]);  
  @override
  String toString() {
    return 'DatabaseFailure: $message';
  }
  final String message;
  final DatabaseExceptionCode? code;
}

class NoWorkplaceFailure extends DatabaseFailure {
  NoWorkplaceFailure([String? message]):
    super(message??DatabaseExceptionCode.noWorkplace.message,DatabaseExceptionCode.noWorkplace);
}

class UserCreationDBFailure extends DatabaseFailure {
  UserCreationDBFailure([String? message]): 
  super(message??DatabaseExceptionCode.userCreationFailed.message,DatabaseExceptionCode.userCreationFailed);
}

class WorkplaceNameMissingFailure extends DatabaseFailure {
  WorkplaceNameMissingFailure([String? message]): 
  super(message??DatabaseExceptionCode.workplaceNameMissing.message,DatabaseExceptionCode.workplaceNameMissing);
}

class WorkplaceCreationFailure extends DatabaseFailure {
  WorkplaceCreationFailure([String? message]): 
  super(message??DatabaseExceptionCode.workplaceCreationFailed.message,DatabaseExceptionCode.workplaceCreationFailed);
}

class WorkplaceNotFoundFailure extends DatabaseFailure {
  WorkplaceNotFoundFailure([String? message]): 
  super(message??DatabaseExceptionCode.workplaceNotFound.message,DatabaseExceptionCode.workplaceNotFound);
}

class MissingUserRoleFailure extends DatabaseFailure {
  MissingUserRoleFailure([String? message]): 
  super(message??DatabaseExceptionCode.wrongUserRole.message,DatabaseExceptionCode.wrongUserRole);
}

class InvitationCodeFailure extends DatabaseFailure {
  InvitationCodeFailure([String? message]): 
  super(message??DatabaseExceptionCode.invitationCode.message,DatabaseExceptionCode.invitationCode);
}

class InvitationCodeExpiredFailure extends DatabaseFailure {
  InvitationCodeExpiredFailure([String? message]): 
  super(message??DatabaseExceptionCode.invitationExpired.message,DatabaseExceptionCode.invitationExpired);
}

class InvitationDataFailure extends DatabaseFailure {
  InvitationDataFailure([String? message]): 
  super(message??DatabaseExceptionCode.invitationData.message,DatabaseExceptionCode.invitationData);
}

class ColllectionPathFailure extends DatabaseFailure {
  ColllectionPathFailure([String? message]):
    super(message??DatabaseExceptionCode.noWorkplace.message,DatabaseExceptionCode.noWorkplace);
}
