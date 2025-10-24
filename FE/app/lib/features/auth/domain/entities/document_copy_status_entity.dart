enum DocumentCopyStatus { AVAILABLE, BORROWED, LOST, DAMAGED, UNKNOWN }

DocumentCopyStatus documentCopyStatusFrom(String? v) {
  switch (v?.toUpperCase()) {
    case 'AVAILABLE':
      return DocumentCopyStatus.AVAILABLE;
    case 'BORROWED':
      return DocumentCopyStatus.BORROWED;
    case 'LOST':
      return DocumentCopyStatus.LOST;
    case 'DAMAGED':
      return DocumentCopyStatus.DAMAGED;
    default:
      return DocumentCopyStatus.UNKNOWN;
  }
}

String documentCopyStatusTo(DocumentCopyStatus s) {
  switch (s) {
    case DocumentCopyStatus.AVAILABLE:
      return 'AVAILABLE';
    case DocumentCopyStatus.BORROWED:
      return 'BORROWED';
    case DocumentCopyStatus.LOST:
      return 'LOST';
    case DocumentCopyStatus.DAMAGED:
      return 'DAMAGED';
    case DocumentCopyStatus.UNKNOWN:
      return 'UNKNOWN';
  }
}