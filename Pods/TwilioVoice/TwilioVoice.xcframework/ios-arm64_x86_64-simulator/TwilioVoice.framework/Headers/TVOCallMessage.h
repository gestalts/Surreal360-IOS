//
//  TVOCallMessage.h
//  TwilioVoice
//
//  Copyright © 2022 Twilio, Inc. All rights reserved.
//

#pragma mark - TVOCallMessageBuilder

/**
 *  `TVOCallMessageBuilder` is a builder class for `TVOCallMessage`.
 */
NS_SWIFT_NAME(CallMessageBuilder)
@interface TVOCallMessageBuilder : NSObject

/**
 * @brief The MIME type for the message.
 *
 * @discussion Currently the only supported type is "application/json", which is also the default value.
 */
@property (nonatomic, copy, nullable) NSString *contentType;

/**
 *  @brief You should not initialize `TVOCallMessageBuilder` directly, use a `TVOCallMessageBuilderBlock` instead.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Use the `TVOCallMessage` initializer instead.")));

@end


#pragma mark - TVOCallMessage

/**
 *  `TVOCallMessageBuilderBlock` allows you to construct `TVOCallMessage` using the builder pattern.
 *
 *  @param builder The builder
 */
typedef void (^TVOCallMessageBuilderBlock)(TVOCallMessageBuilder * _Nonnull builder)
NS_SWIFT_NAME(CallMessageBuilder.Block);

/**
   @brief `TVOCallMessage` represents the in-call message and its configuration.
 
   @discussion Message builder to use when using the `[TVOCall sendMessage:]` method. Example:
 
   ```
     let messageContent = "{\"foo\": \"bar\"}"
     let callMessage = CallMessage(content: messageContent, messageType: "user-defined-message")
 
     let voiceEventSid = call.sendMessage(callMessage)
   ```
 */
NS_SWIFT_NAME(CallMessage)
@interface TVOCallMessage : NSObject

/**
 * @brief The type for the message. The SDK does not validate the value and treats it as a pass-through for both
 * inbound and outbound call messages. To send a user defined message with the `[TVOCall sendMessage:]` method,
 * set the `messageType` to `user-defined-message`.
 */
@property (nonatomic, readonly, copy, nonnull) NSString *messageType;

/**
 * @brief The MIME type for the message.
 *
 * @discussion Currently the only supported type is "application/json", which is also the default value.
 */
@property (nonatomic, copy, readonly, nullable) NSString *contentType;

/**
 * @brief The content body of the message.
 *
 * @discussion The format of the message body must match the content type. The size limit of the message content
 * is 10 KB. `[TVOCall sendMessage:]` with message content that exceeds the size limitation will result in the
 * `[TVOCallMessageDelegate call:didFailToSendMessage:error]` callback.
 *
 * @discussion A call message with content that does not match the content type will not result in the `[TVOCallMessageDelegate call:didFailToSendMessage:error]`
 * callback but will generate an error in your Twilio developer console. For example, a call message with content type "application/json" but
 * with the content "Hello World", which is not a valid JSON object, will result in such error.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *content;

/**
 * @brief The unique identifier of the message.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *voiceEventSid;

/**
 *  @brief Developers shouldn't initialize this class directly.
 *
 *  @discussion Use the `TVOCallMessage`  builder method instead.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Use the `TVOCallMessage` initializer instead.")));

/**
 *  @brief Creates `TVOCallMessage` with the message content.
 *
 *  @param content The message content.
 *
 *  @discussion Default value `application/json` will be used as `contentType`.
 *
 *  @return An instance of `TVOCallMessage`.
 */
+ (nonnull instancetype)messageWithContent:(nonnull NSString *)content
__attribute__( (deprecated("Will not be supported in TwilioVoice v6.12+", "messageWithContent:messageType:block:")) );

/**
 *  @brief Creates `TVOCallMessage` with the message content and message type.
 *
 *  @param content The message content.
 *  @param messageType The message type.
 *  @param builderBlock The `TVOCallMessageBuilderBlock` builder.
 *
 *  @discussion The SDK does not validate the value and treats it as a pass-through for both inbound and outbound call messages.
 *  To send a user defined message with the `[TVOCall sendMessage:]` method, set the `messageType` to `user-defined-message`.
 *  @discussion Default value `application/json` will be used as `contentType` if not explicitly specified in the `builderBlock`.
 *
 *  @return An instance of `TVOCallMessage`.
 */
+ (nonnull instancetype)messageWithContent:(nonnull NSString *)content
                               messageType:(nonnull NSString *)messageType
                                     block:(nullable TVOCallMessageBuilderBlock)builderBlock;

@end
