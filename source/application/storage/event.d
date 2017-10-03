module application.storage.event;

import std.json;
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

struct Event {
	string userId;
	string title;
	string description;
	SysTime createdTime;
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

class Event_storage {
	Database database;
	MongoCollection collection;
	this(Database database) {
		this.database = database;
		collection = database.GetCollection("event");
	}

	void Create(Event event) {
		collection.insert(event);
	}

	Event[] Find(EventSearch eventSearch) {
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
}

//Creating a valid event should succeed
unittest {
	Database database = GetDatabase("test");
	try {
		Event event = {
			userId: "t",
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

Event CoordinateEvent(Location l, string t) {
	Event event;
	event.userId = "t";
	event.title = t;
	event.description = "Description";
	event.createdTime = Clock.currTime();
	event.startTime = Clock.currTime();
	event.endTime = Clock.currTime();
	event.location = l;

	return event;
}

//Find events in area should return all events in the area
unittest {
	Database database = GetDatabase("test");
	try {
		auto event_storage = new Event_storage(database);
		
		Location location = {latitude: 4,longitude: 4};
		event_storage.Create(CoordinateEvent(Location(4, 4), "Inside"));
		event_storage.Create(CoordinateEvent(Location(2, 2), "Inside"));
		event_storage.Create(CoordinateEvent(Location(5, 5), "Outside"));
		event_storage.Create(CoordinateEvent(Location(1, 1), "Outside"));
		event_storage.Create(CoordinateEvent(Location(5, 1), "Outside"));
		event_storage.Create(CoordinateEvent(Location(1, 5), "Outside"));

		EventSearch search = {
			location: {
				latitude: 3,
				longitude: 3
			},
			radius: 1,
			fromTime: Clock.currTime(),
			toTime: Clock.currTime()
		};

		auto events = event_storage.Find(search);

		//writeln(events);
		assertEqual(2, events.length);
		foreach(e; events) {
			assertEqual("Inside", e.title);
		}
	}
	finally {
		database.ClearCollection("event");
	}
}
