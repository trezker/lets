module application.MyEvents;

import std.stdio;
import std.datetime;
import dauth;
import vibe.http.server;
import vibe.db.mongo.mongo;
import vibe.data.json;

import boiler.ActionTester;
import boiler.helpers;
import boiler.testsuite;
import boiler.HttpRequest;
import boiler.HttpResponse;
import application.Database;
import application.storage.event;
import application.testhelpers;

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

class Test : TestSuite {
	Database database;

	this() {
		database = GetDatabase("test");

		AddTest(&Find_event_without_parameters_should_fail);
		AddTest(&Find_events_with_parameters_should_find_events);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("event");
	}

	void Find_event_without_parameters_should_fail() {
		string username = "test";
		string password = "test";
		CreateTestUser(username, password);
		ActionTester tester = TestLogin(username, password);

		MyEvents m = new MyEvents(new Event_storage(database));

		tester.Request(&m.Perform);

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Find_events_with_parameters_should_find_events() {
		string username = "test";
		string password = "test";
		CreateTestUser(username, password);
		ActionTester tester = TestLogin(username, password);
		string userId = tester.GetResponseSessionValue!string("id");

		auto event_storage = new Event_storage(database);
		event_storage.Create(UserEvent(userId));
		event_storage.Create(UserEvent(userId));
		event_storage.Create(UserEvent("123456781234567812345678"));

		MyEvents myEvents = new MyEvents(event_storage);

		EventSearchUser search = {
			fromTime: Clock.currTime(),
			toTime: Clock.currTime()
		};

		Json jsoninput = serialize!(JsonSerializer, EventSearchUser)(search);

		tester.Request(&myEvents.Perform, jsoninput.toString);

		Json jsonoutput = tester.GetResponseJson();
		
		assertEqual(jsonoutput["success"].to!bool, true);
		Event[] events = deserialize!(JsonSerializer, Event[])(jsonoutput["events"]);
		//writeln(events);
		assertEqual(events.length, 2);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}