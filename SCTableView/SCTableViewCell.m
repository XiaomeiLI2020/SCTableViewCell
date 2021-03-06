//
//  SCTableViewCell.m
//  SCTableView
//
//  Created by chen Yuheng on 15/9/13.
//  Copyright (c) 2015年 chen Yuheng. All rights reserved.
//

#import "SCTableViewCell.h"

#define INDEX_X_FOR_DELETING 50.0f
#define SCNotificationExitEditing @"SCNotificationExitEditing"

@interface SCTableViewCell()
{
    BOOL _isMoving;
    BOOL _hasMoved;
}
@property (nonatomic) SCTableViewCellStyle style;

@property (nonatomic, strong) NSMutableArray *rightActionButtons;
@property (nonatomic, strong) NSMutableArray *leftActionButtons;

@property (nonatomic) CGFloat touchBeganPointX;
@property (nonatomic) CGFloat buttonWidth;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSIndexPath *indexPath;
@end

@implementation SCTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier inTableView:(UITableView *)tableView withSCStyle:(SCTableViewCellStyle)sc_style
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self)
    {
        self.style = sc_style;
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.touchBeganPointX = 0.0f;
        self.dragAnimationDuration = 0.2f;
        self.resetAnimationDuration = 0.4f;
        self.buttonWidth = ScreenWidth / 6.0f;
        self.dragAcceleration = 1.14f;
        self.isEditing = NO;
        self.tableView = tableView;
        _isMoving = NO;
        _hasMoved = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ExitEditing:) name:SCNotificationExitEditing object:nil];
        assert([self.tableView isKindOfClass:[UITableView class]]);
    }
    return self;
}

- (void)layoutSubviews
{
    if(_isMoving)
    {
        return;
    }
    [super layoutSubviews];
    [self getSCStyle];
    [self getActionsArray];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

/**
 *  接收到别的cell的通知来取消自己的编辑状态
 *
 *  @param sender NSNotification
 */
- (void)ExitEditing:(id)sender
{
    if([(NSNotification *)sender object] != self)
    {
        if(self.isEditing && !_isMoving)
        {
            [self resetButtonsToOriginPosition];
        }
    }
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Button Actions
- (void)rightButtonPressed:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSInteger index = btn.tag;
    [self actionTrigger:YES index:index];
}

- (void)leftButtonPressed:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSInteger index = btn.tag;
    [self actionTrigger:NO index:index];
}

/**
 *  触发事件的最终汇总出口
 *
 *  @param isRight 是否是右边滑动菜单
 *  @param index   索引
 */
- (void)actionTrigger:(BOOL)isRight index:(NSInteger)index
{
    self.indexPath = [self.tableView indexPathForCell:self];
    
    if(isRight)
    {
        // 判断index是否是最后一个
        if([self.delegate respondsToSelector:@selector(SCTableView:commitActionIndex:forIndexPath:)])
        {
            [self.delegate SCTableView:self.tableView commitActionIndex:index forIndexPath:self.indexPath];
        }
    }
}

#pragma mark - Main Touch processer
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(touches.count == 1)
    {
        for(UITouch *touch in touches)
        {
            if(touch.phase != UITouchPhaseBegan)
            {
                return;
            }
            else
            {
                NSLog(@"begin!");
                switch (self.style) {
                    case SCTableViewCellStyleRight:
                    {
                        if(self.contentView.left == 0.0f)
                        {
                            self.touchBeganPointX = [touch locationInView:self.tableView].x;
                            //当开始编辑的时候，向其他cell发送取消编辑的通知
                            [[NSNotificationCenter defaultCenter] postNotificationName:SCNotificationExitEditing object:self userInfo:nil];
                        }
                        _isMoving = YES;
                    }
                        break;
                    case SCTableViewCellStyleLeft:
                    {
                        
                    }
                        break;
                    case SCTableViewCellStyleBoth:
                    {
                        
                    }
                        break;
                    case SCTableViewCellStyleDefault:
                    {
                        [super touchesBegan:touches withEvent:event];
                    }
                        break;
                    default:
                        break;
                }
            }
        }
    }
    else
    {
        [super touchesBegan:touches withEvent:event];
        return;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(touches.count == 1)
    {
        for(UITouch *touch in touches)
        {
            if(touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled)
            {
                self.tableView.scrollEnabled = YES;
                [super touchesMoved:touches withEvent:event];
                return;
            }
            else if(touch.phase == UITouchPhaseMoved)
            {
                self.tableView.scrollEnabled = NO;
                switch (self.style) {
                    case SCTableViewCellStyleRight:
                    {
                        _hasMoved = YES;
                        _isEditing = YES;
                        CGFloat CurrentXIndex = [touch locationInView:self.tableView].x;
                        CGFloat CurrentYIndex = [touch locationInView:self.tableView].y;
                        NSLog(@"--- (%f,%f) --- %f",CurrentXIndex,CurrentYIndex,self.touchBeganPointX - CurrentXIndex);
                        CGFloat delta = (self.touchBeganPointX - CurrentXIndex) * self.dragAcceleration;
                        [self rightMenuAnimation:delta andCurrentIndexX:CurrentXIndex];
                    }
                        break;
                    case SCTableViewCellStyleLeft:
                    {
                        
                    }
                        break;
                    case SCTableViewCellStyleBoth:
                    {
                        
                    }
                        break;
                    case SCTableViewCellStyleDefault:
                    {
                        [super touchesMoved:touches withEvent:event];
                    }
                    default:
                        break;
                }
            }
            else
            {
                [super touchesMoved:touches withEvent:event];
            }
        }
    }
    else
    {
        [super touchesMoved:touches withEvent:event];
        return;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(touches.count == 1)
    {
        self.tableView.scrollEnabled = YES;
        for(UITouch *touch in touches)
        {
            if(touch.tapCount > 1)
            {
                //双击事件可以由其他recognizer捕获到
                [super touchesEnded:touches withEvent:event];
                return;
            }
            if(touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled)
            {
                CGFloat CurrentXIndex = [touch locationInView:self.tableView].x;
                CGFloat PreviousXIndex = [touch previousLocationInView:self.tableView].x;
                NSLog(@"end ! --(%f)-- %f",CurrentXIndex, PreviousXIndex - CurrentXIndex);
                switch (self.style) {
                    case SCTableViewCellStyleRight:
                    {
                        [self rightMenuAnimationEndpreviousIndex:PreviousXIndex currentIndex:CurrentXIndex];
                    }
                        break;
                    case SCTableViewCellStyleLeft:
                    {
                        
                    }
                        break;
                    case SCTableViewCellStyleBoth:
                    {
                        
                    }
                        break;
                    case SCTableViewCellStyleDefault:
                    {
                        if(fabs(PreviousXIndex - CurrentXIndex) <= 10.0f)
                        {
                            if(!_isEditing)
                            {
                                // 由于把整个手势的检测判断都覆盖了，这里需要把系统的didSelect也重新实现一下
                                self.indexPath = [self.tableView indexPathForCell:self];
                                [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:self.indexPath];
                                return;
                            }
                        }
                    }
                    default:
                        break;
                }
            }
        }
    }
    else
    {
        [super touchesEnded:touches withEvent:event];
        return;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(touches.count == 1)
    {
        self.tableView.scrollEnabled = YES;
        for(UITouch *touch in touches)
        {
            if(touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled)
            {
                NSLog(@"cancelled!");
                CGFloat CurrentXIndex = [touch locationInView:self.tableView].x;
                switch (self.style) {
                    case SCTableViewCellStyleRight:
                    {
                        if(CurrentXIndex > ScreenWidth/2.0f)
                        {
                            [self resetButtonsToOriginPosition];
                        }
                        else
                        {
                            [self resetButtonsToDisplayPosition];
                        }
                    }
                        break;
                    case SCTableViewCellStyleLeft:
                    {
                        
                    }
                        break;
                    case SCTableViewCellStyleBoth:
                    {
                        
                    }
                        break;
                    case SCTableViewCellStyleDefault:
                    {
                        [super touchesCancelled:touches withEvent:event];
                    }
                        break;
                    default:
                        break;
                }
            }
        }
    }
    else
    {
        [super touchesCancelled:touches withEvent:event];
        return;
    }
}

#pragma mark - Reset methods
/**
 *  将Action重置到原始区域，即不可见区域
 */
- (void)resetButtonsToOriginPosition
{
    switch (self.style) {
        case SCTableViewCellStyleRight:
        {
            [UIView animateWithDuration:self.resetAnimationDuration animations:^{
                self.contentView.frame = CGRectMake(0.0f, self.contentView.top, self.contentView.width, self.contentView.height);
                for(UIButton *button in self.rightActionButtons)
                {
                    button.frame = CGRectMake(ScreenWidth, 0.0f, self.buttonWidth, self.height);
                }
            } completion:^(BOOL finished) {
                _isMoving = NO;
                _hasMoved = NO;
                _isEditing = NO;
            }];
        }
            break;
        case SCTableViewCellStyleLeft:
        {
            
        }
            break;
        case SCTableViewCellStyleBoth:
        {
            
        }
            break;
        case SCTableViewCellStyleDefault:
        default:
            break;
    }
}

/**
 *  将Action重置到应该显示的区域，Both模式下可能需要引入当前编辑模式
 */
- (void)resetButtonsToDisplayPosition
{
    switch (self.style) {
        case SCTableViewCellStyleRight:
        {
            [UIView animateWithDuration:self.resetAnimationDuration animations:^{
                self.contentView.frame = CGRectMake(- ScreenWidth/2.0f, self.contentView.top, self.contentView.width, self.contentView.height);
                CGFloat t_start = ScreenWidth / 2.0f;
                for(UIButton *button in self.rightActionButtons)
                {
                    button.frame = CGRectMake(t_start, 0.0f, self.buttonWidth, self.height);
                    t_start += self.buttonWidth;
                }
            } completion:^(BOOL finished) {
                _isMoving = NO;
                _hasMoved = NO;
                _isEditing = YES;
            }];
        }
            break;
        case SCTableViewCellStyleLeft:
        {
            
        }
            break;
        case SCTableViewCellStyleBoth:
        {
            
        }
            break;
        case SCTableViewCellStyleDefault:
        default:
            break;
    }
}

#pragma mark - Delegate method to get data
- (void)getActionsArray
{
    self.indexPath = [self.tableView indexPathForCell:self];
    switch (self.style) {
        case SCTableViewCellStyleRight:
        {
            if([self.delegate respondsToSelector:@selector(SCTableView:rightEditActionsForRowAtIndexPath:)])
            {
                NSLog(@"get Actions!");
                self.rightActionButtons = [[self.delegate SCTableView:self.tableView rightEditActionsForRowAtIndexPath:self.indexPath] mutableCopy];
                self.buttonWidth = (self.width / 2.0f)/ self.rightActionButtons.count;
                
                for(UIButton *button in self.rightActionButtons)
                {
                    button.frame = CGRectMake(ScreenWidth, 0.0f, self.buttonWidth, self.height);
                    button.tag = [self.rightActionButtons indexOfObject:button];
                    [button addTarget:self action:@selector(rightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                    [self addSubview:button];
                }
            }
        }
            break;
        case SCTableViewCellStyleLeft:
        {
            if([self.delegate respondsToSelector:@selector(SCTableView:leftEditActionsForRowAtIndexPath:)])
            {
                self.leftActionButtons = [[self.delegate SCTableView:self.tableView leftEditActionsForRowAtIndexPath:self.indexPath] mutableCopy];
            }
        }
            break;
        case SCTableViewCellStyleBoth:
        {
            if([self.delegate respondsToSelector:@selector(SCTableView:rightEditActionsForRowAtIndexPath:)])
            {
                self.rightActionButtons = [[self.delegate SCTableView:self.tableView rightEditActionsForRowAtIndexPath:self.indexPath] mutableCopy];
            }
            if([self.delegate respondsToSelector:@selector(SCTableView:leftEditActionsForRowAtIndexPath:)])
            {
                self.leftActionButtons = [[self.delegate SCTableView:self.tableView leftEditActionsForRowAtIndexPath:self.indexPath] mutableCopy];
            }
        }
            break;
        case SCTableViewCellStyleDefault:
        default:
            break;
    }
}

- (void)getSCStyle
{
    self.indexPath = [self.tableView indexPathForCell:self];
    if([self.delegate respondsToSelector:@selector(SCTableView:editStyleForRowAtIndexPath:)])
    {
        self.style = [self.delegate SCTableView:self.tableView editStyleForRowAtIndexPath:self.indexPath];
    }
}

#pragma mark - Dragging processing methods
/**
 *  右侧菜单滑动显示的过程代码
 *
 *  @param delta
 *  @param CurrentXIndex
 */
- (void)rightMenuAnimation:(CGFloat)delta andCurrentIndexX:(CGFloat)CurrentXIndex
{
    if(delta > 0)
    {
        if(delta > ScreenWidth / 2.0f)
        {
            if(CurrentXIndex < INDEX_X_FOR_DELETING)
            {
                // 最后一个button需要变宽度了
                if(delta > ScreenWidth / 2.0f)
                {
                    CGFloat t_delta = (delta - (ScreenWidth / 2.0f))/ self.rightActionButtons.count;
                    [UIView animateWithDuration:self.dragAnimationDuration animations:^{
                        self.contentView.frame = CGRectMake(CurrentXIndex-self.width, self.contentView.top, self.contentView.width, self.contentView.height);
                        
                        CGFloat p_delta = delta;
                        for(NSInteger i=0;i<self.rightActionButtons.count-1;i++)
                        {
                            UIButton *button = [self.rightActionButtons objectAtIndex:i];
                            button.frame = CGRectMake(self.width - p_delta, 0.0f, self.buttonWidth + t_delta, self.height);
                            p_delta -= delta / self.rightActionButtons.count;
                        }
                        
                        CGFloat t_x = CurrentXIndex;
                        if([(UIButton *)[self.rightActionButtons objectAtIndex:0] left] < CurrentXIndex)
                        {
                            t_x = [(UIButton *)[self.rightActionButtons objectAtIndex:0] left];
                        }
                        UIButton *lastOne = [self.rightActionButtons lastObject];
                        lastOne.frame = CGRectMake(t_x, 0.0f, self.width - t_x, self.height);
                    }];
                }
                else
                {
                    // 位移量超过0像素才移动，这是保证只有右边的区域会出现
                    [UIView animateWithDuration:self.dragAnimationDuration animations:^{
                        self.contentView.frame = CGRectMake(CurrentXIndex-self.width, self.contentView.top, self.contentView.width, self.contentView.height);
                        
                        CGFloat t_delta = delta;
                        for(NSInteger i=0;i<self.rightActionButtons.count-1;i++)
                        {
                            UIButton *button = [self.rightActionButtons objectAtIndex:i];
                            button.frame = CGRectMake(self.width - t_delta, 0.0f, self.buttonWidth, self.height);
                            t_delta -= delta / self.rightActionButtons.count;
                        }
                        CGFloat t_x = CurrentXIndex;
                        if([(UIButton *)[self.rightActionButtons objectAtIndex:0] left] < CurrentXIndex)
                        {
                            t_x = [(UIButton *)[self.rightActionButtons objectAtIndex:0] left];
                        }
                        UIButton *lastOne = [self.rightActionButtons lastObject];
                        lastOne.frame = CGRectMake(t_x, 0.0f,self.width - t_x, self.height);
                    }];
                }
            }
            else
            {
                CGFloat t_delta = (delta - (ScreenWidth / 2.0f))/ self.rightActionButtons.count;
                [UIView animateWithDuration:self.dragAnimationDuration animations:^{
                    self.contentView.frame = CGRectMake(-delta, self.contentView.top, self.contentView.width, self.contentView.height);
                    
                    CGFloat p_delta = delta;
                    for(UIButton *button in self.rightActionButtons)
                    {
                        button.frame = CGRectMake(self.width - p_delta, 0.0f, self.buttonWidth + t_delta, self.height);
                        p_delta -= delta / self.rightActionButtons.count;
                    }
                }];
            }
        }
        else
        {
            // 位移量超过0像素才移动，这是保证只有右边的区域会出现
            [UIView animateWithDuration:self.dragAnimationDuration animations:^{
                self.contentView.frame = CGRectMake(- delta, self.contentView.top, self.contentView.width, self.contentView.height);
                
                CGFloat t_delta = delta;
                for(UIButton *button in self.rightActionButtons)
                {
                    button.frame = CGRectMake(self.width - t_delta, 0.0f, self.buttonWidth, self.height);
                    t_delta -= delta / self.rightActionButtons.count;
                }
            }];
        }
    }
}

/**
 *  右侧菜单显示滑动结束
 *
 *  @param PreviousXIndex
 *  @param CurrentXIndex
 */
- (void)rightMenuAnimationEndpreviousIndex:(CGFloat)PreviousXIndex currentIndex:(CGFloat)CurrentXIndex
{
    // 判断特殊的删除情况
    if([(UIButton *)self.rightActionButtons.lastObject width] > self.buttonWidth * self.rightActionButtons.count)
    {
        [self actionTrigger:YES index:2];
        return;
    }
    
    if(fabs(PreviousXIndex - CurrentXIndex) <= 3.0f)
    {
        if(!_isEditing)
        {
            // 由于把整个手势的检测判断都覆盖了，这里需要把系统的didSelect也重新实现一下
            self.indexPath = [self.tableView indexPathForCell:self];
            [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:self.indexPath];
            return;
        }
        
        // 并没有怎么移动
        if(self.contentView.left < - ScreenWidth / 2.0f)
        {
            // 需要还原到显示的位置
            if(!_hasMoved)
            {
                return;
            }
            [self resetButtonsToDisplayPosition];
        }
        else
        {
            // 需要还原到初始位置
            [self resetButtonsToOriginPosition];
        }
    }
    else
    {
        if(CurrentXIndex > ScreenWidth / 2.0f)
        {
            // 需要还原到初始位置
            [self resetButtonsToOriginPosition];
        }
        else
        {
            // 需要还原到显示的位置
            if(!_hasMoved)
            {
                return;
            }
            [self resetButtonsToDisplayPosition];
        }
    }
}
@end
