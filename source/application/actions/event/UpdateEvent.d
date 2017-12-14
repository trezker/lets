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

//Update event without parameters should fail.
unittest {
	import application.testhelpers;

	Database database = GetDatabase("test");
	
	try {
		UpdateEvent m = new UpdateEvent(new Event_storage(database));
		ActionTester tester = new ActionTester(&m.Perform);

		Json json = tester.GetResponseJson();
		assertEqual(json["success"].to!bool, false);
	}
	finally {
		database.ClearCollection("event");
		database.ClearCollection("user");
	}
}

//Update event with all parameters but not logged in should fail
unittest {
	Database database = GetDatabase("test");
	
	try {
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