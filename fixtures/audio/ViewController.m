#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <string.h>
#import <unistd.h>

static void write_line(const char *line) {
    size_t remaining = strlen(line);
    const char *cursor = line;
    while (remaining > 0) {
        ssize_t written = write(STDOUT_FILENO, cursor, remaining);
        if (written <= 0) {
            break;
        }
        cursor += written;
        remaining -= (size_t)written;
    }
    (void)write(STDOUT_FILENO, "\n", 1);
}

static BOOL run_audio(void) {
    NSError *error = nil;
    AVAudioSession *session = AVAudioSession.sharedInstance;
    BOOL categoryOK = [session setCategory:AVAudioSessionCategoryPlayback error:&error]
        && [session.category isEqualToString:AVAudioSessionCategoryPlayback];
    write_line(categoryOK ? "category Playback: OK" : "category Playback: FAIL");

    NSURL *url = [NSBundle.mainBundle URLForResource:@"beep" withExtension:@"wav"];
    error = nil;
    AVAudioPlayer *player = url ? [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error] : nil;
    BOOL loaded = player != nil && error == nil && [player prepareToPlay];
    BOOL started = loaded && [player play] && player.isPlaying;
    BOOL durationOK = started && player.duration > 0.15 && player.duration < 0.35;
    write_line(durationOK ? "player beep.wav: OK" : "player beep.wav: FAIL");

    SystemSoundID sound = 0;
    OSStatus created = url ? AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &sound) : -1;
    BOOL soundOK = created == 0 && sound != 0;
    if (soundOK) {
        AudioServicesPlayAlertSound(sound);
        AudioServicesDisposeSystemSoundID(sound);
    }
    AudioServicesPlaySystemSound(1000);
    write_line(soundOK ? "system sound file: OK" : "system sound file: FAIL");

    BOOL passed = categoryOK && durationOK && soundOK;
    write_line(passed ? "AUDIO_OK" : "AUDIO_FAIL");
    return passed;
}

@interface ViewController ()
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UIStackView *content = [[UIStackView alloc] init];
    content.axis = UILayoutConstraintAxisVertical;
    content.alignment = UIStackViewAlignmentCenter;
    content.spacing = 24;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:content];

    UILabel *title = [[UILabel alloc] init];
    title.accessibilityIdentifier = @"audio.title";
    title.text = @"Audio Fixture";
    title.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    [content addArrangedSubview:title];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.accessibilityIdentifier = @"audio.status";
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    [content addArrangedSubview:self.statusLabel];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintGreaterThanOrEqualToAnchor:safeArea.leadingAnchor constant:20],
        [content.trailingAnchor constraintLessThanOrEqualToAnchor:safeArea.trailingAnchor constant:-20],
        [content.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor]
    ]];

    self.statusLabel.text = run_audio() ? @"AUDIO_OK" : @"AUDIO_FAIL";
}

@end
