//
//  BMContinueOperationManager.m
//  BMWash
//
//  Created by BobWong on 2017/8/25.
//  Copyright © 2017年 月亮小屋（中国）有限公司. All rights reserved.
//

#import "BMContinueOperationManager.h"
#import <MJExtension.h>

@interface BMContinueOperationManager ()

// 上一次触发登录相关参数
@property (nonatomic, strong) id lastTarget;  ///< 触发登录的target
@property (nonatomic, assign) SEL lastSelector;  ///< 触发登录所在的selector
@property (nonatomic, strong) NSArray *lastArguments;  ///< 触发登录的selector参数

@end

@implementation BMContinueOperationManager

#pragma mark - Life Cycle

+ (instancetype)sharedManager {
    static id sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (BOOL)checkValidLoginAndContinueOperationAfterNextLogin {
    if ([BMLoginUserManager sharedInstance].loginedUserModel.loginStatus != BMUserLoginStatusLoginNormal) {
        [[NSNotificationCenter defaultCenter] postNotificationName:BMNotificationRequestLogin object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(continueOperation) name:BMNotificationLoginOK object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAddedObserverAndResetData) name:BMNotificationLoginCancel object:nil];
        return NO;
    }
    return YES;
}

- (void)continueOperation {
    [self removeAddedObserver];
    [self routeWithType:self.type urlString:self.urlString code:self.code parameters:self.params];
    [self resetData];
}

- (BOOL)checkLoginStatusContinueOperationWithTarget:(id)target selector:(SEL)selector arguments:(NSArray *)arguments {
    if ([BMLoginUserManager sharedInstance].loginedUserModel.loginStatus != BMUserLoginStatusLoginNormal) {
        _lastTarget = target;
        _lastSelector = selector;
        _lastArguments = arguments;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BMNotificationRequestLogin object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(continueLastOperation) name:BMNotificationLoginOK object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAddedObserverAndResetData) name:BMNotificationLoginCancel object:nil];
        return NO;
    }
    return YES;
}

/** 继续上一次用户本地点击，需要登录的操作 */
- (void)continueLastOperation {
    [self removeAddedObserver];
    [[self class] invokeWithTarget:_lastTarget selector:_lastSelector arguments:_lastArguments];
    [self resetData];
}


- (void)removeAddedObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)resetData {
    _type = nil;
    _urlString = nil;
    _code = nil;
    _params = nil;
    
    _lastTarget = nil;
    _lastSelector = NULL;
    _lastArguments = nil;
    
    _targetVC = nil;
}

- (void)removeAddedObserverAndResetData {
    [self removeAddedObserver];
    [self resetData];
}

/** 给target动态发selector消息，带arguments参数 */
+ (void)invokeWithTarget:(id)target selector:(SEL)selector arguments:(NSArray *)arguments {
    if (!target) return;
    NSMethodSignature *signature = [[target class] instanceMethodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector = selector;
    
    if (arguments && arguments.count > 0) {
        [arguments enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [invocation setArgument:&obj atIndex:2 + idx];
        }];
    }
    
    [invocation invoke];
}

@end
