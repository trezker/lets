module application.CreateUser;

import std.stdio;
import dauth;
import vibe.http.server;
import vibe.db.mongo.mongo;

import boiler.ActionTester;
import boiler.helpers;
import boiler.HttpRequest;
import boiler.HttpResponse;
import application.Database;
import application.storage.user;

class CreateUser: Action {
	User_storage user_storage;

	this(User_storage user_storage) {
		this.user_storage = user_storage;
	}

	HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		try {
			//Read parameters
			string username = req.json["username"].to!string;
			string password = req.json["password"].to!string;

			//Check that username is not taken
			auto obj = user_storage.UserByName(username);
			if(obj != Bson(null)) {
				Json json = Json.emptyObject;
				json["success"] = false;
				json["info"] = "Username is taken";
				res.writeBody(serializeToJsonString(json), 200);
				return res;
			}

			string hashedPassword = makeHash(toPassword(password.dup)).toString();
			user_storage.Create(username, hashedPassword);

			//Write result
			Json json = Json.emptyObject;
			json["success"] = true;
			res.writeBody(serializeToJsonString(json), 200);
		}
		catch(Exception e) {
			//Write result
			Json json = Json.emptyObject;
			json["success"] = false;
			res.writeBody(serializeToJsonString(json), 200);
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

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
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
		Json jsoninput = Json.emptyObject;
		jsoninput["username"] = "testname";
		jsoninput["password"] = "testpass";

		ActionTester tester = new ActionTester(&m.Perform, serializeToJsonString(jsoninput));

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
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
		Json jsoninput = Json.emptyObject;
		jsoninput["username"] = username;
		jsoninput["password"] = password;

		ActionTester tester = new ActionTester(&m.Perform, serializeToJsonString(jsoninput));
		
		auto obj = user_storage.UserByName(username);
		assert(isSameHash(toPassword(password.dup), parseHash(obj["password"].get!string)));
	}
	finally {
		database.ClearCollection("user");
	}
}
