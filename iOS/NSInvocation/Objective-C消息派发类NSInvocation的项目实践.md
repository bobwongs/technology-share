# Objective-C消息派发类NSInvocation的项目实践

NSInvocation

类说明

NSInvocation

An Objective-C message rendered as an object.

NSInvocation是一个消息调用类，它包含了所有OC消息的成分：target、selector、参数以及返回值。NSInvocation可以将消息转换成一个对象，消息的每一个参数能够直接设定，而且当一个NSInvocation对象调度时返回值是可以自己设定的。一个NSInvocation对象能够重复的调度不同的目标(target)，而且它的selector也能够设置为另外一个方法签名。

NSMethodSignature

A record of the type information for the return value and parameters of a method.

NSMethodSignature 对象仅仅表示了方法的签名：方法的请求、返回数据的编码。所以在使用 NSMethodSignature 来创建 NSInvocation 对象之后仍需指定消息的接收对象和选择子。

一般使用 NSObject 的实例方法 methodSignatureForSelector: 或者类方法 instanceMethodSignatureForSelector: 来创建对应 selector 的 NSMethodSignature 对象。



用例

步骤

初始化 -> 接受对象以及选择子 - > 参数传递 -> 返回数据

代码示例

```objective-c
/** 给target动态发selector消息，带arguments参数 */
+ (void)invokeWithTarget:(id)target selector:(SEL)selector arguments:(NSArray *)arguments {
    if (!target) return;
	
	// 初始化，接受对象以及选择子
    NSMethodSignature *signature = [[target class] instanceMethodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector = selector;
    
	// 参数传递
    if (arguments && arguments.count > 0) {
        [arguments enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [invocation setArgument:&obj atIndex:2 + idx];
        }];
    }
    
    [invocation invoke];
}
```



项目实践

登录成功后延续登录前的操作事件

```objective-c
/** 检查登录态，在未登录状态，登录成功后，会继续[target selector]的操作 */
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
```



项目实践

月亮小屋、至尊洗衣、洁净无忧



效果演示



项目资源路径