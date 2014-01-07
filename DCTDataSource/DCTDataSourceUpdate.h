//
//  DCTDataSourceUpdate.h
//  DCTDataSource
//
//  Created by Daniel Tull on 08.10.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

@import Foundation;

typedef enum {
	DCTDataSourceUpdateTypeItemDelete = 1 << 0,
	DCTDataSourceUpdateTypeSectionDelete = 1 << 1,
	DCTDataSourceUpdateTypeItemInsert = 1 << 2,
	DCTDataSourceUpdateTypeSectionInsert = 1 << 3,
	DCTDataSourceUpdateTypeItemReload = 1 << 4,
	DCTDataSourceUpdateTypeItemMove = 1 << 5,
} DCTDataSourceUpdateType;

@interface DCTDataSourceUpdate : NSObject

- (instancetype)initWithType:(DCTDataSourceUpdateType)type oldIndexPath:(NSIndexPath *)oldIndexPath newIndexPath:(NSIndexPath *)newIndexPath;

// Item
+ (instancetype)reloadUpdateWithIndexPath:(NSIndexPath *)indexPath;
+ (instancetype)insertUpdateWithNewIndexPath:(NSIndexPath *)newIndexPath;
+ (instancetype)deleteUpdateWithOldIndexPath:(NSIndexPath *)oldIndexPath;
+ (instancetype)moveUpdateWithOldIndexPath:(NSIndexPath *)oldIndexPath newIndexPath:(NSIndexPath *)newIndexPath;

// Section
+ (instancetype)insertUpdateWithIndex:(NSInteger *)index;
+ (instancetype)deleteUpdateWithIndex:(NSInteger *)index;

@property (nonatomic, readonly) DCTDataSourceUpdateType type;
@property (nonatomic, readonly) NSIndexPath *oldIndexPath;
@property (nonatomic, readonly) NSIndexPath *newIndexPath;
- (NSIndexPath *)newIndexPath __attribute__((objc_method_family(none)));


- (BOOL)isSectionUpdate;

- (NSInteger)section;

@end
