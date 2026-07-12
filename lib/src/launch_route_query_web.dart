import 'package:web/web.dart' as web;

import 'launch_route_query_core.dart';

void clearLaunchRouteQuery() {
  final currentUri = Uri.tryParse(web.window.location.href);
  if (currentUri == null) {
    return;
  }
  final nextUri = withoutLaunchRouteQuery(currentUri);
  // Skip the history write entirely when there was no `route` param to
  // begin with, to avoid pushing a redundant history entry/URL update on
  // every normal (non-deep-linked) page load.
  if (nextUri == currentUri) {
    return;
  }
  // replaceState (not pushState) so removing the query param doesn't add a
  // new back-button stop — the user shouldn't be able to navigate "back" to
  // the pre-cleanup URL with the route param still attached.
  web.window.history.replaceState(null, web.document.title, nextUri.toString());
}
