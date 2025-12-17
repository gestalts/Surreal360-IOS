//
//  TVOLogger.h
//  TwilioVoice
//
//  Copyright © 2023 Twilio, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TVOLogParameters.h"
/**
 * `TVOLogger` is the protocol for the custom logger that can be implemented by the SDK user.
 */

NS_SWIFT_NAME(Logger)
@protocol TVOLogger <NSObject>
/**
 * @name Required Methods
 */

/**
 * @brief Invoked every time there is a log message available that
 * satisfies the log module and log level filters set by the
 * developer. Please note that this method will be invoked very frequently
 * so avoid doing heavy work on this thread.
 *
 * @param logParameters The `<TVOLogParameters>` for the log message.
 * @see TVOLogParameters
 */
- (void)log:(nonnull TVOLogParameters *)logParameters
NS_SWIFT_NAME(log(params:));

@end

