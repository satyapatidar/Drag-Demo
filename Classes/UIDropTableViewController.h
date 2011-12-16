#import <UIKit/UIKit.h>

@interface UIDropTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>
{
    UINavigationItem*   srcTableNavItem;
    UINavigationItem*   dstTableNavItem;
	
    UITableView*        srcTableView;
    UITableView*        dstTableView;
    UITableViewCell*    draggedCell;
    UIView*             dropArea;
	
    NSMutableArray*     srcData;
    NSMutableArray*     dstData;
    id                  draggedData;
	
    BOOL            dragFromSource;     // used for reodering
    NSIndexPath*    pathFromDstTable;   // used to reinsert data when reodering fails
}

@property (nonatomic, readonly) NSArray* srcData;
@property (nonatomic, readonly) NSArray* dstData;

- (id)initWithFrame:(CGRect)frame SourceData:(NSArray*)sourceData DestinationData:(NSArray*)destinationData;

- (void)setSrcTableTitle:(NSString*)title;
- (void)setDstTableTitle:(NSString*)title;

@end