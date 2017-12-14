module application.storage.event;

import std.conv;
import std.stdio;
import std.algorithm;
import std.exception;
import std.datetime;
import dauth;
import vibe.db.mongo.mongo;
import vibe.data.bson;

import boiler.helpers;
import boiler.testsuite;
import application.testhelpers;
import application.Database;

struct Location {
	double latitude;
	double longitude;
}

struct NewEvent {
	@optional BsonObjectID userId;
	string title;
	string description;
	@optional SysTime createdTime;
	SysTime startTime;
	SysTime endTime;
	Location location;
}

struct Event {
	BsonObjectID _id;
	@optional BsonObjectID userId;
	string title;
	string description;
	@optional SysTime createdTime;
	SysTime startTime;
	SysTime endTime;
	Location location;
}

struct EventSearch {
	Location location;
	double radius;
	SysTime fromTime;
	SysTime toTime;
}

struct EventSearchUser {
	@optional BsonObjectID userId;
	@optional SysTime fromTime;
	@optional SysTime toTime;
}

class Event_storage {
	Database database;
	MongoCollection collection;
	this(Database database) {
		this.database = database;
		collection = database.GetCollection("event");
	}

	void Create(NewEvent event) {
		collection.insert(event);
	}

	void Update(Event event) {
		auto selector = Bson(["_id": Bson(event._id)]);
		auto update = Bson([
			"$set": Bson([
				"title": Bson(event.title),
				"description": Bson(event.description),
				"startTime": Bson(BsonDate(event.startTime)),
				"endTime": Bson(BsonDate(event.endTime)),
				"location.longitude": Bson(event.location.longitude),
				"location.latitude": Bson(event.location.latitude)
			])
		]);
		collection.update(selector, update);
	}

	Event[] FindInArea(EventSearch eventSearch) {
		auto conditions = Bson([
			"location.latitude": Bson([
				"$gte": Bson(eventSearch.location.latitude - eventSearch.radius),
				"$lte": Bson(eventSearch.location.latitude + eventSearch.radius)
			]),
			"location.longitude": Bson([
				"$gte": Bson(eventSearch.location.longitude - eventSearch.radius),
				"$lte": Bson(eventSearch.location.longitude + eventSearch.radius)
			])
		]);
		return MongoArray!(Event)(collection, conditions);
	}

	Event[] ByUser(EventSearchUser search) {
		auto conditions = Bson([
			"userId": Bson(search.userId)
		]);
		if(search.fromTime == SysTime.init || search.toTime == SysTime.init) {
			conditions["endTime"] = Bson([
				"$gte": Bson(BsonDate(Clock.currTime()))
			]);
		}
		return MongoArray!(Event)(collection, conditions);
	}

	void Delete(BsonObjectID userId, BsonObjectID eventId) {
		auto condition = Bson(["_id": Bson(eventId)]);
		auto obj = collection.findOne(condition);
		if(userId == obj["userId"].get!BsonObjectID) {
			collection.remove(Bson(["_id": Bson(eventId)]));
		}
	}
}

class Test : TestSuite {
	Database database;
	Event_storage event_storage;

	this() {
		database = GetDatabase("test");
		event_storage = new Event_storage(database);

		AddTest(&Creating_a_valid_event_should_succeed);
		AddTest(&Update_event_should_succeed);
		AddTest(&Find_events_in_area_should_return_all_events_in_the_area);
		AddTest(&Find_events_by_user_should_return_all_events_created_by_the_user);
		AddTest(&Delete_event);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("event");
	}
	
	void Creating_a_valid_event_should_succeed() {
		auto time = Clock.currTime();
		NewEvent event = {
			userId: BsonObjectID.fromString("000000000000000000000000"),
			title: "Title",
			description: "Description",
			createdTime: time,
			startTime: time,
			endTime: time,
			location: {
				latitude: 1,
				longitude: 2
			}
		};

		auto event_storage = new Event_storage(database);
		event_storage.Create(event);

		//Reload the search
		EventSearch search = {
			location: {
				latitude: 2,
				longitude: 2
			},
			radius: 1,
			fromTime: Clock.currTime(),
			toTime: Clock.currTime()
		};

		auto events = event_storage.FindInArea(search);
		assertEqual(1, events.length);
		assertEqual("Title", events[0].title);
		assertEqual("Description", events[0].description);
		assertEqual(BsonDate(time), BsonDate(events[0].createdTime));
	}

	void Update_event_should_succeed() {
		event_storage.Create(CoordinateEvent(Location(4, 4), "Inside"));

		//Find and update the event.
		EventSearch search = {
			location: {
				latitude: 3,
				longitude: 3
			},
			radius: 1,
			fromTime: Clock.currTime(),
			toTime: Clock.currTime()
		};

		auto newTime = Clock.currTime();
		Location newLocation = {
				latitude: 2,
				longitude: 3
		};

		auto events = event_storage.FindInArea(search);
		assertEqual(1, events.length);
		events[0].title = "New title";
		events[0].description = "New description";
		events[0].startTime = newTime;
		events[0].endTime = newTime;
		events[0].location = newLocation;
		event_storage.Update(events[0]);

		//Reload the search
		EventSearch search2 = {
			location: {
				latitude: 3,
				longitude: 3
			},
			radius: 1,
			fromTime: Clock.currTime(),
			toTime: Clock.currTime()
		};

		events = event_storage.FindInArea(search2);
		assertEqual(1, events.length);
		assertEqual("New title", events[0].title);
		assertEqual("New description", events[0].description);
		assertEqual(BsonDate(newTime), BsonDate(events[0].startTime));
		assertEqual(BsonDate(newTime), BsonDate(events[0].endTime));
		assertEqual(newLocation, events[0].location);
	}

	void Find_events_in_area_should_return_all_events_in_the_area() {
		event_storage.Create(CoordinateEvent(Location(4, 4), "Inside"));
		event_storage.Create(CoordinateEvent(Location(2, 2), "Inside"));
		event_storage.Create(CoordinateEvent(Location(5, 5), "Outside"));
		event_storage.Create(CoordinateEvent(Location(1, 1), "Outside"));
		event_storage.Create(CoordinateEvent(Location(5, 1), "Outside"));
		event_storage.Create(CoordinateEvent(Location(1, 5), "Outside"));

		auto collection = database.GetCollection("event");
		auto conditions = Bson([
			"title": Bson("Outside")
		]);

		EventSearch search = {
			location: {
				latitude: 3,
				longitude: 3
			},
			radius: 1,
			fromTime: Clock.currTime(),
			toTime: Clock.currTime()
		};

		auto events = event_storage.FindInArea(search);

		assertEqual(2, events.length);
		foreach(e; events) {
			assertEqual("Inside", e.title);
		}
	}

	void Find_events_by_user_should_return_all_events_created_by_the_user() {
		auto userId = "000000000000000000000000";
		event_storage.Create(UserEvent(userId));
		event_storage.Create(UserEvent(userId));
		event_storage.Create(UserEvent("102030405060708090102030"));

		EventSearchUser search = {
			userId: BsonObjectID.fromString(userId),
			fromTime: Clock.currTime(),
			toTime: Clock.currTime()
		};

		auto events = event_storage.ByUser(search);

		//writeln(events);
		assertEqual(2, events.length);
		foreach(e; events) {
			assertEqual(userId, e.userId.toString());
		}
	}

	void Delete_event() {
		auto userIdString = "000000000000000000000000";
		event_storage.Create(UserEvent(userIdString));
		event_storage.Create(UserEvent(userIdString));
		auto userId = BsonObjectID.fromString(userIdString);

		EventSearchUser search = {
			userId: userId,
			fromTime: Clock.currTime(),
			toTime: Clock.currTime()
		};

		auto events = event_storage.ByUser(search);

		assertEqual(2, events.length);

		event_storage.Delete(userId, events[0]._id);
		auto eventsAfterDelete = event_storage.ByUser(search);

		//writeln(events);
		assertEqual(1, eventsAfterDelete.length);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}