#import "ViewController.h"
#include <math.h>
#include <stdio.h>

// G3 text layout. Every label has a fixed frame, so the screenshot compares drawing alone;
// the measured sizes are printed separately as "TEXT_METRIC" lines (two decimals).

static NSString *const kParagraph =
    @"Textlayout bricht lange Absätze an Wortgrenzen um. Leerzeichen am Zeilenende hängen über, "
    @"Bindestrich-Wörter dürfen nach dem Bindestrich brechen, und ein überlanges Wort wie "
    @"Donaudampfschifffahrtsgesellschaft wird zwischen Zeichen getrennt.";
static NSString *const kLong = @"Ein sehr langer Satz, der in einer einzigen Zeile keinen Platz hat und gekürzt wird.";

@implementation ViewController {
    NSMutableArray<UILabel *> *_labels;
    NSMutableArray<NSString *> *_names;
    BOOL _calibrated;
}

- (UILabel *)label:(NSString *)name frame:(CGRect)frame text:(NSString *)text size:(CGFloat)size lines:(NSInteger)lines {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.accessibilityIdentifier = [@"text." stringByAppendingString:name];
    label.text = text;
    label.font = [UIFont systemFontOfSize:size];
    label.textColor = UIColor.blackColor;
    label.numberOfLines = lines;
    [self.view addSubview:label];
    [_labels addObject:label];
    [_names addObject:name];
    return label;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    _labels = [NSMutableArray array];
    _names = [NSMutableArray array];

    UILabel *title = [self label:@"title" frame:CGRectMake(16, 50, 358, 34) text:@"Textlayout" size:28 lines:1];
    title.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];

    [self label:@"paragraph" frame:CGRectMake(16, 90, 358, 130) text:kParagraph size:17 lines:0];
    [self label:@"pushout" frame:CGRectMake(24, 224, 342, 44)
           text:@"Gib einen Namen ein und tippe auf den Button." size:17 lines:0];

    UILabel *tail = [self label:@"tail" frame:CGRectMake(16, 272, 358, 20) text:kLong size:15 lines:1];
    tail.lineBreakMode = NSLineBreakByTruncatingTail;
    UILabel *head = [self label:@"head" frame:CGRectMake(16, 294, 358, 20) text:kLong size:15 lines:1];
    head.lineBreakMode = NSLineBreakByTruncatingHead;
    UILabel *middle = [self label:@"middle" frame:CGRectMake(16, 316, 358, 20) text:kLong size:15 lines:1];
    middle.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self label:@"twolines" frame:CGRectMake(16, 340, 250, 38)
           text:[kLong stringByAppendingString:@" Und noch ein Satz dazu."] size:15 lines:2];

    UILabel *center = [self label:@"center" frame:CGRectMake(16, 382, 358, 44)
                             text:@"Zentrierter Text über zwei Zeilen, damit beide Zeilen sichtbar sind." size:17 lines:0];
    center.textAlignment = NSTextAlignmentCenter;
    UILabel *right = [self label:@"right" frame:CGRectMake(16, 428, 358, 22) text:@"Rechtsbündig" size:17 lines:1];
    right.textAlignment = NSTextAlignmentRight;
    UILabel *justified = [self label:@"justified" frame:CGRectMake(16, 452, 358, 74)
                                text:@"Blocksatz verteilt den freien Platz auf die Wortzwischenräume aller Zeilen außer der letzten Zeile des Absatzes."
                                size:15 lines:0];
    justified.textAlignment = NSTextAlignmentJustified;

    NSMutableAttributedString *rich = [[NSMutableAttributedString alloc] initWithString:@"Fett rot unterstrichen gesperrt durch"];
    [rich addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:17] range:NSMakeRange(0, rich.length)];
    [rich addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:20 weight:UIFontWeightBold] range:NSMakeRange(0, 4)];
    [rich addAttribute:NSForegroundColorAttributeName value:UIColor.redColor range:NSMakeRange(5, 3)];
    [rich addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(9, 13)];
    [rich addAttribute:NSKernAttributeName value:@3 range:NSMakeRange(23, 8)];
    [rich addAttribute:NSStrikethroughStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(32, 5)];
    [rich addAttribute:NSBackgroundColorAttributeName value:UIColor.yellowColor range:NSMakeRange(32, 5)];
    UILabel *attributed = [self label:@"attributed" frame:CGRectMake(16, 530, 358, 28) text:@"" size:17 lines:1];
    attributed.attributedText = rich;

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 6;
    style.paragraphSpacing = 10;
    style.firstLineHeadIndent = 20;
    style.headIndent = 8;
    NSAttributedString *styled = [[NSAttributedString alloc]
        initWithString:@"Absatzstil mit Zeilenabstand, Einzug der ersten Zeile und hängendem Einzug.\nZweiter Absatz."
            attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15], NSParagraphStyleAttributeName: style,
                         NSForegroundColorAttributeName: UIColor.blackColor}];
    UILabel *paragraphStyle = [self label:@"paragraphstyle" frame:CGRectMake(16, 562, 358, 104) text:@"" size:15 lines:0];
    paragraphStyle.attributedText = styled;

    [self label:@"emoji" frame:CGRectMake(16, 672, 200, 90)
           text:@"Grüße 👋🏽 日本語のテキストも折り返します。❤️ Ende" size:17 lines:0];
    UILabel *chars = [self label:@"charwrap" frame:CGRectMake(226, 672, 148, 90)
                            text:@"Zeichenumbruch trennt mitten im Wort." size:15 lines:0];
    chars.lineBreakMode = NSLineBreakByCharWrapping;

    [self printMetrics];

    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(16, 776, 358, 20)];
    status.accessibilityIdentifier = @"text.status";
    status.text = @"TEXT_DONE";
    status.font = [UIFont systemFontOfSize:12];
    status.textColor = UIColor.grayColor;
    [self.view addSubview:status];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Only the XCUITest asks for the calibration (about 120 000 measurements, a minute or more):
    // the cold start and the HLE replay stay fast. A label tells the test that it is done.
    if (![NSProcessInfo.processInfo.arguments containsObject:@"-ipahle-calibrate-sf"] || _calibrated) {
        return;
    }
    _calibrated = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self printCalibration];
        UILabel *done = [[UILabel alloc] initWithFrame:CGRectMake(16, 796, 358, 16)];
        done.accessibilityIdentifier = @"text.calibrated";
        done.text = @"TEXT_CALIBRATED";
        done.font = [UIFont systemFontOfSize:10];
        [self.view addSubview:done];
    });
}

- (void)printMetrics {
    for (NSNumber *size in @[@12, @15, @17, @20, @28]) {
        UIFont *font = [UIFont systemFontOfSize:size.doubleValue];
        printf("TEXT_METRIC font %.0f lineHeight=%.2f ascender=%.2f descender=%.2f leading=%.2f capHeight=%.2f xHeight=%.2f\n",
               size.doubleValue, font.lineHeight, font.ascender, font.descender, font.leading, font.capHeight, font.xHeight);
    }
    UIFont *bold = [UIFont boldSystemFontOfSize:17];
    printf("TEXT_METRIC bold17 name=%s lineHeight=%.2f\n", bold.fontName.UTF8String, bold.lineHeight);
    printf("TEXT_METRIC unknownFont=%s\n", [UIFont fontWithName:@"NoSuchFont-Regular" size:12] ? "font" : "nil");

    for (NSUInteger i = 0; i < _labels.count; i++) {
        UILabel *label = _labels[i];
        CGSize fit = [label sizeThatFits:CGSizeMake(label.bounds.size.width, CGFLOAT_MAX)];
        CGSize free = [label sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        CGSize intrinsic = label.intrinsicContentSize;
        printf("TEXT_METRIC label %s fit=%.2fx%.2f free=%.2fx%.2f intrinsic=%.2fx%.2f\n", _names[i].UTF8String,
               fit.width, fit.height, free.width, free.height, intrinsic.width, intrinsic.height);
    }

    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:17]};
    for (NSString *text in @[@"Hallo", @"Hallo Welt, wie geht es dir?", kParagraph]) {
        CGSize size = [text sizeWithAttributes:attributes];
        CGRect fragment = [text boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          attributes:attributes context:nil];
        CGRect baseline = [text boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX) options:0
                                          attributes:attributes context:nil];
        printf("TEXT_METRIC string len=%lu size=%.2fx%.2f fragment=%.2f,%.2f,%.2fx%.2f baseline=%.2f,%.2f,%.2fx%.2f\n",
               (unsigned long)text.length, size.width, size.height, fragment.origin.x, fragment.origin.y,
               fragment.size.width, fragment.size.height, baseline.origin.x, baseline.origin.y,
               baseline.size.width, baseline.size.height);
    }
    // Width series for the SF Pro stand-in: per size and weight, strings of different length
    // separate a width scale from SF's size-dependent tracking.
    NSArray<NSString *> *samples = @[@"abcdefghijklmnopqrstuvwxyz", @"ABCDEFGHIJKLMNOPQRSTUVWXYZ", @"0123456789",
                                     @"Handgloves Typografie", @"ii", @"MM"];
    NSArray<NSNumber *> *weights = @[@(UIFontWeightRegular), @(UIFontWeightMedium), @(UIFontWeightSemibold),
                                     @(UIFontWeightBold)];
    for (NSNumber *weight in weights) {
        for (NSNumber *size in @[@9, @11, @12, @13, @14, @15, @16, @17, @18, @19, @20, @22, @24, @28, @32, @34, @40, @48]) {
            UIFont *font = [UIFont systemFontOfSize:size.doubleValue weight:weight.doubleValue];
            printf("TEXT_WIDTH w=%.2f pt=%.0f", weight.doubleValue, size.doubleValue);
            for (NSString *sample in samples) {
                printf(" %.3f", [sample sizeWithAttributes:@{NSFontAttributeName: font}].width);
            }
            printf("\n");
        }
    }
    // Per-character advances: glyph shapes of the stand-in differ character by character.
    NSString *charset = @" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`"
                        @"abcdefghijklmnopqrstuvwxyz{|}~äöüßÄÖÜéèàçñ€–—…„“”‘’«»·•";
    for (NSNumber *weight in @[@(UIFontWeightRegular), @(UIFontWeightBold)]) {
        for (NSNumber *size in @[@17, @28]) {
            UIFont *font = [UIFont systemFontOfSize:size.doubleValue weight:weight.doubleValue];
            printf("TEXT_CHARS w=%.2f pt=%.0f", weight.doubleValue, size.doubleValue);
            for (NSUInteger i = 0; i < charset.length; i++) {
                NSString *one = [charset substringWithRange:NSMakeRange(i, 1)];
                // Ten in a row: the advance without rounding noise of a single glyph.
                NSString *ten = [@"" stringByPaddingToLength:10 withString:one startingAtIndex:0];
                printf(" %.3f", [ten sizeWithAttributes:@{NSFontAttributeName: font}].width / 10.0);
            }
            printf("\n");
        }
    }
    UIFont *body = [UIFont systemFontOfSize:17];
    for (NSString *sample in @[@"👋", @"👋🏽", @"❤️", @"🇩🇪", @"👨‍👩‍👧", @"日", @"本語", @"。", @"テキスト"]) {
        printf("TEXT_WIDTH glyph %s %.3f\n", sample.UTF8String, [sample sizeWithAttributes:@{NSFontAttributeName: body}].width);
    }
    printf("TEXT_DONE\n");
}

- (void)printCalibration {
    // Calibration of SF Pro for the HLE (G3): advances also for Medium and Semibold; the size-dependent
    // tracking as the advance of "n" at every size (the same offset for every character of one optical
    // font); kerning pairs as w("ab") - w("a") - w("b"), only those not zero, by index into charset.
    NSString *charset = @" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`"
                        @"abcdefghijklmnopqrstuvwxyz{|}~äöüßÄÖÜéèàçñ€–—…„“”‘’«»·•";
    NSArray<NSNumber *> *allWeights = @[@(UIFontWeightRegular), @(UIFontWeightMedium), @(UIFontWeightSemibold),
                                        @(UIFontWeightBold)];
    for (NSNumber *weight in @[@(UIFontWeightMedium), @(UIFontWeightSemibold)]) {
        for (NSNumber *size in @[@17, @28]) {
            UIFont *font = [UIFont systemFontOfSize:size.doubleValue weight:weight.doubleValue];
            printf("TEXT_CHARS w=%.2f pt=%.0f", weight.doubleValue, size.doubleValue);
            for (NSUInteger i = 0; i < charset.length; i++) {
                NSString *one = [charset substringWithRange:NSMakeRange(i, 1)];
                NSString *ten = [@"" stringByPaddingToLength:10 withString:one startingAtIndex:0];
                printf(" %.3f", [ten sizeWithAttributes:@{NSFontAttributeName: font}].width / 10.0);
            }
            printf("\n");
        }
    }
    for (NSNumber *weight in allWeights) {
        printf("TEXT_TRACK w=%.2f", weight.doubleValue);
        for (NSNumber *size in @[@6, @8, @9, @10, @11, @12, @13, @14, @15, @16, @17, @18, @19, @20, @22, @24, @26, @28,
                                 @30, @32, @34, @36, @40, @48, @56, @64]) {
            UIFont *font = [UIFont systemFontOfSize:size.doubleValue weight:weight.doubleValue];
            printf(" %.0f:%.4f", size.doubleValue,
                   [@"nnnnnnnnnn" sizeWithAttributes:@{NSFontAttributeName: font}].width / 10.0);
        }
        printf("\n");
    }
    for (NSNumber *weight in allWeights) {
        for (NSNumber *size in @[@17, @28]) {
            UIFont *font = [UIFont systemFontOfSize:size.doubleValue weight:weight.doubleValue];
            NSDictionary *attributes = @{NSFontAttributeName: font};
            NSUInteger count = charset.length;
            double single[256];
            for (NSUInteger i = 0; i < count && i < 256; i++) {
                single[i] = [[charset substringWithRange:NSMakeRange(i, 1)] sizeWithAttributes:attributes].width;
            }
            NSUInteger pairs = 0;
            for (NSUInteger i = 0; i < count && i < 256; i++) {
                NSString *a = [charset substringWithRange:NSMakeRange(i, 1)];
                for (NSUInteger j = 0; j < count && j < 256; j++) {
                    NSString *pair = [a stringByAppendingString:[charset substringWithRange:NSMakeRange(j, 1)]];
                    double kern = [pair sizeWithAttributes:attributes].width - single[i] - single[j];
                    if (fabs(kern) >= 0.001) {
                        printf("TEXT_KERN w=%.2f pt=%.0f %lu %lu %.3f\n", weight.doubleValue, size.doubleValue,
                               (unsigned long)i, (unsigned long)j, kern);
                        pairs++;
                    }
                }
            }
            printf("TEXT_KERN_COUNT w=%.2f pt=%.0f %lu\n", weight.doubleValue, size.doubleValue, (unsigned long)pairs);
        }
    }
    printf("TEXT_CALIBRATED\n");
}

@end
