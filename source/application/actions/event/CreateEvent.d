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

//Create event without parameters should fail.
unittest {
	import application.testhelpers;

	Database database = GetDatabase("test");
	
	try {
		CreateTestUser("testname", "testpass");
		auto tester = TestLogin("testname", "testpass");
		CreateEvent m = new CreateEvent(new Event_storage(database));

		tester.Request(&m.Perform);

		Json json = tester.GetResponseJson();
		assertEqual(json["success"].to!bool, false);
	}
	finally {
		database.ClearCollection("event");
		database.ClearCollection("user");
	}
}

//Create event with all parameters but not logged in should fail
unittest {
	Database database = GetDatabase("test");
	
	try {
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
	finally {
		database.ClearCollection("event");
	}
}

//Create event with all parameters and logged in should succeed
unittest {
	import application.testhelpers;

	Database database = GetDatabase("test");
	
	try {
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
	finally {
		database.ClearCollection("event");
		database.ClearCollection("user");
	}
}

class Test : TestSuite {
	this() {
		//AddTest(&);
	}

	override void Setup() {
	}

	override void Teardown() {
	}

}

unittest {
	auto test = new Test;
	test.Run();
}