module application.testhelpers;

import boiler.ActionTester;
import application.Database;
import application.storage.user;
import application.CreateUser;
import application.Login;
import application.CreateEvent;
import application.storage.event;
import std.datetime;
import vibe.data.json;


void CreateTestUser(string name, string password) {
	Database database = GetDatabase("test");
	
	CreateUser m = new CreateUser(new User_storage(database));
	Json jsoninput = Json.emptyObject;
	jsoninput["username"] = name;
	jsoninput["password"] = password;

	ActionTester tester = new ActionTester(&m.Perform, serializeToJsonString(jsoninput));

	database.Sync();
}

ActionTester TestLogin(string name, string password) {
	Database database = GetDatabase("test");

	Login login = new Login(new User_storage(database));

	Json jsoninput = Json.emptyObject;
	jsoninput["username"] = name;
	jsoninput["password"] = password;

	return new ActionTester(&login.Perform, serializeToJsonString(jsoninput));
}

Event CoordinateEvent(Location l, string t) {
	Event event;
	event.userId = "t";
	event.title = t;
	event.description = "Description";
	event.createdTime = Clock.currTime();
	event.startTime = Clock.currTime();
	event.endTime = Clock.currTime();
	event.location = l;

	return event;
}
