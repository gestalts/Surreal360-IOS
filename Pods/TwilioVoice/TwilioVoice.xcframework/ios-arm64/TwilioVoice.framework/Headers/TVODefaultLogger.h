//
//  TVODefaultLogger.h
//  TwilioVoiceClient
//
//  Copyright © 2023 Twilio, Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "TVOLogger.h"

/**
 *  `TVODefaultLogger` allows you to send your app to the default logger.
 */
NS_SWIFT_NAME(DefaultLogger)
@interface TVODefaultLogger : NSObject <TVOLogger>

/**
 * @brief This method can be invoked to send app level logs to the default logger
 * used by the SDK to log to stdout. Please note that `timeStamp` parameter provided in the
 * `logParameters` will not be used by the default logger and the timestamp
 * string will be generated during actual logging to stdout.
 *
 * @param logParameters The `TVOLogParameters` for the log message.
 * @see TVOLogParameters
 */
- (void)log:(nonnull TVOLogParameters *)logParameters
NS_SWIFT_NAME(log(params:));

@end
