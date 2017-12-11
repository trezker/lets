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
		auto conditions = Bson(["userId": Bson(search.userId)]);
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

//Creating a valid event should succeed
unittest {
	Database database = GetDatabase("test");
	try {
		NewEvent event = {
			userId: BsonObjectID.fromString("000000000000000000000000"),
			title: "Title",
			description: "Description",
			createdTime: Clock.currTime(),
			startTime: Clock.currTime(),
			endTime: Clock.currTime(),
			location: {
				latitude: 1,
				longitude: 2
			}
		};

		auto event_storage = new Event_storage(database);
		event_storage.Create(event);
	}
	finally {
		database.ClearCollection("event");
	}
}

//Update event should succeed
unittest {
	import application.testhelpers;
	Database database = GetDatabase("test");
	try {
		auto event_storage = new Event_storage(database);

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
		//assertEqual(newTime, events[0].startTime);
		//assertEqual(newTime, events[0].endTime);
		assertEqual(newLocation, events[0].location);
	}
	finally {
		database.ClearCollection("event");
	}
}

//Find events in area should return all events in the area
unittest {
	import application.testhelpers;
	Database database = GetDatabase("test");
	try {
		auto event_storage = new Event_storage(database);
		
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
	finally {
		database.ClearCollection("event");
	}
}

//Find events by user should return all events created by the user
unittest {
	import application.testhelpers;
	Database database = GetDatabase("test");
	try {
		auto event_storage = new Event_storage(database);
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
	finally {
		database.ClearCollection("event");
	}
}

//Find events by user should return all events created by the user
unittest {
	import application.testhelpers;
	Database database = GetDatabase("test");
	try {
		auto event_storage = new Event_storage(database);
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
	finally {
		database.ClearCollection("event");
	}
}
