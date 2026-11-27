/// Upload state of the activity shown in the completion summary.
///
/// [awaitingSignIn] means the activity is saved on the device and the upload
/// was skipped because nobody is signed in; the upload queue sends it after
/// the next sign-in.
enum ActivityUploadStatus {
  idle,
  awaitingSignIn,
  uploading,
  uploaded,
  failed,
  cleanupFailed,
}
