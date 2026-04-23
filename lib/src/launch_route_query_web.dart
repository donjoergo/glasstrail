import 'package:web/web.dart' as web;

import 'launch_route_query_core.dart';

void clearLaunchRouteQuery() {
  final currentUri = Uri.tryParse(web.window.location.href);
  if (currentUri == null) {
    return;
  }
  final nextUri = withoutLaunchRouteQuery(currentUri);
  if (nextUri == currentUri) {
    return;
  }
  web.window.history.replaceState(null, web.document.title, nextUri.toString());
}
