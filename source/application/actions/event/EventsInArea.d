module application.EventsInArea;

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
		AddTest(&Find_event_without_parameters_should_fail);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("event");
	}

	void Find_event_without_parameters_should_fail() {
		EventsInArea m = new EventsInArea(new Event_storage(database));

		ActionTester tester = new ActionTester(&m.Perform);

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Find_event_with_parameters_should_find_event() {
		auto event_storage = new Event_storage(database);
		event_storage.Create(CoordinateEvent(Location(2, 2), "Inside"));
		event_storage.Create(CoordinateEvent(Location(5, 5), "Outside"));
		EventsInArea m = new EventsInArea(event_storage);

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

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
		Event[] events = deserialize!(JsonSerializer, Event[])(jsonoutput["events"]);
		assertEqual(events.length, 1);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}