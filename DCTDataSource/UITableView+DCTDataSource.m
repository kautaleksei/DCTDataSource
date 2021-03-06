/*
 UITableView+DCTDataSource.m
 DCTDataSource
 
 Created by Daniel Tull on 08.10.2011.
 
 
 
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

#import "UITableView+DCTDataSource.h"
#import "DCTParentDataSource.h"
#import "DCTDataSource.h"


@interface DCTDataSource (DCTDataSource)
- (void)dct_logTableViewDataSourcesLevel:(NSInteger)level;
@end
@implementation DCTDataSource (DCTDataSource)

- (void)dct_logTableViewDataSourcesLevel:(NSInteger)level {
	
	NSMutableString *string = [[NSMutableString alloc] init];
	
	for (NSInteger i = 0; i < level; i++)
		[string appendString:@"    "];
	
	NSLog(@"%@%@", string, self);
	
	if ([self isKindOfClass:[DCTParentDataSource class]]) {
		for (id object in [(DCTParentDataSource *)self childDataSources])
			[object dct_logTableViewDataSourcesLevel:level+1];
	}
}

@end

@implementation UITableView (DCTDataSource)

- (void)dct_logTableViewDataSources {
	
	id ds = self.dataSource;
	if (![ds isKindOfClass:[DCTDataSource class]]) return;
	
	DCTDataSource *dataSource = (DCTDataSource *)ds;
	
	NSLog(@"-------------");
	NSLog(@"Logging data sources for %@", self);
	NSLog(@"-------------");
	[dataSource dct_logTableViewDataSourcesLevel:0];
	NSLog(@"-------------");
}

- (NSInteger)dct_convertSection:(NSInteger)section fromChildDataSource:(DCTDataSource *)dataSource {
	
	DCTParentDataSource *parent = dataSource.parent;
	
	while (parent) {
		section = [parent convertSection:section fromChildDataSource:dataSource];
		dataSource = parent;
		parent = dataSource.parent;
	}
	
	NSAssert(parent == nil, @"Parent should equal nil at this point");
	NSAssert(dataSource == self.dataSource, @"dataSource should now be the tableview's dataSource");
	
	return section;
}

- (NSIndexPath *)dct_convertIndexPath:(NSIndexPath *)indexPath fromChildDataSource:(DCTDataSource *)dataSource {
	
	DCTParentDataSource *parent = dataSource.parent;
	
	while (parent) {
		indexPath = [parent convertIndexPath:indexPath fromChildDataSource:dataSource];
		dataSource = parent;
		parent = dataSource.parent;
	}
	
	NSAssert(parent == nil, @"Parent should equal nil at this point");
	NSAssert(dataSource == self.dataSource, @"dataSource should now be the tableview's dataSource");
	
	return indexPath;
}

@end
