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
	string user_id;
	string title;
	string description;
	SysTime created_date;
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
			Bson serializedEvent = serialize!BsonSerializer(event);
			collection.insert(serializedEvent);
			/*
			collection.insert(
				Bson([
					"UserId": Bson(event.UserId),
					"Title": Bson(event.Title),
					"Description": Bson(event.Description),
					"CreatedTime": Bson(event.CreatedTime),
					"StartTime": Bson(event.StartTime),
					"EndTime": Bson(event.EndTime),
					"Location": Bson(event.Location)
				])
			);
			*/
		}
		catch(Exception e) {
			//if(!canFind(e.msg, "duplicate key error")) {
				//log unexpected exception
			//}
			throw e;
		}
	}
}

unittest {
	Event event = {
		user_id: "t",
		title: "Title",
		description: "Description",
		created_date: Clock.currTime(),
		startTime: Clock.currTime(),
		endTime: Clock.currTime(),
		location: {
			latitude: 1,
			longitude: 2
		}
	};
}