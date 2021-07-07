#import "TfliteFlutterHelperPlugin.h"
#if __has_include(<tflite_flutter_helper/tflite_flutter_helper-Swift.h>)
#import <tflite_flutter_helper/tflite_flutter_helper-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "tflite_flutter_helper-Swift.h"
#endif

@implementation TfliteFlutterHelperPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftTfliteFlutterHelperPlugin registerWithRegistrar:registrar];
}
@end
