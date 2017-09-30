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

class Event_storage {
	Database database;
	MongoCollection collection;
	this(Database database) {
		this.database = database;
		collection = database.GetCollection("event");
	}

	void Create(Event event) {
		try {
			collection.insert(event);
		}
		catch(Exception e) {
			//if(!canFind(e.msg, "duplicate key error")) {
				//log unexpected exception
			//}
			throw e;
		}
	}
}

//Create a valid event
unittest {
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

	Database database = GetDatabase("test");
	auto event_storage = new Event_storage(database);
	event_storage.Create(event);
}