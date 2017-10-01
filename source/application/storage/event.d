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
			"location.latitude": Bson(["$gte": Bson(1)])
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

//Find events in area should return all events in the area
unittest {
	Database database = GetDatabase("test");
	try {
		Event eventInside = {
			userId: "t",
			title: "Inside",
			description: "Description",
			createdTime: Clock.currTime(),
			startTime: Clock.currTime(),
			endTime: Clock.currTime(),
			location: {
				latitude: 2,
				longitude: 2
			}
		};
		Event eventOutside = {
			userId: "t",
			title: "Outside",
			description: "Description",
			createdTime: Clock.currTime(),
			startTime: Clock.currTime(),
			endTime: Clock.currTime(),
			location: {
				latitude: 6,
				longitude: 8
			}
		};

		auto event_storage = new Event_storage(database);
		event_storage.Create(eventInside);
		event_storage.Create(eventOutside);

		EventSearch search = {
			location: {
				latitude: 3,
				longitude: 3
			},
			radius: 2,
			fromTime: Clock.currTime(),
			toTime: Clock.currTime()
		};

		auto events = event_storage.Find(search);

		foreach(e; events) {
			assertEqual("Inside", e.title);
		}
		writeln(events);
	}
	finally {
		database.ClearCollection("event");
	}
}
