// Legacy entry-point. The implementation now lives at
// `presentation/screens/orders_screen.dart`. We keep this file as a
// re-export so the dozen callers (HomeProvider, route maps, etc.) keep
// working without an import change.
export 'presentation/screens/orders_screen.dart' show OrdersScreeen;
