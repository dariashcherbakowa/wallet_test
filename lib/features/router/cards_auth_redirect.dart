String? cardsAuthRedirect(Uri uri, bool isAuthed) {
  final path = uri.path;

  if (!isAuthed && (path == '/cards' || path.startsWith('/cards/'))) {
    final next = Uri.encodeComponent(uri.toString());
    return '/onboarding?next=$next';
  }

  if (isAuthed && path == '/onboarding') {
    final next = uri.queryParameters['next'];
    if (next != null && next.isNotEmpty) {
      if (next.startsWith('/cards')) {
        return next;
      }
      return '/cards';
    }
    return '/cards';
  }

  if (!isAuthed && path == '/onboarding') {
    return null;
  }

  return null;
}
