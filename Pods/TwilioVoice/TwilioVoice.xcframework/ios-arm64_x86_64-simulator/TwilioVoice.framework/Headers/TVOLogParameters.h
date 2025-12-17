//
//  TVOLogParameters.h
//  TwilioVoiceClient
//
//  Copyright © 2023 Twilio, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * An enumeration indicating log levels that can be used with the SDK.
 */
typedef NS_ENUM(NSUInteger, TVOLogLevel) {
    TVOLogLevelOff = 0,     ///< Disables all SDK logging.
    TVOLogLevelFatal,       ///< Show very severe error events that will presumably lead the application to abort.
    TVOLogLevelError,       ///< Show errors only.
    TVOLogLevelWarning,     ///< Show warnings as well as all **Error** log messages.
    TVOLogLevelInfo,        ///< Show informational messages as well as all **Warn** log messages.
    TVOLogLevelDebug,       ///< Show debugging messages as well as all **Info** log messages.
    TVOLogLevelTrace,       ///< Show low-level debugging messages as well as all **Debug** log messages.
    TVOLogLevelAll          ///< Show all logging.
}
NS_SWIFT_NAME(TwilioVoiceSDK.LogLevel);

/**
 * An enumeration indicating log modules that can be used with the SDK.
 */
typedef NS_ENUM(NSUInteger, TVOLogModule) {
    TVOLogModuleCore = 0,   ///< Voice Core SDK.
    TVOLogModulePlatform,   ///< Voice iOS SDK.
    TVOLogModuleSignaling,  ///< Signaling module.
    TVOLogModuleWebRTC      ///< WebRTC module.
}
NS_SWIFT_NAME(TwilioVoiceSDK.LogModule);

/**
 * A struct used to pass logging parameters to the `log` method in `<TVOLogger>`.
 */
NS_SWIFT_NAME(LogParameters)
@interface TVOLogParameters : NSObject

/**
 * `TVOLogModule` for the logger.
 */
@property (nonatomic, assign) TVOLogModule logModule;
/**
 * `TVOLogLevel` for the logger.
 */
@property (nonatomic, assign) TVOLogLevel logLevel;
/**
 * Local Timestamp for the log statement in YY-MM-DD HH:MM:SS.MMM format
 */
@property (nonatomic, copy, nullable) NSString *timeStamp;
/**
 * File name for the log statement.
 */
@property (nonatomic, copy, nullable) NSString *fileName;

/**
 * Function name for the log statement.
 */
@property (nonatomic, copy, nullable) NSString *functionName;
/**
 * Line number for the log statement.
 */
@property (nonatomic, strong, nullable) NSNumber *lineNumber;
/**
 * Tag for the log statement.
 */
@property (nonatomic, copy, nullable) NSString *tag;

/**
 * The thread name/id.
 */
@property (nonatomic, copy, nonnull) NSString *thread;

/**
 * The log statement body.
 */
@property (nonatomic, copy, nonnull) NSString *message;

- (null_unspecified instancetype)init __attribute__((unavailable("Use initWithModule:logLevel:fileName:functioName:lineNumber:tag:message instead")));

/**
 * @brief Initialize the `LogParameters`.
 *
 * @param logModule The `TVOLogModule` value for the log statement
 * @param logLevel The `TVOLogLevel` for the log statement
 * @param timeStamp Local Timestamp in YY-MM-DD HH:MM:SS.MMM format
 * @param fileName A nullable string that shows the file name of the log statement
 * @param functionName A nullable string that shows the function name of the log statement
 * @param lineNumber A nullable number representing the line number of the log statement in the file
 * @param tag A nullable string that can be used to specify any user defined tag in the log line
 * @param thread A nullable string that can be used to specify the thread name or id
 * @param message Nonnull string for the log statement
 *
 * @return An initialized `LogParameters` instance.
 *
 */
- (null_unspecified instancetype)initWithModule:(TVOLogModule)logModule
                                       logLevel:(TVOLogLevel)logLevel
                                      timeStamp:(nullable NSString *)timeStamp
                                       fileName:(nullable NSString *)fileName
                                   functionName:(nullable NSString *)functionName
                                     lineNumber:(nullable NSNumber *)lineNumber
                                            tag:(nullable NSString *)tag
                                         thread:(nullable NSString *)thread
                                        message:(nonnull NSString *)message;

/**
 * @brief Initialize the `LogParameters`.
 * @discussion This initilizer only initializes required varriables for the log statement. All other parameters are set to `nil`
 *
 * @param logModule The `TVOLogModule` value for the log statement
 * @param logLevel The `TVOLogLevel` for the log statement
 * @param message Nonnull string for the log statement
 *
 * @return An initialized `LogParameters` instance.
 *
 */
- (null_unspecified instancetype)initWithModule:(TVOLogModule)logModule
                                       logLevel:(TVOLogLevel)logLevel
                                        message:(nonnull NSString *)message;
@end
