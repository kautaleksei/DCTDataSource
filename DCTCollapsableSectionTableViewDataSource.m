/*
 DCTCollapsableSectionTableViewDataSource.m
 DCTTableViewDataSources
 
 Created by Daniel Tull on 30.06.2011.
 
 
 
 Copyright (c) 2011 Daniel Tull. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DCTCollapsableSectionTableViewDataSource.h"
#import "DCTParentTableViewDataSource.h"
#import "DCTTableViewCell.h"
#import "UITableView+DCTTableViewDataSources.h"
#import <QuartzCore/QuartzCore.h>
#import "DCTObjectTableViewDataSource.h"
#import "DCTSplitTableViewDataSource.h"



@implementation DCTCollapsableSectionTableViewDataSourceHeader {
	__strong NSString *title;
	BOOL open;
	BOOL empty;
}
@synthesize title;
@synthesize open;
@synthesize empty;
- (id)initWithTitle:(NSString *)aTitle open:(BOOL)isOpen empty:(BOOL)isEmpty {
	
	if (!(self = [super init])) return nil;
	
	title = [aTitle copy];
	open = isOpen;
	empty = isEmpty;
	
	return self;
}
@end








@interface DCTCollapsableSectionTableViewDataSourceHeaderTableViewCell : DCTTableViewCell
@end
@implementation DCTCollapsableSectionTableViewDataSourceHeaderTableViewCell
- (void)configureWithObject:(DCTCollapsableSectionTableViewDataSourceHeader *)object {
	
	self.textLabel.text = object.title;
	
	if (object.empty) {
		
		self.textLabel.textColor = [UIColor lightGrayColor];
		self.accessoryView = nil;
		self.accessoryType = UITableViewCellAccessoryNone;
		
	} else {
		
		UIImage *image = [UIImage imageNamed:@"DCTCollapsableSectionTableViewDataSourceDisclosureIndicator.png"];
		UIImageView *iv = [[UIImageView alloc] initWithImage:image];
		iv.highlightedImage = [UIImage imageNamed:@"DCTCollapsableSectionTableViewDataSourceDisclosureIndicatorHighlighted.png"];
		
		self.accessoryView = iv;
		self.textLabel.textColor = [UIColor blackColor];
		
		self.accessoryView.layer.transform = CATransform3DMakeRotation(object.open ? (CGFloat)M_PI : 0.0f, 0.0f, 0.0f, 1.0f);
	}	
	
	self.selectionStyle = UITableViewCellSelectionStyleBlue;
}
@end















@interface DCTCollapsableSectionTableViewDataSource ()

- (IBAction)dctInternal_titleTapped:(UITapGestureRecognizer *)sender;
- (void)dctInternal_headerCellWillBeReused:(NSNotification *)notification;
- (NSArray *)dctInternal_tableViewIndexPathsForCollapsableCellsIndexPathEnumator:(void (^)(NSIndexPath *))block;
- (NSIndexPath *)dctInternal_headerTableViewIndexPath;
- (void)dctInternal_setOpened;
- (void)dctInternal_setClosed;

- (void)dctInternal_headerCheck;
- (BOOL)dctInternal_childTableViewDataSourceCurrentlyHasCells;

- (void)dctInternal_setSplitChild:(id<DCTTableViewDataSource>)dataSource;

@end

@implementation DCTCollapsableSectionTableViewDataSource {
	__strong NSString *tableViewCellIdentifier;
	__strong UITableViewCell *headerCell;
	BOOL childTableViewDataSourceHasCells;
	BOOL tableViewHasSetup;
	
	__strong DCTSplitTableViewDataSource *splitDataSource;
	__strong DCTObjectTableViewDataSource *headerDataSource;
}

@synthesize childTableViewDataSource;
@synthesize title;
@synthesize open;
@synthesize titleCellClass;

#pragma mark - NSObject

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:DCTTableViewCellWillBeReusedNotification object:headerCell];
}

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	splitDataSource = [[DCTSplitTableViewDataSource alloc] init];
	splitDataSource.type = DCTSplitTableViewDataSourceTypeRow;
	splitDataSource.parent = self;
	
	headerDataSource = [[DCTObjectTableViewDataSource alloc] init];
	headerDataSource.cellClass = [DCTCollapsableSectionTableViewDataSourceHeaderTableViewCell class];
	
	[splitDataSource addChildTableViewDataSource:headerDataSource];
	
	return self;
}

#pragma mark - DCTCollapsableSectionTableViewDataSource

- (void)setChildTableViewDataSource:(id<DCTTableViewDataSource>)ds {
	
	if (childTableViewDataSource == ds) return;
	
	childTableViewDataSource = ds;
	
	if (self.open && ds) [self dctInternal_setSplitChild:ds];
	
	[self dctInternal_headerCheck];
}

#pragma mark - DCTTableViewDataSource

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.row == 0) 
		return [[DCTCollapsableSectionTableViewDataSourceHeader alloc] initWithTitle:self.title open:self.open empty:![self dctInternal_childTableViewDataSourceCurrentlyHasCells]];
	
	return [super objectAtIndexPath:indexPath];
}

#pragma mark - DCTParentTableViewDataSource

- (NSArray *)childTableViewDataSources {
	return [NSArray arrayWithObject:splitDataSource];
}

- (NSIndexPath *)convertIndexPath:(NSIndexPath *)indexPath fromChildTableViewDataSource:(id<DCTTableViewDataSource>)dataSource {
	NSAssert(dataSource == splitDataSource, @"dataSource should be the splitDataSource");
	return indexPath;
}

- (NSIndexPath *)convertIndexPath:(NSIndexPath *)indexPath toChildTableViewDataSource:(id<DCTTableViewDataSource>)dataSource {
	NSAssert(dataSource == splitDataSource, @"dataSource should be the splitDataSource");
	return indexPath;
}

- (NSInteger)convertSection:(NSInteger)section fromChildTableViewDataSource:(id<DCTTableViewDataSource>)dataSource {
	NSAssert(dataSource == splitDataSource, @"dataSource should be the splitDataSource");
	return section;
}

- (NSInteger)convertSection:(NSInteger)section toChildTableViewDataSource:(id<DCTTableViewDataSource>)dataSource {	
	NSAssert(dataSource == splitDataSource, @"dataSource should be the splitDataSource");
	return section;
}

- (id<DCTTableViewDataSource>)childTableViewDataSourceForSection:(NSInteger)section {
	return splitDataSource;
}

- (id<DCTTableViewDataSource>)childTableViewDataSourceForIndexPath:(NSIndexPath *)indexPath {
	return splitDataSource;
}

- (BOOL)childTableViewDataSourceShouldUpdateCells:(id<DCTTableViewDataSource>)dataSource {
	
	[self performSelector:@selector(dctInternal_headerCheck) withObject:nil afterDelay:0.01];
	
	if (!self.open) return NO;
	
	if (self.parent == nil) return YES;
	
	return [self.parent childTableViewDataSourceShouldUpdateCells:self];	
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	tableViewHasSetup = YES;
	
	if (indexPath.row == 0)
		headerDataSource.object = [self objectAtIndexPath:indexPath];
	
	UITableViewCell *cell = [super tableView:tv cellForRowAtIndexPath:indexPath];
	
	if (indexPath.row == 0) {
		
		UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dctInternal_titleTapped:)]; 
		[cell addGestureRecognizer:gr];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:DCTTableViewCellWillBeReusedNotification object:headerCell];		
		headerCell = cell;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dctInternal_headerCellWillBeReused:) name:DCTTableViewCellWillBeReusedNotification object:headerCell];
	}
	
	return cell;
}

- (void)dctInternal_headerCellWillBeReused:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:DCTTableViewCellWillBeReusedNotification object:headerCell];
	headerCell = nil;
}

- (IBAction)dctInternal_titleTapped:(UITapGestureRecognizer *)sender {
	self.open = !self.open;
}

- (NSArray *)dctInternal_tableViewIndexPathsForCollapsableCellsIndexPathEnumator:(void (^)(NSIndexPath *))block {
	
	NSInteger numberOfRows = [self.childTableViewDataSource tableView:self.tableView numberOfRowsInSection:0];
	
	if (numberOfRows == 0) return nil;
	
	childTableViewDataSourceHasCells = YES;
	
	NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:numberOfRows];
	
	for (NSInteger i = 0; i < numberOfRows; i++) {
		NSIndexPath *ip = [NSIndexPath indexPathForRow:i inSection:0];
		
		if (block) block(ip);
		
		ip = [self.tableView dct_convertIndexPath:ip fromChildTableViewDataSource:self.childTableViewDataSource];
		[indexPaths addObject:ip];
	}
	
	return [indexPaths copy];
}

- (NSIndexPath *)dctInternal_headerTableViewIndexPath {
	NSIndexPath *headerIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	return [self.tableView dct_convertIndexPath:headerIndexPath fromChildTableViewDataSource:self];
}

- (void)dctInternal_setSplitChild:(id<DCTTableViewDataSource>)dataSource {
	NSArray *children = splitDataSource.childTableViewDataSources;
	if ([children count] > 1) [splitDataSource removeChildTableViewDataSource:[children lastObject]];
	
	[splitDataSource addChildTableViewDataSource:self.childTableViewDataSource];
}

- (void)dctInternal_setOpened {
	
	[self dctInternal_setSplitChild:self.childTableViewDataSource];
	
	__block CGFloat totalCellHeight = headerCell.bounds.size.height;
	CGFloat tableViewHeight = self.tableView.bounds.size.height;
	
	// If it's grouped we need room for the space between sections.
	if (self.tableView.style == UITableViewStyleGrouped)
		tableViewHeight -= 20.0f;
	
	NSArray *indexPaths = [self dctInternal_tableViewIndexPathsForCollapsableCellsIndexPathEnumator:^(NSIndexPath *ip) {
		
		if (totalCellHeight < tableViewHeight) { // Add this check so we can reduce the amount of calls to heightForObject:width:
			Class cellClass = [self cellClassAtIndexPath:ip];
			totalCellHeight += [cellClass heightForObject:[self objectAtIndexPath:ip] width:self.tableView.bounds.size.width];
		}
		
	}];
	
	if ([indexPaths count] == 0) return;
	
	NSIndexPath *headerIndexPath = [self dctInternal_headerTableViewIndexPath];
	
	if (totalCellHeight < tableViewHeight) {
		[self.tableView scrollToRowAtIndexPath:[indexPaths lastObject] atScrollPosition:UITableViewScrollPositionNone animated:YES];
		[self.tableView scrollToRowAtIndexPath:headerIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
	} else {
		[self.tableView scrollToRowAtIndexPath:headerIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
	}
}

- (void)dctInternal_setClosed {
	
	NSArray *children = splitDataSource.childTableViewDataSources;
	if ([children count] == 1) return;
	
	[splitDataSource removeChildTableViewDataSource:self.childTableViewDataSource];
		
	[self.tableView scrollToRowAtIndexPath:[self dctInternal_headerTableViewIndexPath]
						  atScrollPosition:UITableViewScrollPositionNone
								  animated:YES];
}

- (void)setOpen:(BOOL)aBool {
	
	if (open == aBool) return;
	
	open = aBool;
	
	if (aBool)
		[self dctInternal_setOpened];
	else 
		[self dctInternal_setClosed];
	
	[self.tableView dct_logTableViewDataSources];
	
	UIView *accessoryView = headerCell.accessoryView;
	
	if (!accessoryView) return;
	
	[UIView beginAnimations:@"some" context:nil];
	[UIView setAnimationDuration:0.33];
	accessoryView.layer.transform = CATransform3DMakeRotation(aBool ? (CGFloat)M_PI : 0.0f, 0.0f, 0.0f, 1.0f);
	[UIView commitAnimations];
}

- (void)setTableView:(UITableView *)tv {
	
	if (tv == self.tableView) return;
	
	[super setTableView:tv];
	splitDataSource.tableView = self.tableView;
}

- (void)setTitleCellClass:(Class)cellClass {
	
	if (titleCellClass == cellClass) return;
	
	titleCellClass = cellClass;
	headerDataSource.cellClass = cellClass;
}

- (void)dctInternal_headerCheck {
	
	if (!tableViewHasSetup) return;
	
	if (childTableViewDataSourceHasCells == [self dctInternal_childTableViewDataSourceCurrentlyHasCells]) return;
	
	childTableViewDataSourceHasCells = !childTableViewDataSourceHasCells;
	
	NSIndexPath *header = [self dctInternal_headerTableViewIndexPath];
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:header] withRowAnimation:UITableViewRowAnimationFade];
}

- (BOOL)dctInternal_childTableViewDataSourceCurrentlyHasCells {
	return ([self.childTableViewDataSource tableView:self.tableView numberOfRowsInSection:0] > 0);
}

@end
