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

class CreateEvent: Action {
	Event_storage event_storage;

	this(Event_storage event_storage) {
		this.event_storage = event_storage;
	}

	HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		try {
			//Read parameters
			string title = req.json["title"].str;

			/*
event {
	UserId
	Title
	Description
	CreatedDate
	StartTime
	EndTime
	Location {
		Latitude
		Longitude
	}
}
*/

			//event_storage.Create(event);

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

//Create user without parameters should fail.
unittest {
	Database database = GetDatabase("test");
	
	try {
		CreateUser m = new CreateUser(new User_storage(database));

		ActionTester tester = new ActionTester(&m.Perform);

		JSONValue json = tester.GetResponseJson();
		assert(json["success"] == JSONValue(false));
	}
	finally {
		database.ClearCollection("user");
	}
}

//Create user with name and password should succeed
unittest {
	Database database = GetDatabase("test");
	
	try {
		CreateUser m = new CreateUser(new User_storage(database));
		JSONValue jsoninput;
		jsoninput["username"] = "testname";
		jsoninput["password"] = "testpass";

		ActionTester tester = new ActionTester(&m.Perform, jsoninput.toString);

		JSONValue jsonoutput = tester.GetResponseJson();
		assert(jsonoutput["success"] == JSONValue(true));
	}
	finally {
		database.ClearCollection("user");
	}
}

//Created user should have a hashed password
unittest {
	Database database = GetDatabase("test");
	
	try {
		string username = "testname";
		string password = "testpass";

		auto user_storage = new User_storage(database);
		CreateUser m = new CreateUser(user_storage);
		JSONValue jsoninput;
		jsoninput["username"] = username;
		jsoninput["password"] = password;

		ActionTester tester = new ActionTester(&m.Perform, jsoninput.toString);
		
		auto obj = user_storage.UserByName(username);
		assert(isSameHash(toPassword(password.dup), parseHash(obj["password"].get!string)));
	}
	finally {
		database.ClearCollection("user");
	}
}
