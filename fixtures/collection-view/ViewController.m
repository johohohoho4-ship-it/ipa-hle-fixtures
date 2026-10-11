#import "ViewController.h"
#include <stdio.h>

// F11 reference: a vertical UICollectionViewFlowLayout with a registered system cell class, two sections of
// 30 and 10 items and a delegate that only reports display, selection and (in the last step) item sizes.
// Every line is COL_*; the HLE replays the same app and must print the same lines (layout geometry, call
// order, reuse, selection, scroll positions). `COL_ATTR` prints the layout's own attribute frames, which is
// where the justified lines and the left-aligned last line of each section show up.

static NSString *const kCell = @"cell";

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property(nonatomic, strong) UICollectionView *collection;
@property(nonatomic, strong) UICollectionViewFlowLayout *flow;
@property(nonatomic, strong) UILabel *status;
@property(nonatomic) NSInteger step;
@property(nonatomic) BOOL logCalls;
@property(nonatomic) BOOL delegateSizes;
@end

@implementation ViewController

static NSString *rect(CGRect r) { return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r.origin.x, r.origin.y, r.size.width, r.size.height]; }
static NSString *rgba(UIColor *c) {
    if (!c) return @"nil";
    CGFloat r = 0, g = 0, b = 0, a = 0;
    [c getRed:&r green:&g blue:&b alpha:&a];
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r, g, b, a];
}

- (void)state:(NSString *)phase {
    NSMutableArray *visible = [NSMutableArray array];
    for (NSIndexPath *p in [[self.collection indexPathsForVisibleItems] sortedArrayUsingSelector:@selector(compare:)])
        [visible addObject:[NSString stringWithFormat:@"%ld.%ld", (long)p.section, (long)p.item]];
    printf("COL_STATE phase=%s offset=%.3f,%.3f size=%.3f,%.3f bounds=%s visible=%s cells=%lu subviews=%lu\n", phase.UTF8String,
           self.collection.contentOffset.x, self.collection.contentOffset.y, self.collection.contentSize.width,
           self.collection.contentSize.height, rect(self.collection.bounds).UTF8String,
           [visible componentsJoinedByString:@","].UTF8String, (unsigned long)self.collection.visibleCells.count,
           (unsigned long)self.collection.subviews.count);
}

- (void)attributes:(NSInteger)section item:(NSInteger)item {
    NSIndexPath *path = [NSIndexPath indexPathForItem:item inSection:section];
    UICollectionViewLayoutAttributes *attributes = [self.flow layoutAttributesForItemAtIndexPath:path];
    printf("COL_ATTR path=%ld.%ld frame=%s\n", (long)section, (long)item, rect(attributes.frame).UTF8String);
}

- (void)cellGeometry:(NSInteger)section item:(NSInteger)item {
    UICollectionViewCell *cell = [self.collection cellForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section]];
    if (!cell) { printf("COL_CELL path=%ld.%ld none\n", (long)section, (long)item); return; }
    printf("COL_CELL path=%ld.%ld frame=%s content=%s background=%s selected=%d highlighted=%d reuse=%s subviews=%lu\n",
           (long)section, (long)item, rect(cell.frame).UTF8String, rect(cell.contentView.frame).UTF8String,
           rgba(cell.backgroundColor).UTF8String, cell.selected, cell.highlighted, cell.reuseIdentifier.UTF8String,
           (unsigned long)cell.subviews.count);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.flow = [[UICollectionViewFlowLayout alloc] init];
    printf("COL_DEFAULTS itemSize=%.3f,%.3f line=%.3f interitem=%.3f inset=%.3f,%.3f,%.3f,%.3f direction=%ld header=%.3f,%.3f estimated=%.3f,%.3f\n",
           self.flow.itemSize.width, self.flow.itemSize.height, self.flow.minimumLineSpacing, self.flow.minimumInteritemSpacing,
           self.flow.sectionInset.top, self.flow.sectionInset.left, self.flow.sectionInset.bottom, self.flow.sectionInset.right,
           (long)self.flow.scrollDirection, self.flow.headerReferenceSize.width, self.flow.headerReferenceSize.height,
           self.flow.estimatedItemSize.width, self.flow.estimatedItemSize.height);
    self.flow.itemSize = CGSizeMake(100, 60);
    self.flow.minimumLineSpacing = 12;
    self.flow.minimumInteritemSpacing = 8;
    self.flow.sectionInset = UIEdgeInsetsMake(10, 15, 20, 15);
    self.collection = [[UICollectionView alloc] initWithFrame:CGRectMake(20, 100, 350, 300) collectionViewLayout:self.flow];
    self.collection.accessibilityIdentifier = @"collection.view";
    printf("COL_CONFIG bounces=%d adjust=%ld allowsSelection=%d multiple=%d prefetching=%d background=%s\n", self.collection.bounces,
           (long)self.collection.contentInsetAdjustmentBehavior, self.collection.allowsSelection,
           self.collection.allowsMultipleSelection, self.collection.isPrefetchingEnabled,
           rgba(self.collection.backgroundColor).UTF8String);
    self.collection.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.collection.bounces = NO;
    self.collection.dataSource = self;
    self.collection.delegate = self;
    [self.collection registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kCell];
    [self.view addSubview:self.collection];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(40, 420, 220, 45);
    [button setTitle:@"Advance" forState:UIControlStateNormal];
    button.accessibilityIdentifier = @"collection.advance";
    [button addTarget:self action:@selector(advance:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    self.status = [[UILabel alloc] initWithFrame:CGRectMake(30, 480, 330, 45)];
    self.status.text = @"Ready";
    self.status.accessibilityIdentifier = @"collection.status";
    [self.view addSubview:self.status];
}

- (void)advance:(UIButton *)sender {
    self.step++;
    printf("COL_BEFORE step=%ld\n", (long)self.step);
    self.logCalls = YES;
    if (self.step == 1) {                                   // first load
        [self.collection reloadData];
        [self.collection layoutIfNeeded];
        [self state:@"loaded"];
        for (NSInteger item = 0; item < 4; item++) [self cellGeometry:0 item:item];
        for (NSInteger item = 0; item < 8; item++) [self attributes:0 item:item];
        [self attributes:0 item:29];                        // last item of the first section (a partly filled line)
        [self attributes:1 item:0];
        [self attributes:1 item:9];
    } else if (self.step == 2) {                            // scroll: new items in, old cells reused
        NSMutableArray *before = [NSMutableArray array];
        for (UICollectionViewCell *cell in self.collection.visibleCells) [before addObject:@((NSUInteger)cell)];
        self.collection.contentOffset = CGPointMake(0, 400);
        [self.collection layoutIfNeeded];
        [self state:@"scrolled"];
        NSUInteger reused = 0;
        for (UICollectionViewCell *cell in self.collection.visibleCells) reused += [before containsObject:@((NSUInteger)cell)];
        printf("COL_REUSE reused=%lu of=%lu\n", (unsigned long)reused, (unsigned long)self.collection.visibleCells.count);
        [self cellGeometry:0 item:14];
    } else if (self.step == 3) {                            // programmatic selection
        NSIndexPath *path = [NSIndexPath indexPathForItem:14 inSection:0];
        [self.collection selectItemAtIndexPath:path animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        printf("COL_SELECT selected=%ld\n", (long)self.collection.indexPathsForSelectedItems.firstObject.item);
        [self cellGeometry:0 item:14];
        [self.collection deselectItemAtIndexPath:path animated:NO];
        printf("COL_SELECT selected=%lu\n", (unsigned long)self.collection.indexPathsForSelectedItems.count);
        [self cellGeometry:0 item:14];
    } else if (self.step == 4) {                            // scroll positions (vertical layout)
        NSIndexPath *path = [NSIndexPath indexPathForItem:3 inSection:1];
        UICollectionViewScrollPosition positions[] = {UICollectionViewScrollPositionTop, UICollectionViewScrollPositionCenteredVertically,
                                                      UICollectionViewScrollPositionBottom};
        const char *names[] = {"top", "centeredVertically", "bottom"};
        for (int i = 0; i < 3; i++) {
            self.collection.contentOffset = CGPointMake(0, 0);
            [self.collection scrollToItemAtIndexPath:path atScrollPosition:positions[i] animated:NO];
            [self.collection layoutIfNeeded];
            printf("COL_SCROLLTO position=%s offset=%.3f\n", names[i], self.collection.contentOffset.y);
        }
        self.collection.contentOffset = CGPointMake(0, 0);
        [self.collection layoutIfNeeded];
    } else if (self.step == 5) {                            // sizes from the delegate, the layout is invalidated
        self.delegateSizes = YES;
        [self.flow invalidateLayout];
        [self.collection layoutIfNeeded];
        [self state:@"delegate-sizes"];
        for (NSInteger item = 0; item < 5; item++) [self attributes:0 item:item];
        [self cellGeometry:0 item:1];
    }
    self.logCalls = NO;
    printf("COL_AFTER step=%ld\n", (long)self.step);
    self.status.text = [NSString stringWithFormat:@"Done %ld", (long)self.step];
}

#pragma mark - data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.logCalls) printf("COL_SRC numberOfSections\n");
    return 2;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.logCalls) printf("COL_SRC items section=%ld\n", (long)section);
    return section == 0 ? 30 : 10;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCell forIndexPath:indexPath];
    cell.backgroundColor = indexPath.section == 0 ? UIColor.systemBlueColor : UIColor.systemOrangeColor;
    if (self.logCalls) printf("COL_SRC cell path=%ld.%ld\n", (long)indexPath.section, (long)indexPath.item);
    return cell;
}

#pragma mark - delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.logCalls && indexPath.item == 0) printf("COL_DLG size section=%ld\n", (long)indexPath.section);
    return self.delegateSizes ? CGSizeMake(70, 40) : self.flow.itemSize;
}
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.logCalls) printf("COL_DLG will path=%ld.%ld\n", (long)indexPath.section, (long)indexPath.item);
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.logCalls) printf("COL_DLG end path=%ld.%ld\n", (long)indexPath.section, (long)indexPath.item);
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    printf("COL_DLG select path=%ld.%ld selected=%lu\n", (long)indexPath.section, (long)indexPath.item,
           (unsigned long)collectionView.indexPathsForSelectedItems.count);
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    printf("COL_TAP selected=%d background=%s\n", cell.selected, rgba(cell.backgroundColor).UTF8String);
    self.status.text = [NSString stringWithFormat:@"Selected %ld.%ld", (long)indexPath.section, (long)indexPath.item];
}

@end
