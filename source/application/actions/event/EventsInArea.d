module application.EventsInArea;

import std.json;
import std.stdio;
import dauth;
import vibe.http.server;
import vibe.db.mongo.mongo;

import boiler.ActionTester;
import boiler.helpers;
import boiler.HttpRequest;
import boiler.HttpResponse;
import application.Database;
import application.storage.event;

class EventsInArea: Action {
	Event_storage event_storage;

	this(Event_storage event_storage) {
		this.event_storage = event_storage;
	}

	HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		try {
			EventSearch search = deserialize!(JsonSerializer, EventSearch)(req.json);

			Event[] events = event_storage.FindInArea(search);

			//Write result
			Json json = Json.emptyObject;
			json["success"] = true;
			json["events"] = serialize!(JsonSerializer, Event[])(events);
			res.writeBody(serializeToJsonString(json), 200);
		}
		catch(Exception e) {
			//writeln(e);
			//Write result
			JSONValue json;
			json["success"] = false;
			res.writeBody(json.toString, 200);
		}
		return res;
	}
}

//Find event without parameters should fail.
unittest {
	Database database = GetDatabase("test");
	
	try {
		EventsInArea m = new EventsInArea(new Event_storage(database));

		ActionTester tester = new ActionTester(&m.Perform);

		JSONValue json = tester.GetResponseJson();
		assert(json["success"] == JSONValue(false));
	}
	finally {
		database.ClearCollection("event");
	}
}

//Find event with parameters should find event.
unittest {
	import application.testhelpers;
	import std.datetime;
	Database database = GetDatabase("test");
	
	try {
		CreateTestEvent();
		EventsInArea m = new EventsInArea(new Event_storage(database));

		EventSearch search = {
			location: {
				latitude: 3,
				longitude: 3
			},
			radius: 1,
			fromTime: Clock.currTime(),
			toTime: Clock.currTime()
		};

		Json jsoninput = serialize!(JsonSerializer, EventSearch)(search);

		ActionTester tester = new ActionTester(&m.Perform, jsoninput.toString);

		JSONValue json = tester.GetResponseJson();
		assert(json["success"] == JSONValue(true));
		writeln(json);
		//assert(json["events"] == JSONValue(true));
	}
	finally {
		database.ClearCollection("event");
	}
}
