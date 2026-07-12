// Native platforms have no browser address bar/URL to clean up, so this is
// a no-op — exists only so callers can invoke clearLaunchRouteQuery
// unconditionally regardless of platform.
void clearLaunchRouteQuery() {}
