#import "FFTBufferManager.hpp"

@protocol AudioControllerDelegate

@required
- (void) receivedWaveSamples:(SInt32*) samples length:(int) len;
- (void) receivedFreqSamples:(int32_t*) samples length:(int) len;

@end

@interface AudioController : NSObject 
{
    @public
    AudioBufferList bufferList;
    FFTBufferManager    *_fft;
    int32_t             *_fftData;
}
@property (nonatomic, assign) AudioStreamBasicDescription audioFormat;
@property (nonatomic, assign) AudioUnit rioUnit;
@property (nonatomic, assign) id<AudioControllerDelegate> delegate;

+ (AudioController*) sharedAudioManager;
- (void) startAudio;

@end




