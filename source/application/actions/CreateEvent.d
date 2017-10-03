module application.CreateEvent;

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
	import std.datetime;

class CreateEvent: Action {
	Event_storage event_storage;

	this(Event_storage event_storage) {
		this.event_storage = event_storage;
	}

	HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		try {
			Event event = deserialize!(JsonSerializer, Event)(req.json);

			event_storage.Create(event);

			//Write result
			JSONValue json;
			json["success"] = true;
			res.writeBody(json.toString, 200);
		}
		catch(Exception e) {
			//Write result
			JSONValue json;
			json["success"] = false;
			res.writeBody(json.toString, 200);
		}
		return res;
	}
}

//Create event without parameters should fail.
unittest {
	Database database = GetDatabase("test");
	
	try {
		CreateEvent m = new CreateEvent(new Event_storage(database));

		ActionTester tester = new ActionTester(&m.Perform);

		JSONValue json = tester.GetResponseJson();
		assert(json["success"] == JSONValue(false));
	}
	finally {
		database.ClearCollection("event");
	}
}

//Create event with all parameters should succeed
unittest {
	import std.datetime;
	Database database = GetDatabase("test");
	
	try {
		CreateEvent m = new CreateEvent(new Event_storage(database));
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
		Json jsoninput = serialize!(JsonSerializer, Event)(event);

		ActionTester tester = new ActionTester(&m.Perform, jsoninput.toString);

		JSONValue jsonoutput = tester.GetResponseJson();
		assert(jsonoutput["success"] == JSONValue(true));
	}
	finally {
		database.ClearCollection("event");
	}
}
