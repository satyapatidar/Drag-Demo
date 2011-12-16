#import "UIDropTableViewController.h"

#define kCellIdentifier @"DropTableCell"
#define kCellHeight 44
#define kNavBarHeight 30


// forward declaration of private helper methods
@interface UIDropTableViewController()

- (void)setupSourceTableWithFrame:(CGRect)frame;
- (void)setupDestinationTableWithFrame:(CGRect)frame;
- (void)initDraggedCellWithCell:(UITableViewCell*)cell AtPoint:(CGPoint)point;

- (void)startDragging:(UIPanGestureRecognizer *)gestureRecognizer;
- (void)startDraggingFromSrcAtPoint:(CGPoint)point;
- (void)startDraggingFromDstAtPoint:(CGPoint)point;

- (void)doDrag:(UIPanGestureRecognizer *)gestureRecognizer;
- (void)stopDragging:(UIPanGestureRecognizer *)gestureRecognizer;

- (UITableViewCell*)srcTableCellForRowAtIndexPath:(NSIndexPath*)indexPath;
- (UITableViewCell*)dstTableCellForRowAtIndexPath:(NSIndexPath*)indexPath;

@end


@implementation UIDropTableViewController

@synthesize srcData, dstData;

#pragma mark -
#pragma mark Public Methods

- (void)setSrcTableTitle:(NSString*)title
{
    srcTableNavItem.title = title;
}

- (void)setDstTableTitle:(NSString*)title
{
    dstTableNavItem.title = title;
}

#pragma mark -
#pragma mark UIViewController

- (id)initWithFrame:(CGRect)frame SourceData:(NSArray*)sourceData DestinationData:(NSArray*)destinationData
{
    self = [super init];
    if (self)
    {
        self.view.clipsToBounds = YES;
        self.view.frame = frame;
        int width = frame.size.width;
        int height = frame.size.height;
		
        // set up data
        srcData = [[NSMutableArray alloc] initWithArray:sourceData];
        dstData = [[NSMutableArray alloc] initWithArray:destinationData];
		
        draggedCell = nil;
        draggedData = nil;
        pathFromDstTable = nil;
		
        // set up views
        [self setupSourceTableWithFrame:CGRectMake(0, 0, width / 2, height)];
        [self setupDestinationTableWithFrame:CGRectMake(width / 2, 0, width / 2, height)];
		
        UIView* separator = [[UIView alloc] initWithFrame:CGRectMake(width / 2, 0, 1, height)];
        separator.backgroundColor = [UIColor blackColor];
        [self.view addSubview:separator];
        [separator release];
		
        // set up gestures
        UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanning:)];
        [self.view addGestureRecognizer:panGesture];
        [panGesture release];
    }
    return self;
}

- (void)dealloc
{
    [srcTableNavItem release];
    [dstTableNavItem release];
	
    [srcTableView release];
    [dstTableView release];
    [dropArea release];
	
    [srcData release];
    [dstData release];
	
    if(draggedCell != nil)
        [draggedCell release];
    if(draggedData != nil)
        [draggedData release];
    if(pathFromDstTable != nil)
        [pathFromDstTable release];
	
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated
{
    [srcTableView reloadData];
    [dstTableView reloadData];
	
    [UIView animateWithDuration:0.2 animations:^
     {
         CGRect frame = dstTableView.frame;
         frame.size.height = kCellHeight * [dstData count];
         dstTableView.frame = frame;
     }];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark -
#pragma mark Helper methods for initialization

- (void)setupSourceTableWithFrame:(CGRect)frame
{
    srcTableNavItem = [[UINavigationItem alloc] init];
    srcTableNavItem.title = @"Source Table";
	
    CGRect navBarFrame = frame;
    navBarFrame.size.height = kNavBarHeight;
	
    UINavigationBar* navigationBar = [[UINavigationBar alloc] initWithFrame:navBarFrame];
    [navigationBar pushNavigationItem:srcTableNavItem animated:false];
    [navigationBar setTintColor:[UIColor lightGrayColor]];
    [self.view addSubview:navigationBar];
    [navigationBar release];
	
    CGRect tableFrame = frame;
    tableFrame.origin.y = kNavBarHeight;
    tableFrame.size.height -= kNavBarHeight;
	
    srcTableView = [[UITableView alloc] initWithFrame:tableFrame];
    [srcTableView setDelegate:self];
    [srcTableView setDataSource:self];
    [self.view addSubview:srcTableView];
}

- (void)setupDestinationTableWithFrame:(CGRect)frame
{
    dstTableNavItem = [[UINavigationItem alloc] init];
    dstTableNavItem.title = @"Destination Table";
	
    CGRect navBarFrame = frame;
    navBarFrame.size.height = kNavBarHeight;
	
    UINavigationBar* navigationBar = [[UINavigationBar alloc] initWithFrame:navBarFrame];
    [navigationBar pushNavigationItem:dstTableNavItem animated:false];
    [navigationBar setTintColor:[UIColor lightGrayColor]];
    [self.view addSubview:navigationBar];
    [navigationBar release];
	
    CGRect dropAreaFrame = frame;
    dropAreaFrame.origin.y = kNavBarHeight;
    dropAreaFrame.size.height -= kNavBarHeight;
	
    dropArea = [[UIView alloc] initWithFrame:dropAreaFrame];
    [dropArea setBackgroundColor:[UIColor grayColor]];
    [self.view addSubview:dropArea];
	
    CGRect contentFrame = dropAreaFrame;
    contentFrame.origin = CGPointMake(0, 0);
	
    UILabel* dropAreaLabel = [[UILabel alloc] initWithFrame:contentFrame];
    dropAreaLabel.backgroundColor = [UIColor clearColor];
    dropAreaLabel.font = [UIFont boldSystemFontOfSize:12];
    dropAreaLabel.textAlignment = UITextAlignmentCenter;
    dropAreaLabel.textColor = [UIColor whiteColor];
    dropAreaLabel.text = @"Drop items here...";
    [dropArea addSubview:dropAreaLabel];
    [dropAreaLabel release];
	
    CGRect tableFrame = contentFrame;
    tableFrame.size.height = kCellHeight * [dstData count];
	
    dstTableView = [[UITableView alloc] initWithFrame:tableFrame];
    //[dstTableView setEditing:YES];
    [dstTableView setDelegate:self];
    [dstTableView setDataSource:self];
    [dropArea addSubview:dstTableView];
}

- (void)initDraggedCellWithCell:(UITableViewCell*)cell AtPoint:(CGPoint)point
{
    // get rid of old cell, if it wasn't disposed already
    if(draggedCell != nil)
    {
        [draggedCell removeFromSuperview];
        [draggedCell release];
        draggedCell = nil;
    }
	
    CGRect frame = CGRectMake(point.x, point.y, cell.frame.size.width, cell.frame.size.height);
	
    draggedCell = [[UITableViewCell alloc] init];
    draggedCell.selectionStyle = UITableViewCellSelectionStyleGray;
    draggedCell.textLabel.text = cell.textLabel.text;
    draggedCell.textLabel.textColor = cell.textLabel.textColor;
    draggedCell.highlighted = YES;
    draggedCell.frame = frame;
    draggedCell.alpha = 0.8;
	
    [self.view addSubview:draggedCell];
}

#pragma mark -
#pragma mark UIGestureRecognizer

- (void)handlePanning:(UIPanGestureRecognizer *)gestureRecognizer
{
    switch ([gestureRecognizer state]) {
        case UIGestureRecognizerStateBegan:
            [self startDragging:gestureRecognizer];
            break;
        case UIGestureRecognizerStateChanged:
            [self doDrag:gestureRecognizer];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self stopDragging:gestureRecognizer];
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark Helper methods for dragging

- (void)startDragging:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint pointInSrc = [gestureRecognizer locationInView:srcTableView];
    CGPoint pointInDst = [gestureRecognizer locationInView:dstTableView];
	
    if([srcTableView pointInside:pointInSrc withEvent:nil])
    {
        [self startDraggingFromSrcAtPoint:pointInSrc];
        dragFromSource = YES;
    }
    else if([dstTableView pointInside:pointInDst withEvent:nil])
    {
        [self startDraggingFromDstAtPoint:pointInDst];
        dragFromSource = NO;
    }
}

- (void)startDraggingFromSrcAtPoint:(CGPoint)point
{
    NSIndexPath* indexPath = [srcTableView indexPathForRowAtPoint:point];
    UITableViewCell* cell = [srcTableView cellForRowAtIndexPath:indexPath];
    if(cell != nil)
    {
        CGPoint origin = cell.frame.origin;
        origin.x += srcTableView.frame.origin.x;
        origin.y += srcTableView.frame.origin.y;
		
        [self initDraggedCellWithCell:cell AtPoint:origin];
        cell.highlighted = NO;
		
        if(draggedData != nil)
        {
            [draggedData release];
            draggedData = nil;
        }
        draggedData = [[srcData objectAtIndex:indexPath.row] retain];
    }
}

- (void)startDraggingFromDstAtPoint:(CGPoint)point
{
    NSIndexPath* indexPath = [dstTableView indexPathForRowAtPoint:point];
    UITableViewCell* cell = [dstTableView cellForRowAtIndexPath:indexPath];
    if(cell != nil)
    {
        CGPoint origin = cell.frame.origin;
        origin.x += dropArea.frame.origin.x;
        origin.y += dropArea.frame.origin.y;
		
        [self initDraggedCellWithCell:cell AtPoint:origin];
        cell.highlighted = NO;
		
        if(draggedData != nil)
        {
            [draggedData release];
            draggedData = nil;
        }
        draggedData = [[dstData objectAtIndex:indexPath.row] retain];
		
        // remove old cell
        [dstData removeObjectAtIndex:indexPath.row];
        [dstTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
        pathFromDstTable = [indexPath retain];
		
        [UIView animateWithDuration:0.2 animations:^
         {
             CGRect frame = dstTableView.frame;
             frame.size.height = kCellHeight * [dstData count];
             dstTableView.frame = frame;
         }];
		
    }
}

- (void)doDrag:(UIPanGestureRecognizer *)gestureRecognizer
{
    if(draggedCell != nil && draggedData != nil)
    {
        CGPoint translation = [gestureRecognizer translationInView:[draggedCell superview]];
		[draggedCell setCenter:CGPointMake([draggedCell center].x + translation.x,
										   [draggedCell center].y + translation.y)];
        [gestureRecognizer setTranslation:CGPointZero inView:[draggedCell superview]];
    }
}

- (void)stopDragging:(UIPanGestureRecognizer *)gestureRecognizer
{
    if(draggedCell != nil && draggedData != nil)
    {
        if([gestureRecognizer state] == UIGestureRecognizerStateEnded
           && [dropArea pointInside:[gestureRecognizer locationInView:dropArea] withEvent:nil])
        {            
            NSIndexPath* indexPath = [dstTableView indexPathForRowAtPoint:[gestureRecognizer locationInView:dstTableView]];
            if(indexPath != nil)
            {
                [dstData insertObject:draggedData atIndex:indexPath.row];
                [dstTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
            }
            else
            {
                [dstData addObject:draggedData];
                [dstTableView reloadData];
            }
        }
        else if(!dragFromSource && pathFromDstTable != nil)
        {
            // insert cell back where it came from
            [dstData insertObject:draggedData atIndex:pathFromDstTable.row];
            [dstTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:pathFromDstTable] withRowAnimation:UITableViewRowAnimationMiddle];
			
            [pathFromDstTable release];
            pathFromDstTable = nil;
        }
		
        [UIView animateWithDuration:0.3 animations:^
         {
             CGRect frame = dstTableView.frame;
             frame.size.height = kCellHeight * [dstData count];
             dstTableView.frame = frame;
         }];
		
        [draggedCell removeFromSuperview];
        [draggedCell release];
        draggedCell = nil;
		
        [draggedData release];
        draggedData = nil;
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    // disable build in reodering functionality
    return NO;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // enable cell deletion for destination table
    if([tableView isEqual:dstTableView] && editingStyle == UITableViewCellEditingStyleDelete)
    {
        [dstData removeObjectAtIndex:indexPath.row];
        [dstTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
        [UIView animateWithDuration:0.2 animations:^
         {
             CGRect frame = dstTableView.frame;
             frame.size.height = kCellHeight * [dstData count];
             dstTableView.frame = frame;
         }];
    }
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    // tell our tables how many rows they will have
    int count = 0;
    if([tableView isEqual:srcTableView])
    {
        count = [srcData count];
    }
    else if([tableView isEqual:dstTableView])
    {
        count = [dstData count];
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* result = nil;
    if([tableView isEqual:srcTableView])
    {
        result = [self srcTableCellForRowAtIndexPath:indexPath];
    }
    else if([tableView isEqual:dstTableView])
    {
        result = [self dstTableCellForRowAtIndexPath:indexPath];
    }
	
    return result;
}

#pragma mark -
#pragma mark Helper methods for table stuff

- (UITableViewCell*)srcTableCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    // tell our source table what kind of cell to use and its title for the given row
    UITableViewCell *cell = [srcTableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:kCellIdentifier] autorelease];
		
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = [UIColor darkGrayColor];
    }
    cell.textLabel.text = [[srcData objectAtIndex:indexPath.row] description];
	
    return cell;
}

- (UITableViewCell*)dstTableCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    // tell our destination table what kind of cell to use and its title for the given row
    UITableViewCell *cell = [dstTableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:kCellIdentifier] autorelease];
		
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = [UIColor darkGrayColor];
    }
    cell.textLabel.text = [[dstData objectAtIndex:indexPath.row] description];
	
    return cell;
}

@end