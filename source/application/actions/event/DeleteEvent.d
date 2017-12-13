module application.DeleteEvent;

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

class DeleteEvent: Action {
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
			BsonObjectID eventId = BsonObjectID.fromString(request.json["eventId"].to!string);
			
			BsonObjectID userId = BsonObjectID.fromString(request.session.get!string("id"));

			event_storage.Delete(userId, eventId);

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

//Delete event without parameters should fail.
unittest {
	import application.testhelpers;

	Database database = GetDatabase("test");
	
	try {
		DeleteEvent m = new DeleteEvent(new Event_storage(database));
		ActionTester tester = new ActionTester(&m.Perform);

		Json json = tester.GetResponseJson();
		assertEqual(json["success"].to!bool, false);
	}
	finally {
		database.ClearCollection("event");
		database.ClearCollection("user");
	}
}

//Delete event with all parameters but not logged in should fail
unittest {
	Database database = GetDatabase("test");
	
	try {
		Json jsoninput = Json(["eventId": Json("000000000000000000000000")]);
		DeleteEvent m = new DeleteEvent(new Event_storage(database));
		ActionTester tester = new ActionTester(&m.Perform, jsoninput.toString);
		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}
	finally {
		database.ClearCollection("event");
	}
}

//Delete event with all parameters and logged in should succeed and the event should not exist after
unittest {
	import application.testhelpers;

	Database database = GetDatabase("test");
	
	try {
		CreateTestUser("testname", "testpass");
		auto tester = TestLogin("testname", "testpass");
		string userIdString = tester.GetResponseSessionValue!string("id");
		auto userId = BsonObjectID.fromString(userIdString);

		//Create an event for the user and get its id.
		auto event_storage = new Event_storage(database);
		event_storage.Create(UserEvent(userIdString));
		EventSearchUser search = {
			userId: userId,
			fromTime: Clock.currTime(),
			toTime: Clock.currTime()
		};
		auto events = event_storage.ByUser(search);

		Json jsoninput = Json(["eventId": Json(events[0]._id.toString())]);
		DeleteEvent m = new DeleteEvent(new Event_storage(database));
		tester.Request(&m.Perform, jsoninput.toString);

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);

		auto eventsAfterDelete = event_storage.ByUser(search);

		//writeln(events);
		assertEqual(0, eventsAfterDelete.length);
	}
	finally {
		database.ClearCollection("event");
		database.ClearCollection("user");
	}
}
