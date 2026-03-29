import 'package:flutter/foundation.dart';

import '../../../config/app_config.dart';

/// Non-secret context for deletion callables (support / abuse logging).
Map<String, String> accountDeletionClientMeta() => <String, String>{
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'appVersion': AppConfig.appVersion,
    };
