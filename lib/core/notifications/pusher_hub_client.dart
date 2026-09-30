import '../../pusher_hub.dart';

/// Global PusherHub client instance configured for ProCut
final pusherHub = PusherHub(
  appKey: 'PROCUT',
  publicKey: 'pk_live_fRUyYsYpeoSSQac4dweFb5KhhJHg9yzb',
  baseUrl: 'https://pusherhub.com/api',
);
