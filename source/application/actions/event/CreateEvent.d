module application.CreateEvent;

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

class CreateEvent: Action {
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
			NewEvent event = deserialize!(JsonSerializer, NewEvent)(request.json);
			
			BsonObjectID userId = BsonObjectID.fromString(request.session.get!string("id"));
			event.userId = userId;
			event.createdTime = Clock.currTime();

			event_storage.Create(event);

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

		AddTest(&Create_event_without_parameters_should_fail);
		AddTest(&Create_event_with_all_parameters_but_not_logged_in_should_fail);
		AddTest(&Create_event_with_all_parameters_and_logged_in_should_succeed);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("event");
		database.ClearCollection("user");
	}

	void Create_event_without_parameters_should_fail() {
		CreateTestUser("testname", "testpass");
		auto tester = TestLogin("testname", "testpass");
		CreateEvent m = new CreateEvent(new Event_storage(database));

		tester.Request(&m.Perform);

		Json json = tester.GetResponseJson();
		assertEqual(json["success"].to!bool, false);
	}

	void Create_event_with_all_parameters_but_not_logged_in_should_fail() {
		NewEvent event = {
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
		Json jsoninput = serialize!(JsonSerializer, NewEvent)(event);
		CreateEvent m = new CreateEvent(new Event_storage(database));
		ActionTester tester = new ActionTester(&m.Perform, jsoninput.toString);
		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Create_event_with_all_parameters_and_logged_in_should_succeed() {
		CreateTestUser("testname", "testpass");
		auto tester = TestLogin("testname", "testpass");

		CreateEvent m = new CreateEvent(new Event_storage(database));
		NewEvent event = {
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
		//writeln(event);
		Json jsoninput = serialize!(JsonSerializer, NewEvent)(event);

		tester.Request(&m.Perform, jsoninput.toString);

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}