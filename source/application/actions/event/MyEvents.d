module application.MyEvents;

import std.stdio;
import dauth;
import vibe.http.server;
import vibe.db.mongo.mongo;
import vibe.data.json;

import boiler.ActionTester;
import boiler.helpers;
import boiler.HttpRequest;
import boiler.HttpResponse;
import application.Database;
import application.storage.event;

class MyEvents: Action {
	Event_storage event_storage;

	this(Event_storage event_storage) {
		this.event_storage = event_storage;
	}

	HttpResponse Perform(HttpRequest request) {
		HttpResponse res = new HttpResponse;
		try {
			if(!request.session) {
				throw new Exception("User not logged in");
			}
			EventSearchUser search = deserialize!(JsonSerializer, EventSearchUser)(request.json);
			BsonObjectID userId = BsonObjectID.fromString(request.session.get!string("id"));
			search.userId = userId;

			Event[] events = event_storage.ByUser(search);

			//Write result
			Json json = Json.emptyObject;
			json["success"] = true;
			json["events"] = serialize!(JsonSerializer, Event[])(events);
			res.writeBody(serializeToJsonString(json), 200);
		}
		catch(Exception e) {
			//writeln(e);
			//Write result
			Json json = Json.emptyObject;
			json["success"] = false;
			res.writeBody(serializeToJsonString(json), 200);
		}
		return res;
	}
}

//Find event without parameters should fail.
unittest {
	import application.testhelpers;
	Database database = GetDatabase("test");
	
	try {
		string username = "test";
		string password = "test";
		CreateTestUser(username, password);
		ActionTester tester = TestLogin(username, password);

		MyEvents m = new MyEvents(new Event_storage(database));

		tester.Request(&m.Perform);

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}
	finally {
		database.ClearCollection("event");
	}
}

//Find events with parameters should find events.
unittest {
	import application.testhelpers;
	import std.datetime;
	Database database = GetDatabase("test");
	
	try {
		string username = "test";
		string password = "test";
		CreateTestUser(username, password);
		ActionTester tester = TestLogin(username, password);
		string userId = tester.GetResponseSessionValue!string("id");

		auto event_storage = new Event_storage(database);
		event_storage.Create(UserEvent(userId));
		event_storage.Create(UserEvent(userId));
		event_storage.Create(UserEvent("123456781234567812345678"));

		MyEvents m = new MyEvents(event_storage);

		EventSearch search = {
			fromTime: Clock.currTime(),
			toTime: Clock.currTime()
		};

		Json jsoninput = serialize!(JsonSerializer, EventSearch)(search);

		tester.Request(&m.Perform, jsoninput.toString);

		Json jsonoutput = tester.GetResponseJson();
		
		assertEqual(jsonoutput["success"].to!bool, true);
		Event[] events = deserialize!(JsonSerializer, Event[])(jsonoutput["events"]);
		assertEqual(events.length, 2);
	}
	finally {
		database.ClearCollection("event");
	}
}
