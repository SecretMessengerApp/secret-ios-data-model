//
//

import XCTest
import WireTesting
@testable import WireDataModel

class TestEntity: NSManagedObject {
    @NSManaged var identifier: String?
    @NSManaged var parameter: String?
}

class BatchDeleteTests: ZMTBaseTest {
    var model: NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        let entity = NSEntityDescription()
        entity.name = "\(TestEntity.self)"
        entity.managedObjectClassName = NSStringFromClass(TestEntity.self)
        
        var properties = Array<NSAttributeDescription>()
        
        let remoteURLAttribute = NSAttributeDescription()
        remoteURLAttribute.name = #keyPath(TestEntity.identifier)
        remoteURLAttribute.attributeType = .stringAttributeType
        remoteURLAttribute.isOptional = true
        remoteURLAttribute.isIndexed = true
        properties.append(remoteURLAttribute)
        
        let fileDataAttribute = NSAttributeDescription()
        fileDataAttribute.name = #keyPath(TestEntity.parameter)
        fileDataAttribute.attributeType = .stringAttributeType
        fileDataAttribute.isOptional = true
        properties.append(fileDataAttribute)

        entity.properties = properties
        model.entities = [entity]
        return model
    }

    func cleanStorage() {
        if FileManager.default.fileExists(atPath: storagePath) {
            try! FileManager.default.removeItem(at: URL(fileURLWithPath: storagePath))
        }
    }
    
    func createTestCoreData() throws -> (NSManagedObjectModel, NSManagedObjectContext) {
        let model = self.model
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                          configurationName: nil,
                                                          at: URL(fileURLWithPath: storagePath),
                                                          options: [:])
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        return (model, managedObjectContext)
    }
    
    let storagePath = NSTemporaryDirectory().appending("test.sqlite")
    var mom: NSManagedObjectModel!
    var moc: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        cleanStorage()
        let (mom, moc) = try! createTestCoreData()
        self.mom = mom
        self.moc = moc
    }
    
    override func tearDown() {
        moc.persistentStoreCoordinator?.persistentStores.forEach {
            try! self.moc.persistentStoreCoordinator!.remove($0)
        }
        
        self.moc = nil
        self.mom = nil
        cleanStorage()
        super.tearDown()
    }
    
    func testThatItDoesNotRemoveValidGenericMessageData() throws {
        // given
        let entity = mom.entitiesByName["\(TestEntity.self)"]!
        
        let ints = Array(0...10)
        let objects: [TestEntity] = ints.map { (id: Int) in
            let object = TestEntity(entity: entity, insertInto: self.moc)
            object.identifier = "\(id)"
            object.parameter = "value"
            return object
        }
        
        let objectsShouldBeDeleted: [TestEntity] = ints.map { (id: Int) in
            let object = TestEntity(entity: entity, insertInto: self.moc)
            object.identifier = "\(id + 100)"
            object.parameter = nil
            return object
        }
        
        // when
        
        try moc.save()
        
        let predicate = NSPredicate(format: "%K == nil", #keyPath(TestEntity.parameter))
        try moc.batchDeleteEntities(named: "\(TestEntity.self)", matching: predicate)
        
        // then
        objects.forEach {
            XCTAssertFalse($0.isDeleted)
        }
        
        objectsShouldBeDeleted.forEach {
            XCTAssertTrue($0.isDeleted)
        }
    }
    
    func testThatItNotifiesAboutDelete() throws {
        class FetchRequestObserver: NSObject, NSFetchedResultsControllerDelegate {
            var deletedCount: Int = 0
            
            public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                                   didChange anObject: Any,
                                   at indexPath: IndexPath?,
                                   for type: NSFetchedResultsChangeType,
                                   newIndexPath: IndexPath?)
            {
                switch type {
                case .delete:
                    deletedCount = deletedCount + 1
                case .insert:
                    break
                case .move:
                    break
                case .update:
                    break
                }
            }
        }
        
        // given
        let entity = mom.entitiesByName["\(TestEntity.self)"]!
        
        let object = TestEntity(entity: entity, insertInto: self.moc)
        object.identifier = "1"
        object.parameter = nil
        
        // when
        
        try moc.save()
        
        let observer = FetchRequestObserver()
        
        let fetchRequest = NSFetchRequest<TestEntity>(entityName: "\(TestEntity.self)")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(TestEntity.identifier), ascending: true)]
        let fetchRequestController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                managedObjectContext: moc,
                                                                sectionNameKeyPath: nil,
                                                                cacheName: nil)
        fetchRequestController.delegate = observer
        try fetchRequestController.performFetch()
        XCTAssertEqual(fetchRequestController.sections?.count, 1)
        XCTAssertEqual(fetchRequestController.sections?.first?.objects?.count, 1)
        XCTAssertEqual(fetchRequestController.sections?.first?.objects?.first as! TestEntity, object)
        
        let predicate = NSPredicate(format: "%K == nil", #keyPath(TestEntity.parameter))
        try moc.batchDeleteEntities(named: "\(TestEntity.self)", matching: predicate)
        try moc.save()

        // then
        XCTAssertEqual(observer.deletedCount, 1)
    }
}
