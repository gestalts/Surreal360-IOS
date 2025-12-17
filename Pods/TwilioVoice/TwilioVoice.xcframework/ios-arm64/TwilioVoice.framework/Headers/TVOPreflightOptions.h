//
//  TVOPreflightOptions.h
//  TwilioVoice
//
//  Copyright © 2024 Twilio, Inc. All rights reserved.
//

@class TVOAudioCodec;
@class TVOIceOptions;

#pragma mark - TVOPreflightOptionsBuilder

/**
 *  `TVOPreflightOptionsBuilder` is a builder class for `TVOPreflightOptions`.
 */
NS_SWIFT_NAME(PreflightOptionsBuilder)
@interface TVOPreflightOptionsBuilder : NSObject

/**
 *  @brief The queue where the preflight test will invoke delegate methods.
 *
 *  @discussion All delegate methods are performed on this queue. Any `TVOPreflightTest` instance
 *  which is created with these options will maintain a strong reference to the queue until
 *  it is destroyed.
 *  The default value of `nil` indicates that the main dispatch queue will be used.
 */
@property (nonatomic, strong, nullable) dispatch_queue_t delegateQueue;

/**
 *  @brief A custom ICE configuration used to run a preflight test.
 */
@property (nonatomic, strong, nullable) TVOIceOptions *iceOptions;

/**
 * @brief The collection of preferred audio codecs.
 *
 * @discussion The list specifies which audio codecs will be preferred when negotiating audio between participants.
 * The preferences are applied in the order found in the list starting with the most preferred audio codec to the
 * least preferred audio codec. Audio codec preferences are not guaranteed to be satisfied because not all participants
 * are guaranteed to support all audio codecs. `TVOOpusCodec` is the default audio codec if no preferences are set.
 */
@property (nonatomic, copy, nonnull) NSArray<TVOAudioCodec *> *preferredAudioCodecs;

/**
 *  @brief You should not initialize `TVOPreflightOptionsBuilder` directly, use a `TVOPreflightOptionsBuilderBlock` instead.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Use the `TVOPreflightOptionsBuilderBlock` instead.")));

@end


/**
 *  `TVOPreflightOptionsBuilderBlock` allows you to construct `TVOPreflightOptions` using the builder pattern.
 *
 *  @param builder The builder.
 */
typedef void (^TVOPreflightOptionsBuilderBlock)(TVOPreflightOptionsBuilder * _Nonnull builder)
NS_SWIFT_NAME(PreflightOptionsBuilder.Block);


#pragma mark - TVOPreflightOptions

/**
 * Represents options available when running a preflight test.
 */
NS_SWIFT_NAME(PreflightOptions)
@interface TVOPreflightOptions : NSObject

/**
 * @brief A JWT access token which will be used to run the preflight test.
 */
@property (nonatomic, copy, readonly, nullable) NSString *accessToken;

/**
 *  @brief The queue where the preflight test will invoke delegate methods.
 *
 *  @discussion All delegate methods are performed on this queue. Any `TVOPreflightTest` instance
 *  which is created with these options will maintain a strong reference to the queue until
 *  it is destroyed.
 *  The default value of `nil` indicates that the main dispatch queue will be used.
 */
@property (nonatomic, strong, readonly, nullable) dispatch_queue_t delegateQueue;

/**
 *  @brief A custom ICE configuration used to run a preflight test.
 */
@property (nonatomic, strong, readonly, nullable) TVOIceOptions *iceOptions;

/**
 * @brief The collection of preferred audio codecs.
 *
 * @discussion The list specifies which audio codecs will be preferred when negotiating audio between participants.
 * The preferences are applied in the order found in the list starting with the most preferred audio codec to the
 * least preferred audio codec. Audio codec preferences are not guaranteed to be satisfied because not all participants
 * are guaranteed to support all audio codecs. `TVOOpusCodec` is the default audio codec if no preferences are set.
 */
@property (nonatomic, copy, readonly, nonnull) NSArray<TVOAudioCodec *> *preferredAudioCodecs;

/**
 *  @brief Developers shouldn't initialize this class directly.
 *
 *  @discussion Use the designated builder methods instead.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Use the designated builder methods instead.")));

/**
 *  @brief Creates an instance of `TVOPreflightOptions` using an access token.
 *
 *  @param accessToken A JWT access token which will be used to run the preflight test.
 *
 *  @return An instance of `TVOPreflightOptions`.
 */
+ (nonnull instancetype)optionsWithAccessToken:(nonnull NSString *)accessToken;

/**
 *  @brief Creates an instance of `TVOPreflightOptions` using an access token and a builder block.
 *
 *  @param accessToken A JWT access token which will be used to run the preflight test.
 *  @param block The builder block which will be used to configure the `TVOPreflightOptions` instance.
 *
 *  @return An instance of `TVOPreflightOptions`.
 */
+ (nonnull instancetype)optionsWithAccessToken:(nonnull NSString *)accessToken
                                         block:(nonnull TVOPreflightOptionsBuilderBlock)block;

@end
