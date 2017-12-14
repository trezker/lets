module application.UpdateEvent;

import std.stdio;
import std.datetime;
import dauth;
import vibe.http.server;
import vibe.db.mongo.mongo;

import boiler.ActionTester;
import boiler.helpers;
import boiler.testsuite;
import boiler.HttpRequest;
import boiler.HttpResponse;
import application.Database;
import application.storage.event;
import application.testhelpers;

import application.CreateEvent;

class UpdateEvent: Action {
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
			Event event = deserialize!(JsonSerializer, Event)(request.json);
			
			BsonObjectID userId = BsonObjectID.fromString(request.session.get!string("id"));
			event.userId = userId;

			event_storage.Update(event);

			//Write result
			Json json = Json.emptyObject;
			json["success"] = true;
			res.writeBody(serializeToJsonString(json), 200);
		}
		catch(Exception e) {
			//Write result
			//writeln(e);
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

		AddTest(&Update_event_without_parameters_should_fail);
		AddTest(&Update_event_with_all_parameters_but_not_logged_in_should_fail);
		AddTest(&Create_event_with_all_parameters_and_logged_in_should_succeed);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("event");
		database.ClearCollection("user");
	}

	void Update_event_without_parameters_should_fail() {
		UpdateEvent m = new UpdateEvent(new Event_storage(database));
		ActionTester tester = new ActionTester(&m.Perform);

		Json json = tester.GetResponseJson();
		assertEqual(json["success"].to!bool, false);
	}

	void Update_event_with_all_parameters_but_not_logged_in_should_fail() {
		Event event = {
			title: "Title",
			description: "Description",
			startTime: Clock.currTime(),
			endTime: Clock.currTime(),
			createdTime: Clock.currTime(),
			location: {
				latitude: 1,
				longitude: 2
			}
		};
		Json jsoninput = serialize!(JsonSerializer, Event)(event);

		UpdateEvent m = new UpdateEvent(new Event_storage(database));
		ActionTester tester = new ActionTester(&m.Perform);

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Create_event_with_all_parameters_and_logged_in_should_succeed() {
		CreateTestUser("testname", "testpass");
		auto tester = TestLogin("testname", "testpass");

		NewEvent newEvent = {
			title: "Title",
			description: "Description",
			startTime: Clock.currTime(),
			endTime: Clock.currTime(),
			createdTime: Clock.currTime(),
			location: {
				latitude: 1,
				longitude: 2
			}
		};
		Json createinput = serialize!(JsonSerializer, NewEvent)(newEvent);
		CreateEvent createEvent = new CreateEvent(new Event_storage(database));
		tester.Request(&createEvent.Perform, createinput.toString);

		Event event = {
			title: "Title",
			description: "Description",
			startTime: Clock.currTime(),
			endTime: Clock.currTime(),
			createdTime: Clock.currTime(),
			location: {
				latitude: 1,
				longitude: 2
			}
		};
		Json updateinput = serialize!(JsonSerializer, Event)(event);
		UpdateEvent updateEvent = new UpdateEvent(new Event_storage(database));
		tester.Request(&updateEvent.Perform, updateinput.toString);

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}