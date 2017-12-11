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
import vibe.data.bson;


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

NewEvent CoordinateEvent(Location l, string t) {
	NewEvent event;
	event.userId = BsonObjectID.fromString("000000000000000000000000");
	event.title = t;
	event.description = "Description";
	event.createdTime = Clock.currTime();
	event.startTime = Clock.currTime();
	event.endTime = Clock.currTime();
	event.location = l;

	return event;
}

NewEvent UserEvent(string userId) {
	auto time = Clock.currTime();
	time.roll!"days"(1);
	NewEvent event;
	event.userId = BsonObjectID.fromString(userId);
	event.title = "title";
	event.description = "Description";
	event.createdTime = Clock.currTime();
	event.startTime = time;
	event.endTime = time;
	event.location = Location(4, 4);

	return event;
}
