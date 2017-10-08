module application.Logout;

import std.stdio;
import vibe.http.server;
import vibe.data.json;

import boiler.ActionTester;
import boiler.helpers;
import boiler.HttpRequest;
import boiler.HttpResponse;

class Logout: Action {
	HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		try {
			req.TerminateSession();

			Json json = Json.emptyObject;
			json["success"] = true;
			res.writeBody(serializeToJsonString(json), 200);
		}
		catch(Exception e) {
			Json json = Json.emptyObject;
			json["success"] = false;
			res.writeBody(serializeToJsonString(json), 200);
		}
		return res;
	}
}

//Logout should succeed and session should not contain a user id
unittest {
	import application.testhelpers;
	import application.Database;
	import application.Login;
	import application.storage.user;

	CreateTestUser("testname", "testpass");

	auto tester = TestLogin("testname", "testpass");

	Logout logoutHandler = new Logout();
	tester.Request(&logoutHandler.Perform);
	
	Json jsonoutput = tester.GetResponseJson();
	assertEqual(jsonoutput["success"].to!bool, true);
	string id = tester.GetResponseSessionValue!string("id");
	assertEqual(id, "");
}
