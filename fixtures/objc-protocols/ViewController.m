#import "ViewController.h"
#import <objc/runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

@protocol DetachedGrandparent @end
@protocol DetachedParent <DetachedGrandparent> @end
@protocol DetachedRoot <DetachedParent> @end
@protocol UnusedDetached @end
@interface ProtocolHolder : NSObject <DetachedRoot>
- (NSInteger)localValue;
- (NSInteger)localOther;
+ (NSInteger)factoryValue;
@end
@implementation ProtocolHolder
- (NSInteger)localValue { return 7; }
- (NSInteger)localOther { return 9; }
+ (NSInteger)factoryValue { return 11; }
@end
@interface ProtocolHolder (CategoryProbe)
- (NSInteger)categoryValue;
@end
@implementation ProtocolHolder (CategoryProbe)
- (NSInteger)categoryValue { return 13; }
@end
typedef struct { uint64_t first, second, third; } ForwardLarge;
@protocol ForwardProbe
- (NSInteger)mixA:(NSInteger)a b:(NSInteger)b c:(NSInteger)c d:(NSInteger)d
                 e:(NSInteger)e f:(NSInteger)f g:(NSInteger)g;
- (double)doubleValue:(double)value;
- (ForwardLarge)largeValue:(uint64_t)value;
@end
@interface ForwardSink : NSObject <ForwardProbe>
+ (NSInteger)classValue;
@end
@implementation ForwardSink
- (NSInteger)mixA:(NSInteger)a b:(NSInteger)b c:(NSInteger)c d:(NSInteger)d
                 e:(NSInteger)e f:(NSInteger)f g:(NSInteger)g {
    return a + 2*b + 3*c + 4*d + 5*e + 6*f + 7*g;
}
- (double)doubleValue:(double)value { return value * 2.0; }
- (ForwardLarge)largeValue:(uint64_t)value { return (ForwardLarge){value, value+1, value+2}; }
+ (NSInteger)classValue { return 17; }
@end
@interface FastProxy : NSObject { @public id _forwardTarget; }
@end
@implementation FastProxy
- (id)forwardingTargetForSelector:(SEL)selector { return _forwardTarget; }
+ (id)forwardingTargetForSelector:(SEL)selector { return ForwardSink.class; }
@end
static unsigned int instanceResolutions, classResolutions, negativeResolutions;
static NSInteger dynamicInstance(id receiver, SEL selector, NSInteger value) { return value + 5; }
static NSInteger dynamicClass(id receiver, SEL selector, NSInteger value) { return value + 9; }
static NSInteger unrelatedMethod(id receiver, SEL selector) { return 1; }
@interface DynamicResolved : NSObject { @public id _forwardTarget; }
@end
@interface DynamicResolved (DynamicMethods)
- (NSInteger)lateValue:(NSInteger)value;
+ (NSInteger)lateClassValue:(NSInteger)value;
@end
@implementation DynamicResolved
+ (BOOL)resolveInstanceMethod:(SEL)selector {
    if (selector == @selector(lateValue:)) {
        instanceResolutions++;
        return class_addMethod(self, selector, (IMP)dynamicInstance, "q@:q");
    }
    if (selector == @selector(doubleValue:)) negativeResolutions++;
    return NO;
}
+ (BOOL)resolveClassMethod:(SEL)selector {
    if (selector == @selector(lateClassValue:)) {
        classResolutions++;
        return class_addMethod(object_getClass(self), selector, (IMP)dynamicClass, "q@:q");
    }
    return NO;
}
- (id)forwardingTargetForSelector:(SEL)selector { return _forwardTarget; }
@end
static NSMutableArray<NSString *> *failedChecks;
static BOOL check(const char *name, BOOL value) {
    printf("D1P %s=%d\n", name, value ? 1 : 0);
    if (!value) [failedChecks addObject:@(name)];
    return value;
}
static BOOL probe(void) {
    failedChecks = [NSMutableArray array];
    Protocol *root = @protocol(DetachedRoot), *parent = @protocol(DetachedParent);
    Protocol *grand = @protocol(DetachedGrandparent), *unused = @protocol(UnusedDetached);
    BOOL ok = check("standalone_lookup", objc_getProtocol("UnusedDetached") == unused);
    ok &= check("protocol_name", strcmp(protocol_getName(unused), "UnusedDetached") == 0);
    ok &= check("adopts_transitive", protocol_conformsToProtocol(root, grand));
    ok &= check("adoption_direction", !protocol_conformsToProtocol(grand, root));
    ok &= check("duplicate_allocate", objc_allocateProtocol("UnusedDetached") == nil);
    unsigned int count = 999;
    Protocol * __unsafe_unretained *list = protocol_copyProtocolList(root, &count);
    ok &= check("direct_parent_only", count == 1 && list && list[0] == parent);
    ok &= check("parent_terminator", list && list[count] == NULL); free(list);
    list = protocol_copyProtocolList(grand, &count);
    ok &= check("leaf_empty", list == NULL && count == 0); free(list);
    list = class_copyProtocolList(ProtocolHolder.class, &count);
    ok &= check("class_direct_only", count == 1 && list && list[0] == root);
    ok &= check("class_terminator", list && list[count] == NULL); free(list);
    list = objc_copyProtocolList(&count);
    BOOL found = NO;
    for (unsigned int n = 0; n < count; n++) if (list[n] == unused) found = YES;
    ok &= check("global_contains_standalone", found);
    ok &= check("global_terminator", list && list[count] == NULL); free(list);
    Method *methods = class_copyMethodList(ProtocolHolder.class, &count);
    BOOL ownValue = NO, ownOther = NO, categoryValue = NO;
    for (unsigned int n = 0; n < count; n++) {
        const char *name = sel_getName(method_getName(methods[n]));
        if (strcmp(name, "localValue") == 0) ownValue = YES;
        if (strcmp(name, "localOther") == 0) ownOther = YES;
        if (strcmp(name, "categoryValue") == 0) categoryValue = YES;
    }
    ok &= check("own_methods_only", count == 3 && ownValue && ownOther && categoryValue);
    ok &= check("category_precedes_base", count == 3 && methods &&
        strcmp(sel_getName(method_getName(methods[0])), "categoryValue") == 0);
    ok &= check("method_terminator", methods && methods[count] == NULL); free(methods);
    Class meta = object_getClass(ProtocolHolder.class);
    methods = class_copyMethodList(meta, &count);
    ok &= check("metaclass_methods", count == 1 && methods &&
        strcmp(sel_getName(method_getName(methods[0])), "factoryValue") == 0);
    ok &= check("metaclass_terminator", methods && methods[count] == NULL); free(methods);
    Method first = class_getInstanceMethod(ProtocolHolder.class, @selector(localValue));
    Method second = class_getInstanceMethod(ProtocolHolder.class, @selector(localOther));
    IMP original = method_getImplementation(first), other = method_getImplementation(second);
    const char *types = method_getTypeEncoding(first);
    method_exchangeImplementations(first, second);
    ok &= check("stable_swizzled_handle", class_getInstanceMethod(ProtocolHolder.class, @selector(localValue)) == first &&
        method_getImplementation(first) == other);
    IMP previous = class_replaceMethod(ProtocolHolder.class, @selector(localValue), original, "v@:");
    ok &= check("replace_imp", previous == other && method_getImplementation(first) == original);
    ok &= check("replace_preserves_encoding", strcmp(method_getTypeEncoding(first), types) == 0);
    ForwardSink *sink = [ForwardSink new];
    FastProxy *proxy = [FastProxy new], *intermediate = [FastProxy new];
    proxy->_forwardTarget = intermediate; intermediate->_forwardTarget = sink;
    id<ForwardProbe> forwarded = (id<ForwardProbe>)proxy;
    ok &= check("forward_register_stack", [forwarded mixA:1 b:2 c:3 d:4 e:5 f:6 g:7] == 140);
    ok &= check("forward_double", [forwarded doubleValue:3.25] == 6.5);
    ForwardLarge large = [forwarded largeValue:41];
    ok &= check("forward_indirect_result", large.first == 41 && large.second == 42 && large.third == 43);
    ok &= check("forward_class_method", [(id)FastProxy.class classValue] == 17);
    DynamicResolved *resolved = [DynamicResolved new]; resolved->_forwardTarget = sink;
    ok &= check("resolve_instance", [resolved lateValue:31] == 36 && [resolved lateValue:41] == 46 && instanceResolutions == 1);
    ok &= check("resolve_class", [DynamicResolved lateClassValue:31] == 40 &&
        [DynamicResolved lateClassValue:41] == 50 && classResolutions == 1);
    id<ForwardProbe> unresolved = (id<ForwardProbe>)resolved;
    ok &= check("resolve_negative_forward", [unresolved doubleValue:2.0] == 4.0 &&
        [unresolved doubleValue:3.0] == 6.0);
    printf("D1P negativeResolutions=%u\n", negativeResolutions);
    class_addMethod(DynamicResolved.class, sel_registerName("unrelated"), (IMP)unrelatedMethod, "q@:");
    ok &= check("resolve_after_add", [unresolved doubleValue:4.0] == 8.0);
    printf("D1P negativeResolutionsAfterAdd=%u\n", negativeResolutions);
    printf("D1P %s\n", ok ? "PROTOCOL_OK" : "PROTOCOL_FAILED");
    return ok;
}
@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad]; self.view.backgroundColor = UIColor.whiteColor;
    BOOL ok = probe();
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 140, 340, 60)];
    label.text = ok ? @"PROTOCOL_OK" : @"PROTOCOL_FAILED";
    label.accessibilityIdentifier = @"protocol.status";
    [self.view addSubview:label];
    UILabel *details = [[UILabel alloc] initWithFrame:CGRectMake(20, 210, 340, 60)];
    details.text = failedChecks.count ? [failedChecks componentsJoinedByString:@","] : @"none";
    details.accessibilityIdentifier = @"protocol.details";
    [self.view addSubview:details];
}
@end
